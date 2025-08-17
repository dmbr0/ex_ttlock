defmodule TTlockClient.LockManagement do
  @moduledoc """
  TTLock Lock Management client for retrieving lock information.

  This module handles:
  - Getting list of locks for which you are the top administrator
  - Retrieving detailed information about specific locks
  - Proper pagination and filtering support

  ## Usage

      # Get lock list
      {:ok, response} = TTlockClient.LockManagement.get_lock_list(
        client_id: "your_client_id",
        access_token: "your_access_token",
        page_no: 1,
        page_size: 20
      )
      
      # Get lock details
      {:ok, response} = TTlockClient.LockManagement.get_lock_details(
        client_id: "your_client_id",
        access_token: "your_access_token",
        lock_id: 532323
      )
  """

  @base_url "https://euapi.ttlock.com"
  @lock_list_endpoint "/v3/lock/list"
  @lock_detail_endpoint "/v3/lock/detail"

  @type lock_list_config :: [
          client_id: String.t(),
          access_token: String.t(),
          page_no: integer(),
          page_size: integer(),
          lock_alias: String.t() | nil,
          group_id: integer() | nil
        ]

  @type lock_detail_config :: [
          client_id: String.t(),
          access_token: String.t(),
          lock_id: integer()
        ]

  @type lock_info :: %{
          lockId: integer(),
          lockName: String.t(),
          lockAlias: String.t(),
          lockMac: String.t(),
          electricQuantity: integer(),
          featureValue: String.t(),
          hasGateway: integer(),
          lockData: String.t(),
          groupId: integer() | nil,
          groupName: String.t() | nil,
          date: integer()
        }

  @type lock_list_response :: %{
          list: [lock_info()],
          pageNo: integer(),
          pageSize: integer(),
          pages: integer(),
          total: integer()
        }

  @type lock_detail_response :: %{
          lockId: integer(),
          lockName: String.t(),
          lockAlias: String.t(),
          lockMac: String.t(),
          noKeyPwd: String.t(),
          featureValue: String.t(),
          electricQuantity: integer(),
          timezoneRawOffset: integer(),
          modelNum: String.t(),
          hardwareRevision: String.t(),
          firmwareRevision: String.t(),
          autoLockTime: integer(),
          lockSound: integer(),
          privacyLock: integer(),
          tamperAlert: integer(),
          resetButton: integer(),
          openDirection: integer(),
          passageMode: integer(),
          passageModeAutoUnlock: integer(),
          date: integer()
        }

  @doc """
  Get list of locks for which you are the top administrator.

  Returns all locks regardless of whether they were added via TTLock App or SDK.
  Locks shared with you via eKeys are NOT returned - use the ekey list API for those.

  ## Parameters

  - `client_id`: Application clientId
  - `access_token`: Access token from OAuth
  - `page_no`: Page number (starts from 1)
  - `page_size`: Number of records per page (default 20, max 1000)
  - `lock_alias`: Optional search by lock alias (fuzzy match)
  - `group_id`: Optional filter by group ID

  ## Returns

  - `{:ok, lock_list_response}` on success
  - `{:error, reason}` on failure

  ## Example

      {:ok, %{
        "list" => [
          %{
            "lockId" => 532323,
            "lockName" => "YS1003_c18c9c",
            "lockAlias" => "Front door lock",
            "lockMac" => "C5:40:E0:9C:8C:C1",
            "electricQuantity" => 55,
            "featureValue" => "3F0421C4F5F3",
            "hasGateway" => 1,
            "lockData" => "xxxxxxxxxxxxx",
            "groupId" => 456,
            "groupName" => "The 4th floor",
            "date" => 1528878944000
          }
        ],
        "pageNo" => 1,
        "pageSize" => 20,
        "pages" => 1,
        "total" => 1
      }} = TTlockClient.LockManagement.get_lock_list(
        client_id: "your_client_id",
        access_token: "your_access_token",
        page_no: 1,
        page_size: 20
      )
  """
  @spec get_lock_list(lock_list_config()) :: {:ok, lock_list_response()} | {:error, term()}
  def get_lock_list(opts \\ []) do
    client_id = get_config_value(opts, :client_id)
    access_token = Keyword.fetch!(opts, :access_token)
    page_no = Keyword.get(opts, :page_no, 1)
    page_size = Keyword.get(opts, :page_size, 20)
    lock_alias = Keyword.get(opts, :lock_alias)
    group_id = Keyword.get(opts, :group_id)

    params = [
      {"clientId", client_id},
      {"accessToken", access_token},
      {"pageNo", Integer.to_string(page_no)},
      {"pageSize", Integer.to_string(page_size)},
      {"date", Integer.to_string(current_timestamp())}
    ]

    params = maybe_add_param(params, "lockAlias", lock_alias)
    params = maybe_add_param(params, "groupId", group_id && Integer.to_string(group_id))

    make_get_request(@lock_list_endpoint, params)
  end

  @doc """
  Get detailed information about a specific lock.

  Only the administrator can request this. eKey users should use the Get one eKey API
  to obtain lockData.

  ## Parameters

  - `client_id`: Application clientId
  - `access_token`: Access token from OAuth
  - `lock_id`: Lock ID from Lock init or Lock List API

  ## Returns

  - `{:ok, lock_detail_response}` on success
  - `{:error, reason}` on failure

  ## Example

      {:ok, %{
        "lockId" => 532323,
        "lockName" => "YS1003_c18c9c",
        "lockAlias" => "Front door",
        "lockMac" => "C5:40:E0:9C:8C:C1",
        "noKeyPwd" => "0062386",
        "featureValue" => "3F0421C4F5F3",
        "electricQuantity" => 55,
        "timezoneRawOffset" => 28800000,
        "modelNum" => "SN167-NODFU_PV53",
        "hardwareRevision" => "1.6",
        "firmwareRevision" => "4.1.18.0520",
        "autoLockTime" => -1,
        "lockSound" => 1,
        "privacyLock" => 2,
        "tamperAlert" => 0,
        "resetButton" => 1,
        "openDirection" => 2,
        "passageMode" => 2,
        "passageModeAutoUnlock" => 2,
        "date" => 1528878944000
      }} = TTlockClient.LockManagement.get_lock_details(
        client_id: "your_client_id",
        access_token: "your_access_token",
        lock_id: 532323
      )
  """
  @spec get_lock_details(lock_detail_config()) :: {:ok, lock_detail_response()} | {:error, term()}
  def get_lock_details(opts \\ []) do
    client_id = get_config_value(opts, :client_id)
    access_token = Keyword.fetch!(opts, :access_token)
    lock_id = Keyword.fetch!(opts, :lock_id)

    params = [
      {"clientId", client_id},
      {"accessToken", access_token},
      {"lockId", Integer.to_string(lock_id)},
      {"date", Integer.to_string(current_timestamp())}
    ]

    make_get_request(@lock_detail_endpoint, params)
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

  defp current_timestamp do
    System.system_time(:millisecond)
  end

  defp maybe_add_param(params, _key, nil), do: params
  defp maybe_add_param(params, key, value), do: [{key, value} | params]

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
