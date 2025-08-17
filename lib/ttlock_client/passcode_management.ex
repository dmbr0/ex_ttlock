defmodule TTlockClient.PasscodeManagement do
  @moduledoc """
  TTLock Passcode Management client for managing lock passcodes.

  This module handles:
  - Adding custom passcodes (permanent, period, or single use)
  - Deleting passcodes
  - Changing existing passcodes
  - Listing all passcodes for a lock

  ## Usage

      # Add a passcode
      {:ok, response} = TTlockClient.PasscodeManagement.add_passcode(
        client_id: "your_client_id",
        access_token: "your_access_token",
        lock_id: 123456,
        keyboard_pwd: "123456",
        start_date: 1700000000000,
        end_date: 1705000000000
      )
      
      # List passcodes
      {:ok, response} = TTlockClient.PasscodeManagement.list_passcodes(
        client_id: "your_client_id",
        access_token: "your_access_token",
        lock_id: 123456
      )
  """

  @base_url "https://euapi.ttlock.com"
  @add_passcode_endpoint "/v3/keyboardPwd/add"
  @delete_passcode_endpoint "/v3/keyboardPwd/delete"
  @change_passcode_endpoint "/v3/keyboardPwd/change"
  @list_passcodes_endpoint "/v3/lock/listKeyboardPwd"

  @type add_passcode_config :: [
          client_id: String.t(),
          access_token: String.t(),
          lock_id: integer(),
          keyboard_pwd: String.t(),
          start_date: integer(),
          end_date: integer(),
          add_type: integer() | nil
        ]

  @type delete_passcode_config :: [
          client_id: String.t(),
          access_token: String.t(),
          lock_id: integer(),
          keyboard_pwd_id: integer()
        ]

  @type change_passcode_config :: [
          client_id: String.t(),
          access_token: String.t(),
          lock_id: integer(),
          keyboard_pwd_id: integer(),
          new_keyboard_pwd: String.t()
        ]

  @type list_passcodes_config :: [
          client_id: String.t(),
          access_token: String.t(),
          lock_id: integer(),
          page_no: integer() | nil,
          page_size: integer() | nil
        ]

  @type add_passcode_response :: %{
          keyboardPwdId: integer()
        }

  @type passcode_info :: %{
          keyboardPwdId: integer(),
          keyboardPwd: String.t(),
          keyboardPwdType: integer(),
          startDate: integer(),
          endDate: integer(),
          keyboardPwdName: String.t() | nil,
          senderUsername: String.t() | nil,
          receiverUsername: String.t() | nil,
          isActive: integer(),
          date: integer()
        }

  @type list_passcodes_response :: %{
          list: [passcode_info()],
          pageNo: integer(),
          pageSize: integer(),
          pages: integer(),
          total: integer()
        }

  @doc """
  Add a custom passcode for a lock.

  ## Parameters

  - `client_id`: Application clientId
  - `access_token`: Access token from OAuth
  - `lock_id`: Lock ID
  - `keyboard_pwd`: Custom passcode (4-9 digits)
  - `start_date`: Start time (Unix timestamp in milliseconds)
  - `end_date`: End time (Unix timestamp in milliseconds)
  - `add_type`: Optional. 2 = permanent, 3 = period, 4 = single. Default: 2

  ## Returns

  - `{:ok, add_passcode_response}` on success
  - `{:error, reason}` on failure

  ## Example

      {:ok, %{"keyboardPwdId" => 98765}} = TTlockClient.PasscodeManagement.add_passcode(
        client_id: "your_client_id",
        access_token: "your_access_token",
        lock_id: 123456,
        keyboard_pwd: "123456",
        start_date: 1700000000000,
        end_date: 1705000000000,
        add_type: 2
      )
  """
  @spec add_passcode(add_passcode_config()) :: {:ok, add_passcode_response()} | {:error, term()}
  def add_passcode(opts \\ []) do
    client_id = get_config_value(opts, :client_id)
    access_token = Keyword.fetch!(opts, :access_token)
    lock_id = Keyword.fetch!(opts, :lock_id)
    keyboard_pwd = Keyword.fetch!(opts, :keyboard_pwd)
    start_date = Keyword.fetch!(opts, :start_date)
    end_date = Keyword.fetch!(opts, :end_date)
    add_type = Keyword.get(opts, :add_type, 2)

    params = [
      {"clientId", client_id},
      {"accessToken", access_token},
      {"lockId", Integer.to_string(lock_id)},
      {"keyboardPwd", keyboard_pwd},
      {"startDate", Integer.to_string(start_date)},
      {"endDate", Integer.to_string(end_date)},
      {"addType", Integer.to_string(add_type)}
    ]

    make_post_request(@add_passcode_endpoint, params)
  end

  @doc """
  Delete a passcode from a lock.

  ## Parameters

  - `client_id`: Application clientId
  - `access_token`: Access token from OAuth
  - `lock_id`: Lock ID
  - `keyboard_pwd_id`: Passcode ID to delete

  ## Returns

  - `{:ok, response}` on success
  - `{:error, reason}` on failure

  ## Example

      {:ok, response} = TTlockClient.PasscodeManagement.delete_passcode(
        client_id: "your_client_id",
        access_token: "your_access_token",
        lock_id: 123456,
        keyboard_pwd_id: 98765
      )
  """
  @spec delete_passcode(delete_passcode_config()) :: {:ok, map()} | {:error, term()}
  def delete_passcode(opts \\ []) do
    client_id = get_config_value(opts, :client_id)
    access_token = Keyword.fetch!(opts, :access_token)
    lock_id = Keyword.fetch!(opts, :lock_id)
    keyboard_pwd_id = Keyword.fetch!(opts, :keyboard_pwd_id)

    params = [
      {"clientId", client_id},
      {"accessToken", access_token},
      {"lockId", Integer.to_string(lock_id)},
      {"keyboardPwdId", Integer.to_string(keyboard_pwd_id)}
    ]

    make_post_request(@delete_passcode_endpoint, params)
  end

  @doc """
  Change an existing passcode.

  ## Parameters

  - `client_id`: Application clientId
  - `access_token`: Access token from OAuth
  - `lock_id`: Lock ID
  - `keyboard_pwd_id`: Passcode ID to change
  - `new_keyboard_pwd`: New passcode value

  ## Returns

  - `{:ok, response}` on success
  - `{:error, reason}` on failure

  ## Example

      {:ok, response} = TTlockClient.PasscodeManagement.change_passcode(
        client_id: "your_client_id",
        access_token: "your_access_token",
        lock_id: 123456,
        keyboard_pwd_id: 98765,
        new_keyboard_pwd: "654321"
      )
  """
  @spec change_passcode(change_passcode_config()) :: {:ok, map()} | {:error, term()}
  def change_passcode(opts \\ []) do
    client_id = get_config_value(opts, :client_id)
    access_token = Keyword.fetch!(opts, :access_token)
    lock_id = Keyword.fetch!(opts, :lock_id)
    keyboard_pwd_id = Keyword.fetch!(opts, :keyboard_pwd_id)
    new_keyboard_pwd = Keyword.fetch!(opts, :new_keyboard_pwd)

    params = [
      {"clientId", client_id},
      {"accessToken", access_token},
      {"lockId", Integer.to_string(lock_id)},
      {"keyboardPwdId", Integer.to_string(keyboard_pwd_id)},
      {"newKeyboardPwd", new_keyboard_pwd}
    ]

    make_post_request(@change_passcode_endpoint, params)
  end

  @doc """
  List all passcodes for a specific lock.

  ## Parameters

  - `client_id`: Application clientId
  - `access_token`: Access token from OAuth
  - `lock_id`: Lock ID
  - `page_no`: Optional page number (default: 1)
  - `page_size`: Optional number of results per page (default: 20)

  ## Returns

  - `{:ok, list_passcodes_response}` on success
  - `{:error, reason}` on failure

  ## Example

      {:ok, %{
        "list" => [
          %{
            "keyboardPwdId" => 98765,
            "keyboardPwd" => "123456",
            "keyboardPwdType" => 2,
            "startDate" => 1700000000000,
            "endDate" => 1705000000000,
            "keyboardPwdName" => "Guest Code",
            "senderUsername" => "admin@example.com",
            "receiverUsername" => nil,
            "isActive" => 1,
            "date" => 1700000000000
          }
        ],
        "pageNo" => 1,
        "pageSize" => 20,
        "pages" => 1,
        "total" => 1
      }} = TTlockClient.PasscodeManagement.list_passcodes(
        client_id: "your_client_id",
        access_token: "your_access_token",
        lock_id: 123456
      )
  """
  @spec list_passcodes(list_passcodes_config()) ::
          {:ok, list_passcodes_response()} | {:error, term()}
  def list_passcodes(opts \\ []) do
    client_id = get_config_value(opts, :client_id)
    access_token = Keyword.fetch!(opts, :access_token)
    lock_id = Keyword.fetch!(opts, :lock_id)
    page_no = Keyword.get(opts, :page_no, 1)
    page_size = Keyword.get(opts, :page_size, 20)

    params = [
      {"clientId", client_id},
      {"accessToken", access_token},
      {"lockId", Integer.to_string(lock_id)},
      {"pageNo", Integer.to_string(page_no)},
      {"pageSize", Integer.to_string(page_size)}
    ]

    make_get_request(@list_passcodes_endpoint, params)
  end

  # Private functions

  defp get_config_value(opts, key) do
    case Keyword.get(opts, key) do
      nil -> 
        case Application.get_env(:ex_ttlock, key) do
          nil -> raise ArgumentError, "#{key} is required either as option or in config"
          value -> value
        end
      value -> value
    end
  end

  defp make_post_request(endpoint, params) do
    url = @base_url <> endpoint
    body = URI.encode_query(params)
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, data} -> {:ok, data}
          {:error, _} = error -> error
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, error_data} -> {:error, {status_code, error_data}}
          {:error, _} -> {:error, {status_code, response_body}}
        end

      {:error, %HTTPoison.Error{} = error} ->
        {:error, error}
    end
  end

  defp make_get_request(endpoint, params) do
    url = @base_url <> endpoint <> "?" <> URI.encode_query(params)
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, data} -> {:ok, data}
          {:error, _} = error -> error
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, error_data} -> {:error, {status_code, error_data}}
          {:error, _} -> {:error, {status_code, response_body}}
        end

      {:error, %HTTPoison.Error{} = error} ->
        {:error, error}
    end
  end
end
