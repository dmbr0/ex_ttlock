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
  alias TTlockClient.Locks
  alias TTlockClient.Passcodes

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

  @doc """
  Convenience function to start with environment variables.

  Reads TTLOCK_CLIENT_ID, TTLOCK_CLIENT_SECRET, TTLOCK_USERNAME,
  and TTLOCK_PASSWORD from environment variables and configures/authenticates.

  ## Examples
      # Ensure your .env file has the required variables
      TTlockClient.start_with_env()

  ## Returns
    * `:ok` - Configuration and authentication successful
    * `{:error, :missing_env_vars}` - Required environment variables not set
    * `{:error, reason}` - Setup failed
  """
  @spec start_with_env() :: :ok | {:error, term()}
  def start_with_env do
    client_id = System.get_env("TTLOCK_CLIENT_ID")
    client_secret = System.get_env("TTLOCK_CLIENT_SECRET")
    username = System.get_env("TTLOCK_USERNAME")
    password = System.get_env("TTLOCK_PASSWORD")

    case {client_id, client_secret, username, password} do
      {nil, _, _, _} -> {:error, {:missing_env_var, "TTLOCK_CLIENT_ID"}}
      {_, nil, _, _} -> {:error, {:missing_env_var, "TTLOCK_CLIENT_SECRET"}}
      {_, _, nil, _} -> {:error, {:missing_env_var, "TTLOCK_USERNAME"}}
      {_, _, _, nil} -> {:error, {:missing_env_var, "TTLOCK_PASSWORD"}}
      {cid, cs, u, p} -> start(cid, cs, u, p)
    end
  end

  # Lock Management Functions

  @doc """
  Gets the list of locks for the authenticated user.

  ## Parameters
    * `page_no` - Page number (default 1)
    * `page_size` - Items per page (default 20, max 1000)
    * `lock_alias` - Optional filter by lock alias
    * `group_id` - Optional filter by group ID

  ## Examples
      # Get first page with defaults
      {:ok, locks} = TTlockClient.get_locks()

      # Get specific page
      {:ok, locks} = TTlockClient.get_locks(2, 50)

      # Filter by lock alias
      {:ok, locks} = TTlockClient.get_locks(1, 20, "Front Door")

  ## Returns
    * `{:ok, response}` - Contains list, pagination info
    * `{:error, reason}` - Request failed
  """
  @spec get_locks(integer(), integer(), String.t() | nil, integer() | nil) ::
    {:ok, map()} | {:error, term()}
  def get_locks(page_no \\ 1, page_size \\ 20, lock_alias \\ nil, group_id \\ nil) do
    params = TTlockClient.Types.new_lock_list_params(page_no, page_size, lock_alias, group_id)
    Locks.get_lock_list(params)
  end

  @doc """
  Gets detailed information about a specific lock.

  ## Parameters
    * `lock_id` - The ID of the lock to retrieve

  ## Examples
      {:ok, lock_detail} = TTlockClient.get_lock(12345)

  ## Returns
    * `{:ok, lock_detail}` - Detailed lock information
    * `{:error, reason}` - Request failed or lock not found
  """
  @spec get_lock(integer()) :: {:ok, map()} | {:error, term()}
  def get_lock(lock_id) when is_integer(lock_id) do
    Locks.get_lock(lock_id)
  end

  @doc """
  Gets all locks for the authenticated user (handles pagination automatically).

  ## Parameters
    * `lock_alias` - Optional filter by lock alias
    * `group_id` - Optional filter by group ID

  ## Examples
      {:ok, all_locks} = TTlockClient.get_all_locks()
      {:ok, filtered_locks} = TTlockClient.get_all_locks("Front Door")

  ## Returns
    * `{:ok, [lock_records]}` - List of all locks
    * `{:error, reason}` - Request failed
  """
  @spec get_all_locks(String.t() | nil, integer() | nil) :: {:ok, [map()]} | {:error, term()}
  def get_all_locks(lock_alias \\ nil, group_id \\ nil) do
    Locks.get_all_locks(100, lock_alias, group_id)
  end

  # Passcode Management Functions

  @doc """
  Adds a permanent passcode to a lock via gateway.

  ## Parameters
    * `lock_id` - The lock ID to add the passcode to
    * `passcode` - The 4-9 digit passcode
    * `name` - Optional name/alias for the passcode

  ## Examples
      {:ok, %{keyboardPwdId: passcode_id}} = TTlockClient.add_permanent_passcode(12345, 123456, "Guest")

  ## Returns
    * `{:ok, response}` - Contains keyboardPwdId
    * `{:error, reason}` - Request failed
  """
  @spec add_permanent_passcode(integer(), integer(), String.t() | nil) ::
    {:ok, map()} | {:error, term()}
  def add_permanent_passcode(lock_id, passcode, name \\ nil) do
    Passcodes.add_permanent_passcode(lock_id, passcode, name)
  end

  @doc """
  Adds a temporary passcode to a lock via gateway.

  ## Parameters
    * `lock_id` - The lock ID to add the passcode to
    * `passcode` - The 4-9 digit passcode
    * `start_date` - Start time (DateTime or milliseconds)
    * `end_date` - End time (DateTime or milliseconds)
    * `name` - Optional name/alias for the passcode

  ## Examples
      start_time = DateTime.utc_now()
      end_time = DateTime.add(start_time, 7, :day)
      {:ok, result} = TTlockClient.add_temporary_passcode(12345, 987654, start_time, end_time, "Week Access")

  ## Returns
    * `{:ok, response}` - Contains keyboardPwdId
    * `{:error, reason}` - Request failed
  """
  @spec add_temporary_passcode(integer(), integer(), DateTime.t() | integer(), DateTime.t() | integer(), String.t() | nil) ::
    {:ok, map()} | {:error, term()}
  def add_temporary_passcode(lock_id, passcode, start_date, end_date, name \\ nil) do
    Passcodes.add_temporary_passcode(lock_id, passcode, start_date, end_date, name)
  end

  @doc """
  Adds a custom passcode with full control over parameters.

  ## Parameters
    * `lock_id` - The lock ID to add the passcode to
    * `passcode` - The 4-9 digit passcode
    * `name` - Optional name/alias for the passcode
    * `passcode_type` - 2 = permanent, 3 = period
    * `start_date` - Start time in milliseconds (required for period type)
    * `end_date` - End time in milliseconds (required for period type)
    * `add_type` - 1 = Bluetooth, 2 = Gateway/WiFi

  ## Examples
      # Permanent passcode via gateway
      {:ok, result} = TTlockClient.add_passcode(12345, 123456, "Guest", 2, nil, nil, 2)

      # Temporary passcode via Bluetooth (requires mobile app first)
      start_ms = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      end_ms = DateTime.add(DateTime.utc_now(), 7, :day) |> DateTime.to_unix(:millisecond)
      {:ok, result} = TTlockClient.add_passcode(12345, 555999, "Visitor", 3, start_ms, end_ms, 1)

  ## Returns
    * `{:ok, response}` - Contains keyboardPwdId
    * `{:error, reason}` - Request failed
  """
  @spec add_passcode(integer(), integer(), String.t() | nil, integer(), integer() | nil, integer() | nil, integer()) ::
    {:ok, map()} | {:error, term()}
  def add_passcode(lock_id, passcode, name \\ nil, passcode_type \\ 3, start_date \\ nil, end_date \\ nil, add_type \\ 2) do
    params = TTlockClient.Types.new_passcode_add_params(lock_id, passcode, name, passcode_type, start_date, end_date, add_type)
    Passcodes.add_passcode(params)
  end

  @doc """
  Deletes a passcode from a lock via gateway.

  The passcode will be deleted directly via the cloud API for WiFi locks
  or locks connected to a gateway.

  ## Parameters
    * `lock_id` - The lock ID containing the passcode
    * `passcode_id` - The passcode ID to delete

  ## Examples
      {:ok, result} = TTlockClient.delete_passcode(12345, 67890)

  ## Returns
    * `{:ok, response}` - Success with status information
    * `{:error, reason}` - Request failed
  """
  @spec delete_passcode(integer(), integer()) :: {:ok, map()} | {:error, term()}
  def delete_passcode(lock_id, passcode_id) do
    params = TTlockClient.Types.new_passcode_delete_params(lock_id, passcode_id)
    Passcodes.delete_passcode(params)
  end

  @doc """
  Convenience function to delete a passcode via gateway.

  This is an alias for `delete_passcode/2` for clarity.

  ## Parameters
    * `lock_id` - The lock ID containing the passcode
    * `passcode_id` - The passcode ID to delete

  ## Examples
      {:ok, result} = TTlockClient.delete_passcode_via_gateway(12345, 67890)

  ## Returns
    * `{:ok, response}` - Success with status information
    * `{:error, reason}` - Request failed
  """
  @spec delete_passcode_via_gateway(integer(), integer()) :: {:ok, map()} | {:error, term()}
  def delete_passcode_via_gateway(lock_id, passcode_id) do
    Passcodes.delete_passcode_via_gateway(lock_id, passcode_id)
  end

  @doc """
  Gets all passcodes for a lock.

  ## Parameters
    * `lock_id` - The lock ID to get passcodes for
    * `search_str` - Optional search keyword (fuzzy search by name or exact match by passcode)
    * `page_no` - Page number (default 1)
    * `page_size` - Items per page (default 20, max 200)
    * `order_by` - Sorting: 0 = by name, 1 = reverse by time, 2 = reverse by name (default 1)

  ## Examples
      # Get all passcodes for a lock
      {:ok, %{list: passcodes, total: count}} = TTlockClient.get_passcodes(12345)

      # Search for specific passcodes
      {:ok, response} = TTlockClient.get_passcodes(12345, "Guest")

      # Get specific page
      {:ok, response} = TTlockClient.get_passcodes(12345, nil, 2, 50, 1)

  ## Returns
    * `{:ok, response}` - Contains list, pagination info
    * `{:error, reason}` - Request failed
  """
  @spec get_passcodes(integer(), String.t() | nil, integer(), integer(), integer()) ::
    {:ok, map()} | {:error, term()}
  def get_passcodes(lock_id, search_str \\ nil, page_no \\ 1, page_size \\ 20, order_by \\ 1) do
    params = TTlockClient.Types.new_passcode_list_params(lock_id, search_str, page_no, page_size, order_by)
    Passcodes.get_passcode_list(params)
  end

  @doc """
  Gets all passcodes for a lock (convenience function).

  ## Parameters
    * `lock_id` - The lock ID to get passcodes for
    * `search_str` - Optional search string

  ## Examples
      {:ok, %{list: passcodes}} = TTlockClient.get_lock_passcodes(12345)
      {:ok, results} = TTlockClient.get_lock_passcodes(12345, "Guest")

  ## Returns
    * `{:ok, response}` - Contains list of passcodes
    * `{:error, reason}` - Request failed
  """
  @spec get_lock_passcodes(integer(), String.t() | nil) :: {:ok, map()} | {:error, term()}
  def get_lock_passcodes(lock_id, search_str \\ nil) do
    Passcodes.get_lock_passcodes(lock_id, search_str)
  end

  @doc """
  Searches passcodes by name or passcode value.

  ## Parameters
    * `lock_id` - The lock ID to search in
    * `search_term` - Search term (name or exact passcode match)

  ## Examples
      {:ok, results} = TTlockClient.search_passcodes(12345, "Guest")
      {:ok, results} = TTlockClient.search_passcodes(12345, "123456")

  ## Returns
    * `{:ok, response}` - Contains matching passcodes
    * `{:error, reason}` - Request failed
  """
  @spec search_passcodes(integer(), String.t()) :: {:ok, map()} | {:error, term()}
  def search_passcodes(lock_id, search_term) do
    Passcodes.search_passcodes(lock_id, search_term)
  end
end
