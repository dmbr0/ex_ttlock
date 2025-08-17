defmodule TTlockClient.Passcodes do
  @moduledoc """
  TTLock Passcodes API client.
  
  Provides functions to interact with TTLock's passcode management endpoints.
  Handles adding, managing, and deleting custom passcodes for locks.
  
  All functions automatically retrieve valid access tokens and client configuration
  from the TTlockClient.AuthManager, so authentication must be set up first.
  
  ## Passcode Types
  
  - **Permanent (type 2)**: Passcode never expires
  - **Period (type 3)**: Passcode valid only between start and end dates
  
  ## Add Methods
  
  - **Bluetooth (addType 1)**: Use mobile app/SDK first, then sync to cloud
  - **Gateway/WiFi (addType 2)**: Add directly via gateway or WiFi lock
  
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
      
      # Add a temporary passcode (valid for 1 week)
      start_time = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      end_time = DateTime.add(DateTime.utc_now(), 7, :day) |> DateTime.to_unix(:millisecond)
      
      params = TTlockClient.Types.new_passcode_add_params(
        12345,     # lock_id
        987654,    # passcode
        "Visitor", # name
        3,         # period type
        start_time,
        end_time,
        2          # via gateway
      )
      {:ok, result} = TTlockClient.Passcodes.add_passcode(params)
  """

  require Logger
  import TTlockClient.Types

  alias TTlockClient.AuthManager

  @type passcode_api_result :: TTlockClient.Types.passcode_api_result()
  @type passcode_add_params :: TTlockClient.Types.passcode_add_params()

  @passcode_add_endpoint "/v3/keyboardPwd/add"
  @request_timeout 30_000

  # Passcode type constants
  @passcode_type_permanent 2
  @passcode_type_period 3

  # Add type constants  
  @add_type_bluetooth 1
  @add_type_gateway 2

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
    params = new_passcode_add_params(lock_id, passcode, name, @passcode_type_permanent, nil, nil, @add_type_gateway)
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
  @spec add_temporary_passcode(integer(), integer(), DateTime.t() | integer(), DateTime.t() | integer(), String.t() | nil) :: passcode_api_result()
  def add_temporary_passcode(lock_id, passcode, start_date, end_date, name \\ nil) do
    start_ms = datetime_to_milliseconds(start_date)
    end_ms = datetime_to_milliseconds(end_date)
    
    params = new_passcode_add_params(lock_id, passcode, name, @passcode_type_period, start_ms, end_ms, @add_type_gateway)
    add_passcode(params)
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
      bluetooth: @add_type_bluetooth,
      gateway: @add_type_gateway
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

  @spec get_client_config() :: {:ok, TTlockClient.Types.client_config()} | {:error, :not_configured}
  defp get_client_config do
    AuthManager.get_config()
  end

  @spec build_passcode_add_params(TTlockClient.Types.passcode_add_params(), {String.t(), String.t()}) :: {:ok, map()}
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

  @spec parse_response(String.t()) :: {:ok, map()} | {:error, term()}
  defp parse_response(response_body) do
    case Jason.decode(response_body) do
      {:ok, %{"keyboardPwdId" => _} = response} ->
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
