defmodule TTlockClient.Types do
  @moduledoc """
  Type definitions and records for TTLock client library.
  """

  require Record

  # Client configuration record
  Record.defrecord(:client_config,
    client_id: nil,
    client_secret: nil,
    base_url: "https://euapi.ttlock.com"
  )

  # Token information record
  Record.defrecord(:token_info,
    access_token: nil,
    refresh_token: nil,
    expires_at: nil,
    uid: nil
  )

  # Authentication credentials record
  Record.defrecord(:auth_credentials,
    username: nil,
    password_hash: nil
  )

  @type client_config :: record(:client_config,
          client_id: String.t(),
          client_secret: String.t(),
          base_url: String.t()
        )

  @type token_info :: record(:token_info,
          access_token: String.t() | nil,
          refresh_token: String.t() | nil,
          expires_at: DateTime.t() | nil,
          uid: integer() | nil
        )

  @type auth_credentials :: record(:auth_credentials,
          username: String.t(),
          password_hash: String.t()
        )

  @type oauth_response :: %{
          access_token: String.t(),
          refresh_token: String.t(),
          expires_in: integer(),
          uid: integer()
        }

  @type oauth_error :: %{
          error_code: integer(),
          description: String.t()
        }

  @type auth_result :: {:ok, oauth_response()} | {:error, oauth_error() | atom()}

  # Error codes
  @expired_token_error 10004

  def expired_token_error, do: @expired_token_error

  @doc """
  Creates a new client configuration record.
  """
  @spec new_client_config(String.t(), String.t(), String.t()) :: client_config()
  def new_client_config(client_id, client_secret, base_url \\ "https://euapi.ttlock.com") do
    client_config(
      client_id: client_id,
      client_secret: client_secret,
      base_url: base_url
    )
  end

  @doc """
  Creates a new token info record from OAuth response.
  """
  @spec new_token_info(oauth_response()) :: token_info()
  def new_token_info(%{
        access_token: access_token,
        refresh_token: refresh_token,
        expires_in: expires_in,
        uid: uid
      }) do
    expires_at = DateTime.add(DateTime.utc_now(), expires_in, :second)

    token_info(
      access_token: access_token,
      refresh_token: refresh_token,
      expires_at: expires_at,
      uid: uid
    )
  end

  @doc """
  Creates authentication credentials with MD5 hashed password.
  """
  @spec new_auth_credentials(String.t(), String.t()) :: auth_credentials()
  def new_auth_credentials(username, password) do
    password_hash = :crypto.hash(:md5, password) |> Base.encode16(case: :lower)

    auth_credentials(
      username: username,
      password_hash: password_hash
    )
  end

  @doc """
  Checks if a token is expired or will expire within the given buffer seconds.
  """
  @spec token_expired?(token_info(), integer()) :: boolean()
  def token_expired?(token_info, buffer \\ 300)

  def token_expired?(token_info(expires_at: nil), _buffer) do
    true
  end

  def token_expired?(token_info(expires_at: expires_at), buffer) do
    buffer_time = DateTime.add(DateTime.utc_now(), buffer, :second)
    DateTime.compare(expires_at, buffer_time) != :gt
  end

  @doc """
  Checks if a token info record has valid token data.
  """
  @spec valid_token_info?(token_info()) :: boolean()
  def valid_token_info?(
        token_info(
          access_token: access_token,
          refresh_token: refresh_token
        )
      )
      when is_binary(access_token) and is_binary(refresh_token) do
    true
  end

  def valid_token_info?(_), do: false
end
