defmodule TTlockClient.Gateways do
  @moduledoc """
  Gateway-related API endpoints for TTLock.

  This module handles TTLock gateway management operations including
  listing gateways and retrieving locks associated with gateways.
  """

  require Logger
  import TTlockClient.Types
  alias TTlockClient.AuthManager

  @gateway_list_endpoint "/v3/gateway/list"
  @gateway_locks_endpoint "/v3/gateway/listLock"
  @request_timeout 30_000

  @doc """
  Gets the list of gateways for the authenticated user account.

  Lists all gateways that belong to a user account with pagination and ordering options.

  ## Parameters
    * `page_no` - Page number (starting from 1)
    * `page_size` - Number of items per page (max 200)
    * `order_by` - Sort order: 0 = by name, 1 = reverse by time, 2 = reverse by name

  ## Examples
      {:ok, response} = TTlockClient.Gateways.list(1, 20, 1)

  ## Returns
      * `{:ok, response}` - List of gateways with pagination info
      * `{:error, reason}` - Request failed

  Gateway information includes:
    * `gatewayId` - Gateway ID
    * `gatewayMac` - Gateway MAC address
    * `gatewayName` - Gateway name
    * `gatewayVersion` - Version (1=G1, 2=G2, 3=G3 wired, 4=G4 4G)
    * `networkName` - Connected network name
    * `networkMac` - Connected network MAC
    * `lockNum` - Number of connected locks
    * `isOnline` - Online status (0=No, 1=Yes)
  """
  @spec list(integer(), integer(), integer()) :: {:ok, map()} | {:error, term()}
  def list(page_no, page_size, order_by) do
    Logger.debug(
      "Fetching gateway list - Page: #{page_no}, Size: #{page_size}, Order: #{order_by}"
    )

    with {:ok, auth_data} <- get_auth_data(),
         {:ok, query_params} <-
           build_gateway_list_params(page_no, page_size, order_by, auth_data),
         {:ok, response} <- make_api_request(@gateway_list_endpoint, query_params) do
      Logger.info("Successfully retrieved gateway list")
      {:ok, response}
    end
  end

  @doc """
  Gets the list of locks for a specified gateway.

  The gateway automatically searches for nearby locks and reports them to the
  gateway server. The server maintains a cached many-to-many relationship
  between gateways and locks for 30 minutes.

  ## Parameters
    * `gateway_id` - Gateway ID (integer)

  ## Examples
      {:ok, response} = TTlockClient.Gateways.list_locks(12345)

  ## Returns
      * `{:ok, %{list: [lock_info]}}` - List of locks with their information
      * `{:error, reason}` - Request failed

  Lock information includes:
    * `lockId` - Lock ID
    * `lockName` - Lock name
    * `lockAlias` - User-friendly alias
    * `lockMac` - Lock MAC address
    * `rssi` - Signal strength (-75 to -85 range)
    * `updateDate` - Last signal strength update timestamp (ms)
  """
  @spec list_locks(integer()) :: {:ok, map()} | {:error, term()}
  def list_locks(gateway_id) do
    Logger.debug("Fetching gateway locks for gateway ID: #{gateway_id}")

    with {:ok, auth_data} <- get_auth_data(),
         {:ok, query_params} <- build_gateway_locks_params(gateway_id, auth_data),
         {:ok, response} <- make_api_request(@gateway_locks_endpoint, query_params) do
      Logger.info("Successfully retrieved gateway locks for gateway ID: #{gateway_id}")
      {:ok, response}
    end
  end

  # Private helper functions

  @spec get_auth_data() :: {:ok, {String.t(), String.t()}} | {:error, term()}
  defp get_auth_data do
    with {:ok, access_token} <- AuthManager.get_valid_token(),
         {:ok, client_config} <- get_client_config() do
      client_id = client_config(client_config, :client_id)
      {:ok, {access_token, client_id}}
    else
      {:error, :not_authenticated} ->
        Logger.error("Authentication required for gateway API calls")
        {:error, :not_authenticated}

      {:error, reason} ->
        Logger.error("Failed to get authentication data: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @spec get_client_config() ::
          {:ok, TTlockClient.Types.client_config()} | {:error, :not_configured}
  defp get_client_config do
    AuthManager.get_config()
  end

  @spec build_gateway_list_params(integer(), integer(), integer(), {String.t(), String.t()}) ::
          {:ok, map()}
  defp build_gateway_list_params(page_no, page_size, order_by, {access_token, client_id}) do
    params = %{
      "clientId" => client_id,
      "accessToken" => access_token,
      "pageNo" => page_no,
      "pageSize" => page_size,
      "orderBy" => order_by,
      "date" => System.system_time(:millisecond)
    }

    {:ok, params}
  end

  @spec build_gateway_locks_params(integer(), {String.t(), String.t()}) :: {:ok, map()}
  defp build_gateway_locks_params(gateway_id, {access_token, client_id}) do
    params = %{
      "clientId" => client_id,
      "accessToken" => access_token,
      "gatewayId" => gateway_id,
      "date" => System.system_time(:millisecond)
    }

    {:ok, params}
  end

  @spec make_api_request(String.t(), map()) :: {:ok, map()} | {:error, term()}
  defp make_api_request(endpoint, query_params) do
    case get_client_config() do
      {:ok, config} ->
        base_url = client_config(config, :base_url)
        url = base_url <> endpoint <> "?" <> URI.encode_query(query_params)

        Logger.debug("Making gateway API request to: #{endpoint}")

        request = Finch.build(:get, url, [])

        case Finch.request(request, TTlockClient.Finch, receive_timeout: @request_timeout) do
          {:ok, %Finch.Response{status: 200, body: response_body}} ->
            parse_response(response_body)

          {:ok, %Finch.Response{status: status, body: response_body}} ->
            Logger.warning("Gateway API request failed with status #{status}: #{response_body}")
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
      {:ok, %{"list" => _} = response} ->
        {:ok, response}

      {:ok, parsed} ->
        {:error, {:invalid_response, parsed}}

      {:error, reason} ->
        {:error, {:json_decode_error, reason}}
    end
  end

  @spec parse_error_response(String.t()) :: {:error, map() | term()}
  defp parse_error_response(response_body) do
    case Jason.decode(response_body) do
      {:ok, %{"errcode" => error_code, "errmsg" => error_msg}} ->
        {:error, %{error_code: error_code, description: error_msg}}

      {:ok, parsed} ->
        {:error, {:api_error, parsed}}

      {:error, _reason} ->
        {:error, {:unknown_error, response_body}}
    end
  end
end
