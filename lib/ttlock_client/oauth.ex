defmodule TTlockClient.OAuth do
  @moduledoc """
  TTLock OAuth2 client for authentication and token management.

  This module handles:
  - Getting access tokens using Resource Owner Password Credentials
  - Refreshing expired access tokens
  - Password hashing (MD5) for TTLock API requirements

  ## Usage

      # Get access token
      {:ok, response} = TTlockClient.OAuth.get_access_token(
        client_id: "your_client_id",
        client_secret: "your_client_secret", 
        username: "+8618966498228",
        password: "your_password"
      )
      
      # Refresh token
      {:ok, response} = TTlockClient.OAuth.refresh_token(
        client_id: "your_client_id",
        client_secret: "your_client_secret",
        refresh_token: "existing_refresh_token"
      )
  """

  @base_url "https://euapi.ttlock.com"
  @token_endpoint "/oauth2/token"

  @type oauth_config :: [
          client_id: String.t(),
          client_secret: String.t(),
          username: String.t(),
          password: String.t()
        ]

  @type refresh_config :: [
          client_id: String.t(),
          client_secret: String.t(),
          refresh_token: String.t()
        ]

  @type token_response :: %{
          access_token: String.t(),
          uid: integer(),
          refresh_token: String.t(),
          expires_in: integer()
        }

  @type refresh_response :: %{
          access_token: String.t(),
          refresh_token: String.t(),
          expires_in: integer()
        }

  @doc """
  Get an access token using TTLock app account credentials.

  ## Parameters

  - `client_id`: Application clientId from TTLock Create Application page
  - `client_secret`: Application clientSecret from TTLock Create Application page  
  - `username`: TTLock app account username (or prefixed username from User Register API)
  - `password`: Plain text password (will be MD5 hashed automatically)

  ## Returns

  - `{:ok, token_response}` on success
  - `{:error, reason}` on failure

  ## Example

      {:ok, %{
        "access_token" => "39caac89b0b51c980aa61ad4264b693b",
        "uid" => 2340,
        "refresh_token" => "1bd2a21a7df889630f444364813738d7",
        "expires_in" => 7776000
      }} = TTlockClient.OAuth.get_access_token(
        client_id: "your_client_id",
        client_secret: "your_client_secret",
        username: "+8618966498228", 
        password: "your_password"
      )
  """
  @spec get_access_token(oauth_config()) :: {:ok, token_response()} | {:error, term()}
  def get_access_token(opts \\ []) do
    client_id = get_config_value(opts, :client_id)
    client_secret = get_config_value(opts, :client_secret)
    username = get_config_value(opts, :username)
    password = get_config_value(opts, :password)

    hashed_password = hash_password(password)

    params = [
      {"clientId", client_id},
      {"clientSecret", client_secret},
      {"username", username},
      {"password", hashed_password}
    ]

    make_token_request(params)
  end

  @doc """
  Refresh an expired access token using a refresh token.

  ## Parameters

  - `client_id`: Application clientId
  - `client_secret`: Application clientSecret
  - `refresh_token`: Refresh token obtained from previous get_access_token call

  ## Returns

  - `{:ok, refresh_response}` on success
  - `{:error, reason}` on failure

  ## Example

      {:ok, %{
        "access_token" => "39caac89b0b51c980aa61ad4264b693b",
        "refresh_token" => "1bd2a21a7df889630f444364813738d7", 
        "expires_in" => 7776000
      }} = TTlockClient.OAuth.refresh_token(
        client_id: "your_client_id",
        client_secret: "your_client_secret",
        refresh_token: "existing_refresh_token"
      )
  """
  @spec refresh_token(refresh_config()) :: {:ok, refresh_response()} | {:error, term()}
  def refresh_token(opts \\ []) do
    client_id = get_config_value(opts, :client_id)
    client_secret = get_config_value(opts, :client_secret)
    refresh_token = Keyword.fetch!(opts, :refresh_token)

    params = [
      {"clientId", client_id},
      {"clientSecret", client_secret},
      {"grant_type", "refresh_token"},
      {"refresh_token", refresh_token}
    ]

    make_token_request(params)
  end

  @doc """
  Hash a password using MD5 as required by TTLock API.

  Returns a 32-character lowercase MD5 hash.

  ## Example

      iex> TTlockClient.OAuth.hash_password("123456")
      "e10adc3949ba59abbe56e057f20f883e"
  """
  @spec hash_password(String.t()) :: String.t()
  def hash_password(password) when is_binary(password) do
    :crypto.hash(:md5, password)
    |> Base.encode16(case: :lower)
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

  defp make_token_request(params) do
    url = @base_url <> @token_endpoint
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
end
