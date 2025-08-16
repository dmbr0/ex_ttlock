#!/usr/bin/env elixir

# TTlockClient Client Library Usage Example
#
# This example demonstrates how to use the TTlockClient client library
# to authenticate and make API calls.

defmodule TTlockClientExample do
  @moduledoc """
  Example usage of TTlockClient client library.
  """

  require Logger

  def run do
    Logger.info("Starting TTlockClient client example")

    # Step 1: Configure client credentials
    # Get these from your TTLock developer portal
    client_id = System.get_env("TTLOCK_CLIENT_ID") || "your_client_id_here"
    client_secret = System.get_env("TTLOCK_CLIENT_SECRET") || "your_client_secret_here"

    case TTlockClient.configure(client_id, client_secret) do
      :ok ->
        Logger.info("✓ Client configured successfully")

      {:error, reason} ->
        Logger.error("✗ Configuration failed: #{inspect(reason)}")
        exit(:configuration_failed)
    end

    # Step 2: Authenticate with TTLock app credentials
    # Use your TTLock mobile app username and password (NOT developer portal credentials)
    username = System.get_env("TTLOCK_USERNAME") || "+8618966498228"
    password = System.get_env("TTLOCK_PASSWORD") || "your_app_password"

    case TTlockClient.authenticate(username, password) do
      :ok ->
        Logger.info("✓ Authentication successful")

      {:error, %{error_code: error_code, description: description}} ->
        Logger.error("✗ TTLock API error #{error_code}: #{description}")
        exit(:authentication_failed)

      {:error, reason} ->
        Logger.error("✗ Authentication failed: #{inspect(reason)}")
        exit(:authentication_failed)
    end

    # Step 3: Check authentication status
    case TTlockClient.status() do
      :authenticated ->
        Logger.info("✓ Client is authenticated and ready")

      status ->
        Logger.warning("Client status: #{status}")
    end

    # Step 4: Get user information
    case TTlockClient.get_user_id() do
      {:ok, user_id} ->
        Logger.info("✓ User ID: #{user_id}")

      {:error, reason} ->
        Logger.error("✗ Failed to get user ID: #{inspect(reason)}")
    end

    # Step 5: Get valid token for API calls
    case TTlockClient.get_valid_token() do
      {:ok, token} ->
        Logger.info("✓ Got valid access token: #{String.slice(token, 0, 8)}...")
        demonstrate_api_usage(token)

      {:error, reason} ->
        Logger.error("✗ Failed to get token: #{inspect(reason)}")
        exit(:token_failed)
    end

    # Step 6: Demonstrate token refresh
    Logger.info("Demonstrating manual token refresh...")

    case TTlockClient.refresh_token() do
      :ok ->
        Logger.info("✓ Token refreshed successfully")

      {:error, reason} ->
        Logger.error("✗ Token refresh failed: #{inspect(reason)}")
    end

    Logger.info("Example completed successfully!")
  end

  defp demonstrate_api_usage(token) do
    Logger.info("Demonstrating API usage with token...")

    # Example: Make a request to TTLock API
    # This is where you'd make actual API calls to TTLock endpoints

    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    Logger.info("Headers prepared for API calls:")
    Enum.each(headers, fn {key, value} ->
      display_value = if key == "Authorization", do: "Bearer #{String.slice(token, 0, 8)}...", else: value
      Logger.info("  #{key}: #{display_value}")
    end)

    # Example API endpoints you might call:
    # - GET /v3/lock/list - Get list of locks
    # - POST /v3/lock/unlock - Unlock a lock
    # - GET /v3/key/list - Get list of keys
    # etc.

    Logger.info("Ready to make TTLock API calls!")
  end
end

# Usage examples:

# 1. Set environment variables and run:
#    export TTLOCK_CLIENT_ID="your_client_id"
#    export TTLOCK_CLIENT_SECRET="your_client_secret"
#    export TTLOCK_USERNAME="your_username"
#    export TTLOCK_PASSWORD="your_password"
#    elixir example.exs

# 2. Or run with inline configuration:
#    TTLOCK_CLIENT_ID=abc TTLOCK_CLIENT_SECRET=def elixir example.exs

defmodule TTlockClientLiveExample do
  @moduledoc """
  Interactive example that demonstrates real-time token management.
  """

  def monitor_authentication do
    # Start monitoring loop
    spawn(fn -> monitor_loop() end)

    # Keep the example running
    receive do
      :stop -> :ok
    end
  end

  defp monitor_loop do
    case TTlockClient.status() do
      :authenticated ->
        case TTlockClient.get_valid_token() do
          {:ok, token} ->
            IO.puts("✓ [#{timestamp()}] Valid token available: #{String.slice(token, 0, 8)}...")

          {:error, reason} ->
            IO.puts("✗ [#{timestamp()}] Token error: #{inspect(reason)}")
        end

      status ->
        IO.puts("ℹ [#{timestamp()}] Status: #{status}")
    end

    # Check every 30 seconds
    Process.sleep(30_000)
    monitor_loop()
  end

  defp timestamp do
    DateTime.utc_now() |> DateTime.to_string()
  end
end

# Run the example
if System.argv() == ["monitor"] do
  IO.puts("Starting authentication monitor...")
  IO.puts("Press Ctrl+C to stop")
  TTlockClientLiveExample.monitor_authentication()
else
  TTlockClientExample.run()
end
