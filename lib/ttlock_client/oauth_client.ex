defmodule TTlockClient.OAuthClient do
  @moduledoc """
  HTTP client for TTLock OAuth API endpoints.

  Handles OAuth 2.0 Resource Owner Password grant and refresh token flows
  according to TTLock Open Platform API specifications.
  """

  require Logger
  import TTlockClient.Types

  @type request_params :: map()
  @type http_result :: {:ok, map()} | {:error, term()}
  @type auth_result :: TTlockClient.Types.auth_result()
  @type oauth_error :: TTlockClient.Types.oauth_error()

  @oauth_endpoint "/oauth2/token"
  @request_timeout 30_000

  @doc """
  Retrieves an access token using OAuth 2.0 Resource Owner Password grant.

  ## Parameters
    * `config` - Client configuration record
    * `username` - TTLock app username
    * `password` - Plain text password (will be MD5 hashed)

  ## Returns
    * `{:ok, oauth_response}` - Success with token data
    * `{:error, reason}` - Authentication failure or network error

  ## Example
      iex> config = TTlockClient.Types.new_client_config("client_id", "client_secret")
      iex> TTlockClient.OAuthClient.get_access_token(config, "username", "password")
      {:ok, %{access_token: "...", refresh_token: "...", expires_in: 7776000, uid: 1234}}
  """
  @spec get_access_token(TTlockClient.Types.client_config(), String.t(), String.t()) :: auth_result()
  def get_access_token(
        client_config(client_id: client_id, client_secret: client_secret, base_url: base_url),
        username,
        password
      ) do
    password_hash = hash_password(password)

    params = %{
      "clientId" => client_id,
      "clientSecret" => client_secret,
      "username" => username,
      "password" => password_hash
    }

    Logger.debug("Requesting access token for user: #{username}")

    case make_oauth_request(base_url, params) do
      {:ok, response} ->
        Logger.info("Successfully obtained access token for user: #{username}")
        {:ok, response}

      {:error, reason} = error ->
        Logger.error("Failed to get access token for user #{username}: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Refreshes an expired access token using the refresh token.

  ## Parameters
    * `config` - Client configuration record
    * `refresh_token` - Valid refresh token from previous authentication

  ## Returns
    * `{:ok, oauth_response}` - Success with new token data
    * `{:error, reason}` - Refresh failure or network error

  ## Example
      iex> config = TTlockClient.Types.new_client_config("client_id", "client_secret")
      iex> TTlockClient.OAuthClient.refresh_access_token(config, "refresh_token_here")
      {:ok, %{access_token: "...", refresh_token: "...", expires_in: 7776000}}
  """
  @spec refresh_access_token(TTlockClient.Types.client_config(), String.t()) :: auth_result()
  def refresh_access_token(
        client_config(client_id: client_id, client_secret: client_secret, base_url: base_url),
        refresh_token
      ) do
    params = %{
      "clientId" => client_id,
      "clientSecret" => client_secret,
      "grant_type" => "refresh_token",
      "refresh_token" => refresh_token
    }

    Logger.debug("Refreshing access token")

    case make_oauth_request(base_url, params) do
      {:ok, response} ->
        Logger.info("Successfully refreshed access token")
        {:ok, response}

      {:error, reason} = error ->
        Logger.error("Failed to refresh access token: #{inspect(reason)}")
        error
    end
  end

  # Private functions

  @spec make_oauth_request(String.t(), request_params()) :: http_result()
  defp make_oauth_request(base_url, params) do
    url = base_url <> @oauth_endpoint
    body = URI.encode_query(params)

    headers = [
      {"content-type", "application/x-www-form-urlencoded"}
    ]

    request = Finch.build(:post, url, headers, body)

    case Finch.request(request, TTlockClient.Finch, receive_timeout: @request_timeout) do
      {:ok, %Finch.Response{status: 200, body: response_body}} ->
        parse_response(response_body)

      {:ok, %Finch.Response{status: status, body: response_body}} ->
        Logger.warning("OAuth request failed with status #{status}: #{response_body}")
        parse_error_response(response_body)

      {:error, %Mint.TransportError{reason: reason}} ->
        {:error, {:transport_error, reason}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
    end
  end

  @spec parse_response(String.t()) :: http_result()
  defp parse_response(response_body) do
    case Jason.decode(response_body) do
      {:ok, %{"access_token" => access_token} = response} ->
        oauth_response = %{
          access_token: access_token,
          refresh_token: Map.get(response, "refresh_token"),
          expires_in: Map.get(response, "expires_in", 7_776_000),
          uid: Map.get(response, "uid")
        }

        {:ok, oauth_response}

      {:ok, parsed} ->
        {:error, {:invalid_response, parsed}}

      {:error, reason} ->
        {:error, {:json_decode_error, reason}}
    end
  end

  @spec parse_error_response(String.t()) :: {:error, TTlockClient.Types.oauth_error() | atom()}
  defp parse_error_response(response_body) do
    case Jason.decode(response_body) do
      {:ok, %{"errcode" => error_code, "errmsg" => description}} ->
        error = %{
          error_code: error_code,
          description: description
        }

        {:error, error}

      {:ok, %{"error" => error_type}} ->
        {:error, {:oauth_error, error_type}}

      {:ok, parsed} ->
        {:error, {:unknown_error_format, parsed}}

      {:error, _reason} ->
        {:error, :invalid_error_response}
    end
  end

  @spec hash_password(String.t()) :: String.t()
  defp hash_password(password) do
    :crypto.hash(:md5, password) |> Base.encode16(case: :lower)
  end
end
