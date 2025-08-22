defmodule TTlockClient.Passcodes do
  @moduledoc """
  TTLock Passcodes API client.

  Provides functions to interact with TTLock's passcode management endpoints.
  Handles adding, managing, deleting, and changing custom passcodes for locks.

  All functions automatically retrieve valid access tokens and client configuration
  from the TTlockClient.AuthManager, so authentication must be set up first.

  ## Passcode Types

  - **Permanent (type 2)**: Passcode never expires
  - **Period (type 3)**: Passcode valid only between start and end dates

  ## Add Methods

  - **Gateway/WiFi (addType 2)**: Add directly via gateway or WiFi lock

  ## Change Methods

  - **Gateway/WiFi (changeType 2)**: Change directly via gateway or WiFi lock

  ## Examples

      # Add a permanent passcode via gateway
      params = TTlockClient.Types.new_passcode_add_params(
        12345,     # lock_id
        123456,    # passcode (4-9 digits)
        "Guest",   # name
        2,         # permanent type
        nil,       # no start date for permanent
        nil,       # no end date for permanent
        2          # via gateway
      )
      {:ok, result} = TTlockClient.Passcodes.add_passcode(params)

      # Change a passcode name
      change_params = TTlockClient.Types.new_passcode_change_params(
        12345,     # lock_id
        67890,     # passcode_id
        "New Name" # new name
      )
      {:ok, result} = TTlockClient.Passcodes.change_passcode(change_params)

      # Delete a passcode
      delete_params = TTlockClient.Types.new_passcode_delete_params(
        12345,     # lock_id
        67890      # passcode_id
      )
      {:ok, result} = TTlockClient.Passcodes.delete_passcode(delete_params)
  """

  require Logger
  import TTlockClient.Types

  alias TTlockClient.AuthManager

  @type passcode_api_result :: TTlockClient.Types.passcode_api_result()
  @type passcode_add_params :: TTlockClient.Types.passcode_add_params()
  @type passcode_list_params :: TTlockClient.Types.passcode_list_params()
  @type passcode_delete_params :: TTlockClient.Types.passcode_delete_params()
  @type passcode_change_params :: TTlockClient.Types.passcode_change_params()

  @passcode_add_endpoint "/v3/keyboardPwd/add"
  @passcode_list_endpoint "/v3/lock/listKeyboardPwd"
  @passcode_delete_endpoint "/v3/keyboardPwd/delete"
  @passcode_change_endpoint "/v3/keyboardPwd/change"
  @request_timeout 30_000

  # Passcode type constants
  @passcode_type_permanent 2
  @passcode_type_period 3

  # Add type constants
  @add_type_gateway 2

  # Change type constants
  @change_type_gateway 2

  # Order by constants
  @order_by_name 0
  @order_by_time_desc 1
  @order_by_name_desc 2

  @doc """
  Adds a custom passcode to a lock.

  Supports both permanent and temporary passcodes. For temporary passcodes,
  start_date and end_date must be provided. Maximum 250 passcodes per lock.

  ## Parameters
    * `params` - Passcode add parameters containing all required information

  ## Examples
      # Permanent passcode via gateway
      params = TTlockClient.Types.new_passcode_add_params(
        lock_id, 123456, "Guest Access", 2, nil, nil, 2
      )
      {:ok, %{keyboardPwdId: passcode_id}} = TTlockClient.Passcodes.add_passcode(params)

      # Temporary passcode (1 week)
      start_ms = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      end_ms = DateTime.add(DateTime.utc_now(), 7, :day) |> DateTime.to_unix(:millisecond)

      params = TTlockClient.Types.new_passcode_add_params(
        lock_id, 555999, "Week Access", 3, start_ms, end_ms, 2
      )
      {:ok, result} = TTlockClient.Passcodes.add_passcode(params)

  ## Returns
    * `{:ok, passcode_add_response}` - Success with passcode ID
    * `{:error, :not_authenticated}` - Authentication required
    * `{:error, %{error_code: -3009}}` - Lock passcode storage full (250 max)
    * `{:error, reason}` - API call failed
  """
  @spec add_passcode(TTlockClient.Types.passcode_add_params()) :: passcode_api_result()
  def add_passcode(passcode_add_params() = params) do
    lock_id = passcode_add_params(params, :lock_id)
    keyboard_pwd = passcode_add_params(params, :keyboard_pwd)

    Logger.debug("Adding passcode #{keyboard_pwd} to lock ID: #{lock_id}")

    with :ok <- validate_passcode_params(params),
         {:ok, auth_data} <- get_auth_data(),
         {:ok, form_params} <- build_passcode_add_params(params, auth_data),
         {:ok, response} <- make_api_request(@passcode_add_endpoint, form_params) do
      Logger.info("Successfully added passcode to lock ID: #{lock_id}")
      {:ok, parse_passcode_add_response(response)}
    end
  end

  @doc """
  Changes a passcode's name, value, or valid period.

  Can change any combination of passcode properties. At least one of the optional
  parameters must be provided to perform a change.

  ## Parameters
    * `params` - Passcode change parameters containing lock ID, passcode ID, and changes

  ## Examples
      # Change passcode name only
      params = TTlockClient.Types.new_passcode_change_params(
        12345, 67890, "New Name"
      )
      {:ok, result} = TTlockClient.Passcodes.change_passcode(params)

      # Change passcode value
      params = TTlockClient.Types.new_passcode_change_params(
        12345, 67890, nil, 999888
      )
      {:ok, result} = TTlockClient.Passcodes.change_passcode(params)

      # Change validity period
      start_ms = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      end_ms = DateTime.add(DateTime.utc_now(), 30, :day) |> DateTime.to_unix(:millisecond)

      params = TTlockClient.Types.new_passcode_change_params(
        12345, 67890, nil, nil, start_ms, end_ms
      )
      {:ok, result} = TTlockClient.Passcodes.change_passcode(params)

  ## Returns
    * `{:ok, passcode_change_response}` - Success with status information
    * `{:error, :not_authenticated}` - Authentication required
    * `{:error, reason}` - API call failed
  """
  @spec change_passcode(TTlockClient.Types.passcode_change_params()) :: passcode_api_result()
  def change_passcode(passcode_change_params() = params) do
    lock_id = passcode_change_params(params, :lock_id)
    passcode_id = passcode_change_params(params, :keyboard_pwd_id)

    Logger.debug("Changing passcode #{passcode_id} for lock ID: #{lock_id}")

    with :ok <- validate_passcode_change_params(params),
         {:ok, auth_data} <- get_auth_data(),
         {:ok, form_params} <- build_passcode_change_params(params, auth_data),
         {:ok, response} <- make_api_request(@passcode_change_endpoint, form_params) do
      Logger.info("Successfully changed passcode #{passcode_id} for lock ID: #{lock_id}")
      {:ok, parse_passcode_change_response(response)}
    end
  end

  @doc """
  Convenience function to change only a passcode's name.

  ## Parameters
    * `lock_id` - The lock ID containing the passcode
    * `passcode_id` - The passcode ID to change
    * `new_name` - The new name for the passcode

  ## Example
      {:ok, result} = TTlockClient.Passcodes.change_passcode_name(12345, 67890, "Updated Name")
  """
  @spec change_passcode_name(integer(), integer(), String.t()) :: passcode_api_result()
  def change_passcode_name(lock_id, passcode_id, new_name) do
    params = new_passcode_change_params(lock_id, passcode_id, new_name)
    change_passcode(params)
  end

  @doc """
  Convenience function to change only a passcode's value.

  ## Parameters
    * `lock_id` - The lock ID containing the passcode
    * `passcode_id` - The passcode ID to change
    * `new_passcode` - The new passcode value (4-9 digits)

  ## Example
      {:ok, result} = TTlockClient.Passcodes.change_passcode_value(12345, 67890, 999888)
  """
  @spec change_passcode_value(integer(), integer(), integer()) :: passcode_api_result()
  def change_passcode_value(lock_id, passcode_id, new_passcode) do
    params = new_passcode_change_params(lock_id, passcode_id, nil, new_passcode)
    change_passcode(params)
  end

  @doc """
  Convenience function to change only a passcode's validity period.

  ## Parameters
    * `lock_id` - The lock ID containing the passcode
    * `passcode_id` - The passcode ID to change
    * `start_date` - New start time (DateTime or milliseconds)
    * `end_date` - New end time (DateTime or milliseconds)

  ## Example
      start_time = DateTime.utc_now()
      end_time = DateTime.add(start_time, 30, :day)
      {:ok, result} = TTlockClient.Passcodes.change_passcode_period(12345, 67890, start_time, end_time)
  """
  @spec change_passcode_period(
          integer(),
          integer(),
          DateTime.t() | integer(),
          DateTime.t() | integer()
        ) :: passcode_api_result()
  def change_passcode_period(lock_id, passcode_id, start_date, end_date) do
    start_ms = datetime_to_milliseconds(start_date)
    end_ms = datetime_to_milliseconds(end_date)

    params = new_passcode_change_params(lock_id, passcode_id, nil, nil, start_ms, end_ms)
    change_passcode(params)
  end

  @doc """
  Convenience function to add a permanent passcode via gateway.

  ## Parameters
    * `lock_id` - The lock ID to add the passcode to
    * `passcode` - The 4-9 digit passcode
    * `name` - Optional name for the passcode

  ## Example
      {:ok, result} = TTlockClient.Passcodes.add_permanent_passcode(12345, 123456, "Guest")
  """
  @spec add_permanent_passcode(integer(), integer(), String.t() | nil) :: passcode_api_result()
  def add_permanent_passcode(lock_id, passcode, name \\ nil) do
    params =
      new_passcode_add_params(
        lock_id,
        passcode,
        name,
        @passcode_type_permanent,
        nil,
        nil,
        @add_type_gateway
      )

    add_passcode(params)
  end

  @doc """
  Convenience function to add a temporary passcode via gateway.

  ## Parameters
    * `lock_id` - The lock ID to add the passcode to
    * `passcode` - The 4-9 digit passcode
    * `start_date` - Start time (DateTime or milliseconds)
    * `end_date` - End time (DateTime or milliseconds)
    * `name` - Optional name for the passcode

  ## Example
      start_time = DateTime.utc_now()
      end_time = DateTime.add(start_time, 7, :day)
      {:ok, result} = TTlockClient.Passcodes.add_temporary_passcode(
        12345, 987654, start_time, end_time, "Week Access"
      )
  """
  @spec add_temporary_passcode(
          integer(),
          integer(),
          DateTime.t() | integer(),
          DateTime.t() | integer(),
          String.t() | nil
        ) :: passcode_api_result()
  def add_temporary_passcode(lock_id, passcode, start_date, end_date, name \\ nil) do
    start_ms = datetime_to_milliseconds(start_date)
    end_ms = datetime_to_milliseconds(end_date)

    params =
      new_passcode_add_params(
        lock_id,
        passcode,
        name,
        @passcode_type_period,
        start_ms,
        end_ms,
        @add_type_gateway
      )

    add_passcode(params)
  end

  @doc """
  Deletes a passcode from a lock via gateway.

  This function deletes passcodes directly via the cloud API for WiFi locks
  or locks connected to a gateway.

  ## Parameters
    * `params` - Passcode delete parameters containing lock ID and passcode ID

  ## Examples
      # Delete via gateway
      delete_params = TTlockClient.Types.new_passcode_delete_params(
        12345,  # lock_id
        67890   # passcode_id
      )
      {:ok, result} = TTlockClient.Passcodes.delete_passcode(delete_params)

  ## Returns
    * `{:ok, passcode_delete_response}` - Success with status information
    * `{:error, :not_authenticated}` - Authentication required
    * `{:error, reason}` - API call failed
  """
  @spec delete_passcode(TTlockClient.Types.passcode_delete_params()) :: passcode_api_result()
  def delete_passcode(passcode_delete_params() = params) do
    lock_id = passcode_delete_params(params, :lock_id)
    passcode_id = passcode_delete_params(params, :keyboard_pwd_id)

    Logger.debug("Deleting passcode #{passcode_id} from lock ID: #{lock_id}")

    with :ok <- validate_passcode_delete_params(params),
         {:ok, auth_data} <- get_auth_data(),
         {:ok, form_params} <- build_passcode_delete_params(params, auth_data),
         {:ok, response} <- make_api_request(@passcode_delete_endpoint, form_params) do
      Logger.info("Successfully deleted passcode #{passcode_id} from lock ID: #{lock_id}")
      {:ok, parse_passcode_delete_response(response)}
    end
  end

  @doc """
  Convenience function to delete a passcode via gateway.

  This is the recommended method for WiFi locks or locks connected to a gateway.
  The passcode will be deleted directly via the cloud API.

  ## Parameters
    * `lock_id` - The lock ID containing the passcode
    * `passcode_id` - The passcode ID to delete

  ## Example
      {:ok, result} = TTlockClient.Passcodes.delete_passcode_via_gateway(12345, 67890)
  """
  @spec delete_passcode_via_gateway(integer(), integer()) :: passcode_api_result()
  def delete_passcode_via_gateway(lock_id, passcode_id) do
    params = new_passcode_delete_params(lock_id, passcode_id)
    delete_passcode(params)
  end

  @doc """
  Retrieves all passcodes created for a lock.

  Returns both random and custom passcodes with pagination support.

  ## Parameters
    * `params` - Passcode list parameters containing lock ID and optional filters

  ## Examples
      # Get first page of passcodes for a lock
      params = TTlockClient.Types.new_passcode_list_params(lock_id)
      {:ok, response} = TTlockClient.Passcodes.get_passcode_list(params)

      # Search for specific passcodes
      params = TTlockClient.Types.new_passcode_list_params(lock_id, "Guest", 1, 50, 1)
      {:ok, response} = TTlockClient.Passcodes.get_passcode_list(params)

      # Access the results
      %{list: passcodes, total: total_count} = response

  ## Returns
    * `{:ok, passcode_list_response}` - Success with passcode list data
    * `{:error, :not_authenticated}` - Authentication required
    * `{:error, reason}` - API call failed
  """
  @spec get_passcode_list(TTlockClient.Types.passcode_list_params()) :: passcode_api_result()
  def get_passcode_list(passcode_list_params() = params) do
    lock_id = passcode_list_params(params, :lock_id)

    Logger.debug("Fetching passcode list for lock ID: #{lock_id}")

    with {:ok, auth_data} <- get_auth_data(),
         {:ok, query_params} <- build_passcode_list_params(params, auth_data),
         {:ok, response} <- make_get_request(@passcode_list_endpoint, query_params) do
      Logger.info(
        "Successfully retrieved passcode list for lock ID: #{lock_id} - Total: #{Map.get(response, "total", 0)}"
      )

      {:ok, parse_passcode_list_response(response)}
    end
  end

  @doc """
  Convenience function to get all passcodes for a lock.

  ## Parameters
    * `lock_id` - The lock ID to get passcodes for
    * `search_str` - Optional search string

  ## Example
      {:ok, %{list: passcodes}} = TTlockClient.Passcodes.get_lock_passcodes(12345)
  """
  @spec get_lock_passcodes(integer(), String.t() | nil) :: passcode_api_result()
  def get_lock_passcodes(lock_id, search_str \\ nil) do
    params = new_passcode_list_params(lock_id, search_str, 1, 200, @order_by_time_desc)
    get_passcode_list(params)
  end

  @doc """
  Convenience function to search passcodes by name or passcode value.

  ## Parameters
    * `lock_id` - The lock ID to search in
    * `search_term` - Search term (name or exact passcode match)

  ## Example
      {:ok, results} = TTlockClient.Passcodes.search_passcodes(12345, "Guest")
  """
  @spec search_passcodes(integer(), String.t()) :: passcode_api_result()
  def search_passcodes(lock_id, search_term) do
    params = new_passcode_list_params(lock_id, search_term, 1, 200, @order_by_name)
    get_passcode_list(params)
  end

  @doc """
  Helper function to get passcode type constants.
  """
  def passcode_types do
    %{
      permanent: @passcode_type_permanent,
      period: @passcode_type_period
    }
  end

  @doc """
  Helper function to get add type constants.
  """
  def add_types do
    %{
      gateway: @add_type_gateway
    }
  end

  @doc """
  Helper function to get change type constants.
  """
  def change_types do
    %{
      gateway: @change_type_gateway
    }
  end

  @doc """
  Helper function to get order by constants.
  """
  def order_by_options do
    %{
      name: @order_by_name,
      time_desc: @order_by_time_desc,
      name_desc: @order_by_name_desc
    }
  end

  # Private functions

  @spec validate_passcode_params(passcode_add_params()) :: :ok | {:error, term()}
  defp validate_passcode_params(params) do
    lock_id = passcode_add_params(params, :lock_id)
    keyboard_pwd = passcode_add_params(params, :keyboard_pwd)
    keyboard_pwd_type = passcode_add_params(params, :keyboard_pwd_type)
    start_date = passcode_add_params(params, :start_date)
    end_date = passcode_add_params(params, :end_date)

    cond do
      not is_integer(lock_id) or lock_id <= 0 ->
        {:error, {:validation_error, "lock_id must be a positive integer"}}

      not is_integer(keyboard_pwd) or keyboard_pwd < 1000 or keyboard_pwd > 999_999_999 ->
        {:error, {:validation_error, "keyboard_pwd must be 4-9 digits"}}

      keyboard_pwd_type not in [@passcode_type_permanent, @passcode_type_period] ->
        {:error, {:validation_error, "keyboard_pwd_type must be 2 (permanent) or 3 (period)"}}

      keyboard_pwd_type == @passcode_type_period and (start_date == nil or end_date == nil) ->
        {:error, {:validation_error, "start_date and end_date are required for period passcodes"}}

      keyboard_pwd_type == @passcode_type_period and start_date >= end_date ->
        {:error, {:validation_error, "start_date must be before end_date"}}

      true ->
        :ok
    end
  end

  @spec validate_passcode_change_params(passcode_change_params()) :: :ok | {:error, term()}
  defp validate_passcode_change_params(params) do
    lock_id = passcode_change_params(params, :lock_id)
    keyboard_pwd_id = passcode_change_params(params, :keyboard_pwd_id)
    keyboard_pwd_name = passcode_change_params(params, :keyboard_pwd_name)
    new_keyboard_pwd = passcode_change_params(params, :new_keyboard_pwd)
    start_date = passcode_change_params(params, :start_date)
    end_date = passcode_change_params(params, :end_date)

    cond do
      not is_integer(lock_id) or lock_id <= 0 ->
        {:error, {:validation_error, "lock_id must be a positive integer"}}

      not is_integer(keyboard_pwd_id) or keyboard_pwd_id <= 0 ->
        {:error, {:validation_error, "keyboard_pwd_id must be a positive integer"}}

      new_keyboard_pwd != nil and
          (not is_integer(new_keyboard_pwd) or new_keyboard_pwd < 1000 or
             new_keyboard_pwd > 999_999_999) ->
        {:error, {:validation_error, "new_keyboard_pwd must be 4-9 digits"}}

      (start_date != nil and end_date == nil) or (start_date == nil and end_date != nil) ->
        {:error,
         {:validation_error,
          "start_date and end_date must both be provided when changing validity period"}}

      start_date != nil and end_date != nil and start_date >= end_date ->
        {:error, {:validation_error, "start_date must be before end_date"}}

      keyboard_pwd_name == nil and new_keyboard_pwd == nil and start_date == nil and
          end_date == nil ->
        {:error,
         {:validation_error,
          "at least one change parameter must be provided (name, passcode, or dates)"}}

      true ->
        :ok
    end
  end

  @spec validate_passcode_delete_params(passcode_delete_params()) :: :ok | {:error, term()}
  defp validate_passcode_delete_params(params) do
    lock_id = passcode_delete_params(params, :lock_id)
    keyboard_pwd_id = passcode_delete_params(params, :keyboard_pwd_id)

    cond do
      not is_integer(lock_id) or lock_id <= 0 ->
        {:error, {:validation_error, "lock_id must be a positive integer"}}

      not is_integer(keyboard_pwd_id) or keyboard_pwd_id <= 0 ->
        {:error, {:validation_error, "keyboard_pwd_id must be a positive integer"}}

      true ->
        :ok
    end
  end

  @spec get_auth_data() :: {:ok, {String.t(), String.t()}} | {:error, term()}
  defp get_auth_data do
    with {:ok, access_token} <- AuthManager.get_valid_token(),
         {:ok, client_config} <- get_client_config() do
      client_id = client_config(client_config, :client_id)
      {:ok, {access_token, client_id}}
    else
      {:error, :not_authenticated} ->
        Logger.error("Authentication required for passcode API calls")
        {:error, :not_authenticated}

      {:error, reason} = error ->
        Logger.error("Failed to get authentication data: #{inspect(reason)}")
        error
    end
  end

  @spec get_client_config() ::
          {:ok, TTlockClient.Types.client_config()} | {:error, :not_configured}
  defp get_client_config do
    AuthManager.get_config()
  end

  @spec build_passcode_add_params(
          TTlockClient.Types.passcode_add_params(),
          {String.t(), String.t()}
        ) :: {:ok, map()}
  defp build_passcode_add_params(params, {access_token, client_id}) do
    base_params = %{
      "clientId" => client_id,
      "accessToken" => access_token,
      "lockId" => passcode_add_params(params, :lock_id),
      "keyboardPwd" => passcode_add_params(params, :keyboard_pwd),
      "keyboardPwdType" => passcode_add_params(params, :keyboard_pwd_type),
      "addType" => passcode_add_params(params, :add_type),
      "date" => current_timestamp_ms()
    }

    optional_params =
      []
      |> maybe_add_param("keyboardPwdName", passcode_add_params(params, :keyboard_pwd_name))
      |> maybe_add_param("startDate", passcode_add_params(params, :start_date))
      |> maybe_add_param("endDate", passcode_add_params(params, :end_date))
      |> Enum.into(%{})

    form_params = Map.merge(base_params, optional_params)
    {:ok, form_params}
  end

  @spec build_passcode_change_params(
          TTlockClient.Types.passcode_change_params(),
          {String.t(), String.t()}
        ) :: {:ok, map()}
  defp build_passcode_change_params(params, {access_token, client_id}) do
    base_params = %{
      "clientId" => client_id,
      "accessToken" => access_token,
      "lockId" => passcode_change_params(params, :lock_id),
      "keyboardPwdId" => passcode_change_params(params, :keyboard_pwd_id),
      "changeType" => passcode_change_params(params, :change_type),
      "date" => current_timestamp_ms()
    }

    optional_params =
      []
      |> maybe_add_param("keyboardPwdName", passcode_change_params(params, :keyboard_pwd_name))
      |> maybe_add_param("newKeyboardPwd", passcode_change_params(params, :new_keyboard_pwd))
      |> maybe_add_param("startDate", passcode_change_params(params, :start_date))
      |> maybe_add_param("endDate", passcode_change_params(params, :end_date))
      |> Enum.into(%{})

    form_params = Map.merge(base_params, optional_params)
    {:ok, form_params}
  end

  @spec build_passcode_delete_params(
          TTlockClient.Types.passcode_delete_params(),
          {String.t(), String.t()}
        ) :: {:ok, map()}
  defp build_passcode_delete_params(params, {access_token, client_id}) do
    form_params = %{
      "clientId" => client_id,
      "accessToken" => access_token,
      "lockId" => passcode_delete_params(params, :lock_id),
      "keyboardPwdId" => passcode_delete_params(params, :keyboard_pwd_id),
      # Always use gateway deletion
      "deleteType" => 2,
      "date" => current_timestamp_ms()
    }

    {:ok, form_params}
  end

  @spec build_passcode_list_params(
          TTlockClient.Types.passcode_list_params(),
          {String.t(), String.t()}
        ) :: {:ok, map()}
  defp build_passcode_list_params(params, {access_token, client_id}) do
    base_params = %{
      "clientId" => client_id,
      "accessToken" => access_token,
      "lockId" => passcode_list_params(params, :lock_id),
      "pageNo" => passcode_list_params(params, :page_no),
      "pageSize" => passcode_list_params(params, :page_size),
      "orderBy" => passcode_list_params(params, :order_by),
      "date" => current_timestamp_ms()
    }

    optional_params =
      []
      |> maybe_add_param("searchStr", passcode_list_params(params, :search_str))
      |> Enum.into(%{})

    query_params = Map.merge(base_params, optional_params)
    {:ok, query_params}
  end

  @spec maybe_add_param([{String.t(), any()}], String.t(), any()) :: [{String.t(), any()}]
  defp maybe_add_param(params, _key, nil), do: params
  defp maybe_add_param(params, key, value), do: [{key, value} | params]

  @spec make_api_request(String.t(), map()) :: {:ok, map()} | {:error, term()}
  defp make_api_request(endpoint, form_params) do
    case get_client_config() do
      {:ok, config} ->
        base_url = client_config(config, :base_url)
        url = base_url <> endpoint
        body = URI.encode_query(form_params)

        headers = [
          {"content-type", "application/x-www-form-urlencoded"}
        ]

        Logger.debug("Making passcode API request to: #{endpoint}")

        request = Finch.build(:post, url, headers, body)

        case Finch.request(request, TTlockClient.Finch, receive_timeout: @request_timeout) do
          {:ok, %Finch.Response{status: 200, body: response_body}} ->
            parse_response(response_body)

          {:ok, %Finch.Response{status: status, body: response_body}} ->
            Logger.warning("Passcode API request failed with status #{status}: #{response_body}")
            parse_error_response(response_body)

          {:error, %Mint.TransportError{reason: reason}} ->
            {:error, {:transport_error, reason}}

          {:error, reason} ->
            {:error, {:request_error, reason}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec make_get_request(String.t(), map()) :: {:ok, map()} | {:error, term()}
  defp make_get_request(endpoint, query_params) do
    case get_client_config() do
      {:ok, config} ->
        base_url = client_config(config, :base_url)
        url = base_url <> endpoint <> "?" <> URI.encode_query(query_params)

        Logger.debug("Making passcode GET API request to: #{endpoint}")

        request = Finch.build(:get, url, [])

        case Finch.request(request, TTlockClient.Finch, receive_timeout: @request_timeout) do
          {:ok, %Finch.Response{status: 200, body: response_body}} ->
            parse_response(response_body)

          {:ok, %Finch.Response{status: status, body: response_body}} ->
            Logger.warning(
              "Passcode GET API request failed with status #{status}: #{response_body}"
            )

            parse_error_response(response_body)

          {:error, %Mint.TransportError{reason: reason}} ->
            {:error, {:transport_error, reason}}

          {:error, reason} ->
            {:error, {:request_error, reason}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec parse_response(String.t()) :: {:ok, map()} | {:error, term()}
  defp parse_response(response_body) do
    case Jason.decode(response_body) do
      {:ok, %{"keyboardPwdId" => _} = response} ->
        # Add passcode response
        {:ok, response}

      {:ok, %{"list" => _} = response} ->
        # List passcodes response
        {:ok, response}

      {:ok, %{"errcode" => _} = response} ->
        # Delete/change passcode response (and other simple responses)
        {:ok, response}

      {:ok, parsed} ->
        {:error, {:invalid_response, parsed}}

      {:error, reason} ->
        {:error, {:json_decode_error, reason}}
    end
  end

  @spec parse_error_response(String.t()) :: {:error, term()}
  defp parse_error_response(response_body) do
    case Jason.decode(response_body) do
      {:ok, %{"errcode" => error_code, "errmsg" => description}} ->
        error = %{
          error_code: error_code,
          description: description
        }

        {:error, error}

      {:ok, %{"error" => error_type}} ->
        {:error, {:api_error, error_type}}

      {:ok, parsed} ->
        {:error, {:unknown_error_format, parsed}}

      {:error, _reason} ->
        {:error, :invalid_error_response}
    end
  end

  @spec parse_passcode_add_response(map()) :: map()
  defp parse_passcode_add_response(response) do
    %{
      keyboardPwdId: response["keyboardPwdId"]
    }
  end

  @spec parse_passcode_change_response(map()) :: map()
  defp parse_passcode_change_response(response) do
    %{
      errcode: response["errcode"],
      errmsg: response["errmsg"]
    }
  end

  @spec parse_passcode_delete_response(map()) :: map()
  defp parse_passcode_delete_response(response) do
    %{
      errcode: response["errcode"],
      errmsg: response["errmsg"]
    }
  end

  @spec parse_passcode_list_response(map()) :: map()
  defp parse_passcode_list_response(response) do
    %{
      list: response["list"] || [],
      pageNo: response["pageNo"] || 1,
      pageSize: response["pageSize"] || 20,
      pages: response["pages"] || 1,
      total: response["total"] || 0
    }
  end

  @spec current_timestamp_ms() :: integer()
  defp current_timestamp_ms do
    DateTime.utc_now() |> DateTime.to_unix(:millisecond)
  end

  @spec datetime_to_milliseconds(DateTime.t() | integer()) :: integer()
  defp datetime_to_milliseconds(%DateTime{} = dt) do
    DateTime.to_unix(dt, :millisecond)
  end

  defp datetime_to_milliseconds(ms) when is_integer(ms) do
    ms
  end
end
