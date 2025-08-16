#!/usr/bin/env elixir

# TTlockClient Locks API Usage Example
#
# This example demonstrates how to use the lock management features
# of the TTlockClient library.
#
# Usage:
#   elixir locks_example.exs           # Basic lock operations
#   elixir locks_example.exs detail    # Show detailed lock information

defmodule LocksExample do
  @moduledoc """
  Example usage of TTlockClient lock management features.
  """

  require Logger

  def run do
    Logger.info("Starting TTlockClient Locks API example")

    # First, authenticate (required for lock API calls)
    case TTlockClient.start_with_env() do
      :ok ->
        Logger.info("✓ Authentication successful")
        demonstrate_lock_operations()

      {:error, {:missing_env_var, var_name}} ->
        Logger.error("✗ Missing environment variable: #{var_name}")
        Logger.info("Please set #{var_name} in your .env file")

      {:error, reason} ->
        Logger.error("✗ Authentication failed: #{inspect(reason)}")
        exit(:authentication_failed)
    end
  end

  defp demonstrate_lock_operations do
    Logger.info("Demonstrating lock operations...")

    # 1. Get list of locks (first page)
    case TTlockClient.get_locks() do
      {:ok, %{list: locks, total: total}} ->
        Logger.info("✓ Found #{total} total locks")
        Logger.info("✓ Retrieved #{length(locks)} locks on this page")

        if length(locks) > 0 do
          show_lock_summary(locks)

          # Get details for the first lock
          first_lock = List.first(locks)
          get_lock_details(first_lock["lockId"])
        else
          Logger.info("No locks found in this account")
        end

      {:error, reason} ->
        Logger.error("✗ Failed to get locks: #{inspect(reason)}")
    end

    # 2. Demonstrate pagination
    demonstrate_pagination()

    # 3. Get all locks (if you have many)
    demonstrate_get_all_locks()
  end

  defp show_lock_summary(locks) do
    Logger.info("Lock Summary:")

    Enum.each(locks, fn lock ->
      name = lock["lockName"] || "Unknown"
      alias_name = lock["lockAlias"] || "No alias"
      battery = lock["electricQuantity"] || 0
      has_gateway = if lock["hasGateway"] == 1, do: "Yes", else: "No"

      Logger.info("  - #{name} (#{alias_name})")
      Logger.info("    ID: #{lock["lockId"]}, Battery: #{battery}%, Gateway: #{has_gateway}")
    end)
  end

  defp get_lock_details(lock_id) do
    Logger.info("Getting detailed information for lock ID: #{lock_id}")

    case TTlockClient.get_lock(lock_id) do
      {:ok, lock_detail} ->
        Logger.info("✓ Lock details retrieved successfully")
        show_lock_details(lock_detail)

      {:error, reason} ->
        Logger.error("✗ Failed to get lock details: #{inspect(reason)}")
    end
  end

  defp show_lock_details(lock_detail) do
    Logger.info("Detailed Lock Information:")
    Logger.info("  Name: #{lock_detail[:lockName]}")
    Logger.info("  Alias: #{lock_detail[:lockAlias]}")
    Logger.info("  MAC Address: #{lock_detail[:lockMac]}")
    Logger.info("  Battery Level: #{lock_detail[:electricQuantity]}%")
    Logger.info("  Model: #{lock_detail[:modelNum]}")
    Logger.info("  Hardware Version: #{lock_detail[:hardwareRevision]}")
    Logger.info("  Firmware Version: #{lock_detail[:firmwareRevision]}")

    if lock_detail[:noKeyPwd] do
      Logger.info("  Super Passcode: #{lock_detail[:noKeyPwd]}")
    end

    # Show lock settings
    auto_lock = case lock_detail[:autoLockTime] do
      -1 -> "Disabled"
      time -> "#{time} seconds"
    end
    Logger.info("  Auto-lock Time: #{auto_lock}")

    sound_setting = case lock_detail[:lockSound] do
      1 -> "On"
      2 -> "Off"
      _ -> "Unknown"
    end
    Logger.info("  Lock Sound: #{sound_setting}")
  end

  defp demonstrate_pagination do
    Logger.info("Demonstrating pagination...")

    # Get second page with custom page size
    case TTlockClient.get_locks(2, 5) do
      {:ok, %{list: locks, pageNo: page, pages: total_pages}} ->
        Logger.info("✓ Page #{page} of #{total_pages} retrieved (#{length(locks)} locks)")

      {:error, reason} ->
        Logger.error("✗ Pagination example failed: #{inspect(reason)}")
    end
  end

  defp demonstrate_get_all_locks do
    Logger.info("Getting all locks (this might take a while for accounts with many locks)...")

    case TTlockClient.get_all_locks() do
      {:ok, all_locks} ->
        Logger.info("✓ Retrieved all #{length(all_locks)} locks")

        # Show battery statistics
        if length(all_locks) > 0 do
          batteries = Enum.map(all_locks, & &1["electricQuantity"])
          avg_battery = Enum.sum(batteries) / length(batteries)
          min_battery = Enum.min(batteries)
          max_battery = Enum.max(batteries)

          Logger.info("Battery Statistics:")
          Logger.info("  Average: #{Float.round(avg_battery, 1)}%")
          Logger.info("  Minimum: #{min_battery}%")
          Logger.info("  Maximum: #{max_battery}%")

          # Show locks with low battery
          low_battery_locks = Enum.filter(all_locks, & &1["electricQuantity"] < 20)
          if length(low_battery_locks) > 0 do
            Logger.warning("⚠️  #{length(low_battery_locks)} lock(s) have low battery:")
            Enum.each(low_battery_locks, fn lock ->
              Logger.warning("  - #{lock["lockName"]}: #{lock["electricQuantity"]}%")
            end)
          end
        end

      {:error, reason} ->
        Logger.error("✗ Failed to get all locks: #{inspect(reason)}")
    end
  end
end

defmodule DetailedLocksExample do
  @moduledoc """
  Detailed example showing advanced lock operations.
  """

  require Logger

  def run do
    Logger.info("Starting detailed locks example")

    case TTlockClient.start_with_env() do
      :ok ->
        demonstrate_advanced_operations()

      {:error, reason} ->
        Logger.error("Authentication failed: #{inspect(reason)}")
        exit(:authentication_failed)
    end
  end

  defp demonstrate_advanced_operations do
    # Filter locks by alias
    Logger.info("Searching for locks with 'door' in the name...")

    case TTlockClient.get_locks(1, 50, "door") do
      {:ok, %{list: locks}} ->
        Logger.info("Found #{length(locks)} locks matching 'door'")

        Enum.each(locks, fn lock ->
          Logger.info("  - #{lock["lockAlias"]} (#{lock["lockName"]})")
        end)

      {:error, reason} ->
        Logger.error("Search failed: #{inspect(reason)}")
    end

    # Using the Types module for more control
    Logger.info("Using Types module for advanced parameter control...")

    params = TTlockClient.Types.new_lock_list_params(1, 10, nil, nil)

    case TTlockClient.Locks.get_lock_list(params) do
      {:ok, response} ->
        Logger.info("Advanced query successful - got #{length(response.list)} locks")

      {:error, reason} ->
        Logger.error("Advanced query failed: #{inspect(reason)}")
    end
  end
end

# Run the appropriate example based on command line arguments
case System.argv() do
  ["detail"] ->
    DetailedLocksExample.run()
  _ ->
    LocksExample.run()
end
