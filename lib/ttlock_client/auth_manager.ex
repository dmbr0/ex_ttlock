defmodule TTlockClient.AuthManager do
  @moduledoc """
  GenServer that manages TTLock authentication state and token lifecycle.

  Provides centralized token management with automatic refresh capabilities.
  All authentication logic is contained within this module, eliminating the
  need for module-specific authentication handling.
  """

  use GenServer
  require Logger
  import TTlockClient.Types

  alias TTlockClient.OAuthClient

  # Client API

  @doc """
  Starts the AuthManager GenServer.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Configures the client credentials for OAuth authentication.

  ## Parameters
    * `client_id` - Application client ID from TTLock developer portal
    * `client_secret` - Application client secret from TTLock developer portal
    * `base_url` - Optional base URL (defaults to EU API endpoint)

  ## Example
      TTlockClient.AuthManager.configure("your_client_id", "your_client_secret")
  """
  @spec configure(String.t(), String.t(), String.t()) :: :ok | {:error, term()}
  def configure(client_id, client_secret, base_url \\ "https://euapi.ttlock.com") do
    config = new_client_config(client_id, client_secret, base_url)
    GenServer.call(__MODULE__, {:configure, config})
  end

  @doc """
  Authenticates with TTLock using username and password.

  ## Parameters
    * `username` - TTLock app username (not developer account)
    * `password` - Plain text password

  ## Returns
    * `:ok` - Authentication successful
    * `{:error, reason}` - Authentication failed

  ## Example
      TTlockClient.AuthManager.authenticate("your_username", "your_password")
  """
  @spec authenticate(String.t(), String.t()) :: :ok | {:error, term()}
  def authenticate(username, password) do
    GenServer.call(__MODULE__, {:authenticate, username, password}, 30_000)
  end

  @doc """
  Gets a valid access token, refreshing if necessary.

  ## Returns
    * `{:ok, access_token}` - Valid token available
    * `{:error, :not_authenticated}` - No authentication data available
    * `{:error, reason}` - Token refresh failed

  ## Example
      case TTlockClient.AuthManager.get_valid_token() do
        {:ok, token} ->
          # Use token for API requests
        {:error, :not_authenticated} ->
          # Need to authenticate first
        {:error, reason} ->
          # Handle error
      end
  """
  @spec get_valid_token() :: {:ok, String.t()} | {:error, term()}
  def get_valid_token do
    GenServer.call(__MODULE__, :get_valid_token)
  end

  @doc """
  Gets the current user ID if authenticated.
  """
  @spec get_user_id() :: {:ok, integer()} | {:error, :not_authenticated}
  def get_user_id do
    GenServer.call(__MODULE__, :get_user_id)
  end

  @doc """
  Manually triggers a token refresh.
  """
  @spec refresh_token() :: :ok | {:error, term()}
  def refresh_token do
    GenServer.call(__MODULE__, :refresh_token)
  end

  @doc """
  Gets the current authentication status.
  """
  @spec status() :: :configured | :authenticated | :not_configured
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @doc """
  Gets the current client configuration.
  """
  @spec get_config() :: {:ok, TTlockClient.Types.client_config()} | {:error, :not_configured}
  def get_config do
    GenServer.call(__MODULE__, :get_config)
  end

  @doc """
  Clears all authentication data.
  """
  @spec reset() :: :ok
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # GenServer Callbacks

  defmodule State do
    @moduledoc false
    defstruct [
      :config,
      :token_info,
      :refresh_timer
    ]
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting TTlockClient AuthManager")
    {:ok, %State{}}
  end

  @impl true
  def handle_call({:configure, config}, _from, state) do
    Logger.info("Configuring TTlockClient client")
    new_state = %{state | config: config}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:authenticate, _username, _password}, _from, %State{config: nil} = state) do
    {:reply, {:error, :not_configured}, state}
  end

  @impl true
  def handle_call({:authenticate, username, password}, _from, %State{config: config} = state) do
    case OAuthClient.get_access_token(config, username, password) do
      {:ok, oauth_response} ->
        token_info = new_token_info(oauth_response)
        timer = schedule_refresh(token_info)

        new_state = %{state | token_info: token_info, refresh_timer: timer}

        Logger.info("Authentication successful for user: #{username}")
        {:reply, :ok, new_state}

      {:error, reason} = error ->
        Logger.error("Authentication failed for user #{username}: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call(:get_valid_token, _from, %State{token_info: nil} = state) do
    {:reply, {:error, :not_authenticated}, state}
  end

  @impl true
  def handle_call(:get_valid_token, _from, %State{token_info: token_info} = state) do
    if token_expired?(token_info) do
      # Token is expired, try to refresh
      case perform_refresh(state) do
        {:ok, new_state} ->
          token_info(access_token: access_token) = new_state.token_info
          {:reply, {:ok, access_token}, new_state}

        {:error, _reason} = error ->
          {:reply, error, state}
      end
    else
      token_info(access_token: access_token) = token_info
      {:reply, {:ok, access_token}, state}
    end
  end

  @impl true
  def handle_call(:get_user_id, _from, %State{token_info: nil} = state) do
    {:reply, {:error, :not_authenticated}, state}
  end

  @impl true
  def handle_call(:get_user_id, _from, %State{token_info: token_info} = state) do
    token_info(uid: uid) = token_info
    {:reply, {:ok, uid}, state}
  end

  @impl true
  def handle_call(:refresh_token, _from, state) do
    case perform_refresh(state) do
      {:ok, new_state} ->
        {:reply, :ok, new_state}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call(:status, _from, %State{config: nil} = state) do
    {:reply, :not_configured, state}
  end

  @impl true
  def handle_call(:status, _from, %State{token_info: nil} = state) do
    {:reply, :configured, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, :authenticated, state}
  end

  @impl true
  def handle_call(:reset, _from, %State{refresh_timer: timer} = _state) do
    if timer, do: Process.cancel_timer(timer)
    Logger.info("Resetting TTlockClient authentication state")
    {:reply, :ok, %State{}}
  end

  @impl true
  def handle_call(:get_config, _from, %State{config: config} = state) do
    case config do
      nil -> {:reply, {:error, :not_configured}, state}
      config -> {:reply, {:ok, config}, state}
    end
  end

  @impl true
  def handle_info(:refresh_token, state) do
    case perform_refresh(state) do
      {:ok, new_state} ->
        Logger.info("Automatic token refresh successful")
        {:noreply, new_state}

      {:error, reason} ->
        Logger.error("Automatic token refresh failed: #{inspect(reason)}")
        # Clear token info on refresh failure
        new_state = %{state | token_info: nil, refresh_timer: nil}
        {:noreply, new_state}
    end
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Private functions

  @spec perform_refresh(State.t()) :: {:ok, State.t()} | {:error, term()}
  defp perform_refresh(%State{config: nil}) do
    {:error, :not_configured}
  end

  defp perform_refresh(%State{token_info: nil}) do
    {:error, :not_authenticated}
  end

  defp perform_refresh(%State{config: config, token_info: token_info, refresh_timer: timer} = state) do
    token_info(refresh_token: refresh_token) = token_info

    case OAuthClient.refresh_access_token(config, refresh_token) do
      {:ok, oauth_response} ->
        if timer, do: Process.cancel_timer(timer)

        new_token_info = new_token_info(oauth_response)
        new_timer = schedule_refresh(new_token_info)

        new_state = %{state | token_info: new_token_info, refresh_timer: new_timer}
        {:ok, new_state}

      {:error, reason} = error ->
        Logger.error("Token refresh failed: #{inspect(reason)}")
        error
    end
  end

  @spec schedule_refresh(TTlockClient.Types.token_info()) :: reference()
  defp schedule_refresh(token_info(expires_at: expires_at)) do
    # Schedule refresh 5 minutes before expiry
    refresh_time = DateTime.add(expires_at, -300, :second)
    delay_ms = max(DateTime.diff(refresh_time, DateTime.utc_now(), :millisecond), 60_000)

    Logger.debug("Scheduling token refresh in #{delay_ms}ms")
    Process.send_after(self(), :refresh_token, delay_ms)
  end
end
