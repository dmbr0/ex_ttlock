defmodule TTlockClient.Locks do
  @moduledoc """
  TTLock Locks API client.

  Provides functions to interact with TTLock's lock management endpoints.
  Handles retrieving lock lists and detailed lock information.

  All functions automatically retrieve valid access tokens and client configuration
  from the TTlockClient.AuthManager, so authentication must be set up first.

  ## Examples

      # Get list of locks (first page, 20 items)
      {:ok, locks} = TTlockClient.Locks.get_lock_list()

      # Get specific page with custom size
      params = TTlockClient.Types.new_lock_list_params(2, 50)
      {:ok, locks} = TTlockClient.Locks.get_lock_list(params)

      # Get lock details
      detail_params = TTlockClient.Types.new_lock_detail_params(12345)
      {:ok, lock_detail} = TTlockClient.Locks.get_lock_detail(detail_params)
  """

  require Logger
  import TTlockClient.Types

  alias TTlockClient.AuthManager

  @type lock_api_result :: TTlockClient.Types.lock_api_result()
  @type lock_list_params :: TTlockClient.Types.lock_list_params()
  @type lock_detail_params :: TTlockClient.Types.lock_detail_params()

  @lock_list_endpoint "/v3/lock/list"
  @lock_detail_endpoint "/v3/lock/detail"
  @request_timeout 30_000

  @doc """
  Retrieves the list of locks for the authenticated user.

  Returns locks where the user is the top administrator. Locks shared with the user
  via ekeys are not included (use ekey endpoints for those).

  ## Parameters
    * `params` - Lock list parameters (optional, uses defaults if not provided)

  ## Examples
      # Get first page with default settings (page 1, 20 items)
      {:ok, response} = TTlockClient.Locks.get_lock_list()

      # Custom pagination and filtering
      params = TTlockClient.Types.new_lock_list_params(2, 50, "Front Door", 123)
      {:ok, response} = TTlockClient.Locks.get_lock_list(params)

      # Access the results
      %{list: locks, total: total_count} = response

  ## Returns
    * `{:ok, lock_list_response}` - Success with lock list data
    * `{:error, :not_authenticated}` - Authentication required
    * `{:error, reason}` - API call failed
  """
  @spec get_lock_list(TTlockClient.Types.lock_list_params() | nil) :: lock_api_result()
  def get_lock_list(params \\ nil) do
    params = params || new_lock_list_params()

    Logger.debug(
      "Fetching lock list - Page: #{lock_list_params(params, :page_no)}, Size: #{lock_list_params(params, :page_size)}"
    )

    with {:ok, auth_data} <- get_auth_data(),
         {:ok, query_params} <- build_lock_list_params(params, auth_data),
         {:ok, response} <- make_api_request(@lock_list_endpoint, query_params) do
      Logger.info(
        "Successfully retrieved lock list - Total locks: #{Map.get(response, "total", 0)}"
      )

      {:ok, parse_lock_list_response(response)}
    end
  end

  @doc """
  Retrieves detailed information about a specific lock.

  Only the lock's administrator can access this endpoint. Ekey users should use
  the ekey endpoints to obtain lock data.

  ## Parameters
    * `params` - Lock detail parameters containing the lock ID

  ## Examples
      detail_params = TTlockClient.Types.new_lock_detail_params(12345)
      {:ok, lock_detail} = TTlockClient.Locks.get_lock_detail(detail_params)

      # Access lock information
      %{lockName: name, electricQuantity: battery} = lock_detail

  ## Returns
    * `{:ok, lock_detail_response}` - Success with detailed lock information
    * `{:error, :not_authenticated}` - Authentication required
    * `{:error, reason}` - API call failed or lock not found
  """
  @spec get_lock_detail(TTlockClient.Types.lock_detail_params()) :: lock_api_result()
  def get_lock_detail(lock_detail_params(lock_id: lock_id) = params) do
    Logger.debug("Fetching lock details for lock ID: #{lock_id}")

    with {:ok, auth_data} <- get_auth_data(),
         {:ok, query_params} <- build_lock_detail_params(params, auth_data),
         {:ok, response} <- make_api_request(@lock_detail_endpoint, query_params) do
      Logger.info("Successfully retrieved lock details for lock ID: #{lock_id}")
      {:ok, parse_lock_detail_response(response)}
    end
  end

  @doc """
  Convenience function to get a specific lock by ID.

  ## Parameters
    * `lock_id` - The lock ID to retrieve details for

  ## Example
      {:ok, lock_detail} = TTlockClient.Locks.get_lock(12345)
  """
  @spec get_lock(integer()) :: lock_api_result()
  def get_lock(lock_id) when is_integer(lock_id) do
    params = new_lock_detail_params(lock_id)
    get_lock_detail(params)
  end

  @doc """
  Convenience function to get all locks (handles pagination automatically).

  Retrieves all locks by making multiple API calls if necessary. Be careful with
  accounts that have many locks as this could result in many API calls.

  ## Parameters
    * `page_size` - Number of locks to fetch per page (default 100, max 1000)
    * `lock_alias` - Optional filter by lock alias
    * `group_id` - Optional filter by group ID

  ## Example
      {:ok, all_locks} = TTlockClient.Locks.get_all_locks()
      {:ok, filtered_locks} = TTlockClient.Locks.get_all_locks(50, "Front", 123)
  """
  @spec get_all_locks(integer(), String.t() | nil, integer() | nil) ::
          {:ok, [map()]} | {:error, term()}
  def get_all_locks(page_size \\ 100, lock_alias \\ nil, group_id \\ nil) do
    get_all_locks_recursive([], 1, page_size, lock_alias, group_id)
  end

  # Private functions

  @spec get_auth_data() :: {:ok, {String.t(), String.t()}} | {:error, term()}
  defp get_auth_data do
    with {:ok, access_token} <- AuthManager.get_valid_token(),
         {:ok, client_config} <- get_client_config() do
      client_id = client_config(client_config, :client_id)
      {:ok, {access_token, client_id}}
    else
      {:error, :not_authenticated} ->
        Logger.error("Authentication required for lock API calls")
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

  @spec build_lock_list_params(TTlockClient.Types.lock_list_params(), {String.t(), String.t()}) ::
          {:ok, map()}
  defp build_lock_list_params(params, {access_token, client_id}) do
    base_params = %{
      "clientId" => client_id,
      "accessToken" => access_token,
      "pageNo" => lock_list_params(params, :page_no),
      "pageSize" => lock_list_params(params, :page_size),
      "date" => current_timestamp_ms()
    }

    optional_params =
      []
      |> maybe_add_param("lockAlias", lock_list_params(params, :lock_alias))
      |> maybe_add_param("groupId", lock_list_params(params, :group_id))
      |> Enum.into(%{})

    query_params = Map.merge(base_params, optional_params)
    {:ok, query_params}
  end

  @spec build_lock_detail_params(
          TTlockClient.Types.lock_detail_params(),
          {String.t(), String.t()}
        ) :: {:ok, map()}
  defp build_lock_detail_params(params, {access_token, client_id}) do
    query_params = %{
      "clientId" => client_id,
      "accessToken" => access_token,
      "lockId" => lock_detail_params(params, :lock_id),
      "date" => current_timestamp_ms()
    }

    {:ok, query_params}
  end

  @spec maybe_add_param([{String.t(), any()}], String.t(), any()) :: [{String.t(), any()}]
  defp maybe_add_param(params, _key, nil), do: params
  defp maybe_add_param(params, key, value), do: [{key, value} | params]

  @spec make_api_request(String.t(), map()) :: {:ok, map()} | {:error, term()}
  defp make_api_request(endpoint, query_params) do
    # Get base URL from config
    case get_client_config() do
      {:ok, config} ->
        base_url = client_config(config, :base_url)
        url = base_url <> endpoint <> "?" <> URI.encode_query(query_params)

        Logger.debug("Making lock API request to: #{endpoint}")

        request = Finch.build(:get, url, [])

        case Finch.request(request, TTlockClient.Finch, receive_timeout: @request_timeout) do
          {:ok, %Finch.Response{status: 200, body: response_body}} ->
            parse_response(response_body)

          {:ok, %Finch.Response{status: status, body: response_body}} ->
            Logger.warning("Lock API request failed with status #{status}: #{response_body}")
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
        # Lock list response
        {:ok, response}

      {:ok, %{"lockId" => _} = response} ->
        # Lock detail response
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

  @spec parse_lock_list_response(map()) :: map()
  defp parse_lock_list_response(response) do
    %{
      list: response["list"] || [],
      pageNo: response["pageNo"] || 1,
      pageSize: response["pageSize"] || 20,
      pages: response["pages"] || 1,
      total: response["total"] || 0
    }
  end

  @spec parse_lock_detail_response(map()) :: map()
  defp parse_lock_detail_response(response) do
    # Convert string keys to atoms for easier access
    response
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Enum.into(%{})
  end

  @spec current_timestamp_ms() :: integer()
  defp current_timestamp_ms do
    DateTime.utc_now() |> DateTime.to_unix(:millisecond)
  end

  @spec get_all_locks_recursive([map()], integer(), integer(), String.t() | nil, integer() | nil) ::
          {:ok, [map()]} | {:error, term()}
  defp get_all_locks_recursive(acc_locks, page_no, page_size, lock_alias, group_id) do
    params = new_lock_list_params(page_no, page_size, lock_alias, group_id)

    case get_lock_list(params) do
      {:ok, %{list: locks, pages: total_pages}} ->
        all_locks = acc_locks ++ locks

        if page_no >= total_pages do
          {:ok, all_locks}
        else
          get_all_locks_recursive(all_locks, page_no + 1, page_size, lock_alias, group_id)
        end

      {:error, reason} = error ->
        Logger.error("Failed to fetch page #{page_no} of locks: #{inspect(reason)}")
        error
    end
  end
end
