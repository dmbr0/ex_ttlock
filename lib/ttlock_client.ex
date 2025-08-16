defmodule TTlockClient do
  @moduledoc """
  TTLock client library for Elixir.

  This library provides a clean, centralized interface to the TTLock Open Platform API
  with automatic OAuth 2.0 token management and refresh capabilities.

  ## Getting Started

  First, configure your client credentials:

      TTlockClient.configure("your_client_id", "your_client_secret")

  Then authenticate with your TTLock app credentials:

      TTlockClient.authenticate("your_username", "your_password")

  Now you can get valid tokens for API requests:

      {:ok, token} = TTlockClient.get_valid_token()

  ## Configuration

  The library supports configuration through application config:

      config :ex_ttlock,
        client_id: "your_client_id",
        client_secret: "your_client_secret",
        base_url: "https://euapi.ttlock.com"  # optional

  ## Architecture

  This library implements a centralized authentication state manager using GenServer
  that handles all token lifecycle management. This eliminates the need for
  module-specific authentication logic and provides thread-safe access to tokens
  across your application.

  Key features:
  - Automatic token refresh before expiry
  - Thread-safe token access
  - Centralized authentication state
  - Error handling and recovery
  - Proper OTP supervision
  """

  alias TTlockClient.AuthManager

  @doc """
  Configures the TTLock client with your application credentials.

  ## Parameters
    * `client_id` - Your application's client ID from the TTLock developer portal
    * `client_secret` - Your application's client secret from the TTLock developer portal
    * `base_url` - Optional API base URL (defaults to EU endpoint)

  ## Examples
      TTlockClient.configure("your_client_id", "your_client_secret")

      # For different regions
      TTlockClient.configure("client_id", "client_secret", "https://usapi.ttlock.com")

  ## Returns
    * `:ok` - Configuration successful
    * `{:error, reason}` - Configuration failed
  """
  @spec configure(String.t(), String.t(), String.t()) :: :ok | {:error, term()}
  def configure(client_id, client_secret, base_url \\ "https://euapi.ttlock.com") do
    AuthManager.configure(client_id, client_secret, base_url)
  end

  @doc """
  Authenticates with TTLock using your app credentials.

  **Important:** Use your TTLock mobile app credentials here, not your developer
  portal credentials. The username should be the same one you use to log into
  the TTLock mobile application.

  ## Parameters
    * `username` - Your TTLock app username (often a phone number like "+8618966498228")
    * `password` - Your TTLock app password (will be MD5 hashed automatically)

  ## Examples
      TTlockClient.authenticate("+8618966498228", "your_password")
      TTlockClient.authenticate("your_email@example.com", "your_password")

  ## Returns
    * `:ok` - Authentication successful, tokens stored
    * `{:error, reason}` - Authentication failed

  Common error reasons:
    * `:not_configured` - Need to call `configure/2` first
    * `%{error_code: code, description: msg}` - TTLock API error
    * Network/HTTP errors
  """
  @spec authenticate(String.t(), String.t()) :: :ok | {:error, term()}
  def authenticate(username, password) do
    AuthManager.authenticate(username, password)
  end

  @doc """
  Gets a valid access token for API requests.

  This function will automatically refresh the token if it's expired or near expiry.
  The returned token can be used immediately for TTLock API requests.

  ## Examples
      case TTlockClient.get_valid_token() do
        {:ok, token} ->
          # Use token in your API requests
          headers = [{"Authorization", "Bearer " <> token}]

        {:error, :not_authenticated} ->
          # Need to authenticate first
          TTlockClient.authenticate("username", "password")

        {:error, reason} ->
          # Handle other errors
          Logger.error("Token error: " <> inspect(reason))
      end

  ## Returns
    * `{:ok, access_token}` - Valid token ready for use
    * `{:error, :not_authenticated}` - Need to authenticate first
    * `{:error, reason}` - Token refresh or other error
  """
  @spec get_valid_token() :: {:ok, String.t()} | {:error, term()}
  def get_valid_token do
    AuthManager.get_valid_token()
  end

  @doc """
  Gets the user ID of the currently authenticated user.

  ## Examples
      {:ok, user_id} = TTlockClient.get_user_id()

  ## Returns
    * `{:ok, user_id}` - Current user's ID
    * `{:error, :not_authenticated}` - No user currently authenticated
  """
  @spec get_user_id() :: {:ok, integer()} | {:error, :not_authenticated}
  def get_user_id do
    AuthManager.get_user_id()
  end

  @doc """
  Manually refreshes the current access token.

  Normally you don't need to call this as tokens are refreshed automatically,
  but this can be useful for testing or if you need to force a refresh.

  ## Examples
      TTlockClient.refresh_token()

  ## Returns
    * `:ok` - Token refreshed successfully
    * `{:error, reason}` - Refresh failed
  """
  @spec refresh_token() :: :ok | {:error, term()}
  def refresh_token do
    AuthManager.refresh_token()
  end

  @doc """
  Gets the current authentication status.

  ## Examples
      case TTlockClient.status() do
        :not_configured ->
          # Need to call configure/2
        :configured ->
          # Configured but not authenticated
        :authenticated ->
          # Ready to make API calls
      end

  ## Returns
    * `:not_configured` - Client credentials not set
    * `:configured` - Client configured but not authenticated
    * `:authenticated` - Ready for API requests
  """
  @spec status() :: :not_configured | :configured | :authenticated
  def status do
    AuthManager.status()
  end

  @doc """
  Resets all authentication state.

  This clears stored tokens and credentials. You'll need to configure
  and authenticate again after calling this.

  ## Examples
      TTlockClient.reset()
      TTlockClient.configure("new_client_id", "new_client_secret")
      TTlockClient.authenticate("username", "password")

  ## Returns
    * `:ok` - State cleared successfully
  """
  @spec reset() :: :ok
  def reset do
    AuthManager.reset()
  end

  @doc """
  Convenience function to configure and authenticate in one call.

  ## Parameters
    * `client_id` - Application client ID
    * `client_secret` - Application client secret
    * `username` - TTLock app username
    * `password` - TTLock app password
    * `base_url` - Optional API base URL

  ## Examples
      TTlockClient.start("client_id", "client_secret", "username", "password")

  ## Returns
    * `:ok` - Configuration and authentication successful
    * `{:error, reason}` - Setup failed
  """
  @spec start(String.t(), String.t(), String.t(), String.t(), String.t()) :: :ok | {:error, term()}
  def start(client_id, client_secret, username, password, base_url \\ "https://euapi.ttlock.com") do
    with :ok <- configure(client_id, client_secret, base_url),
         :ok <- authenticate(username, password) do
      :ok
    end
  end

  @doc """
  Helper function to check if the client is ready for API calls.

  ## Examples
      if TTlockClient.ready?() do
        {:ok, token} = TTlockClient.get_valid_token()
        # Make API calls
      else
        # Need to configure/authenticate
      end

  ## Returns
    * `true` - Client is authenticated and ready
    * `false` - Client needs configuration or authentication
  """
  @spec ready?() :: boolean()
  def ready? do
    status() == :authenticated
  end
end
