#!/usr/bin/env elixir

# TTlockClient Passcodes API Usage Example
#
# This example demonstrates how to use the passcode management features
# of the TTlockClient library.
#
# Usage:
#   elixir passcodes_example.exs           # Basic passcode operations
#   elixir passcodes_example.exs advanced  # Advanced passcode examples
#   elixir passcodes_example.exs delete    # Passcode deletion examples

defmodule PasscodesExample do
  @moduledoc """
  Example usage of TTlockClient passcode management features.
  """

  require Logger

  def run do
    Logger.info("Starting TTlockClient Passcodes API example")

    # First, authenticate (required for passcode API calls)
    case TTlockClient.start_with_env() do
      :ok ->
        Logger.info("✓ Authentication successful")
        demonstrate_passcode_operations()

      {:error, {:missing_env_var, var_name}} ->
        Logger.error("✗ Missing environment variable: #{var_name}")
        Logger.info("Please set #{var_name} in your .env file")

      {:error, reason} ->
        Logger.error("✗ Authentication failed: #{inspect(reason)}")
        exit(:authentication_failed)
    end
  end

  defp demonstrate_passcode_operations do
    Logger.info("Demonstrating passcode operations...")

    # First, get a lock to work with
    case get_first_lock() do
      {:ok, lock_id} ->
        Logger.info("Using lock ID: #{lock_id}")

        # Demonstrate different types of passcodes
        add_permanent_passcode_example(lock_id)
        add_temporary_passcode_example(lock_id)
        add_custom_passcode_example(lock_id)

        # Demonstrate listing and searching passcodes
        list_passcodes_example(lock_id)
        search_passcodes_example(lock_id)

      {:error, reason} ->
        Logger.error("✗ Could not get a lock to work with: #{inspect(reason)}")
        Logger.info("Make sure you have at least one lock in your account")
    end
  end

  defp get_first_lock do
    case TTlockClient.get_locks(1, 1) do
      {:ok, %{list: [first_lock | _]}} ->
        {:ok, first_lock["lockId"]}

      {:ok, %{list: []}} ->
        {:error, :no_locks_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp add_permanent_passcode_example(lock_id) do
    Logger.info("Adding a permanent passcode...")

    # Generate a random 6-digit passcode
    passcode = Enum.random(100_000..999_999)

    case TTlockClient.add_permanent_passcode(lock_id, passcode, "Guest Access") do
      {:ok, %{keyboardPwdId: passcode_id}} ->
        Logger.info("✓ Permanent passcode added successfully!")
        Logger.info("  Passcode ID: #{passcode_id}")
        Logger.info("  Passcode: #{passcode}")
        Logger.info("  Name: Guest Access")
        Logger.info("  Type: Permanent (never expires)")

      {:error, %{error_code: -3009}} ->
        Logger.warning("⚠️  Lock passcode storage is full (250 passcode limit)")

      {:error, reason} ->
        Logger.error("✗ Failed to add permanent passcode: #{inspect(reason)}")
    end
  end

  defp add_temporary_passcode_example(lock_id) do
    Logger.info("Adding a temporary passcode (valid for 1 week)...")

    # Generate a random 6-digit passcode
    passcode = Enum.random(100_000..999_999)

    # Set up dates for 1 week from now
    start_time = DateTime.utc_now()
    end_time = DateTime.add(start_time, 7, :day)

    case TTlockClient.add_temporary_passcode(lock_id, passcode, start_time, end_time, "Weekly Visitor") do
      {:ok, %{keyboardPwdId: passcode_id}} ->
        Logger.info("✓ Temporary passcode added successfully!")
        Logger.info("  Passcode ID: #{passcode_id}")
        Logger.info("  Passcode: #{passcode}")
        Logger.info("  Name: Weekly Visitor")
        Logger.info("  Valid from: #{DateTime.to_string(start_time)}")
        Logger.info("  Valid until: #{DateTime.to_string(end_time)}")

      {:error, %{error_code: -3009}} ->
        Logger.warning("⚠️  Lock passcode storage is full (250 passcode limit)")

      {:error, reason} ->
        Logger.error("✗ Failed to add temporary passcode: #{inspect(reason)}")
    end
  end

  defp add_custom_passcode_example(lock_id) do
    Logger.info("Adding a custom passcode with specific parameters...")

    # Generate a random 4-digit passcode
    passcode = Enum.random(1000..9999)

    # Set up for a passcode valid for 24 hours starting in 1 hour
    start_time = DateTime.add(DateTime.utc_now(), 1, :hour)
    end_time = DateTime.add(start_time, 24, :hour)

    start_ms = DateTime.to_unix(start_time, :millisecond)
    end_ms = DateTime.to_unix(end_time, :millisecond)

    # Add via gateway (addType 2) as a period passcode (type 3)
    case TTlockClient.add_passcode(lock_id, passcode, "24h Delivery", 3, start_ms, end_ms, 2) do
      {:ok, %{keyboardPwdId: passcode_id}} ->
        Logger.info("✓ Custom passcode added successfully!")
        Logger.info("  Passcode ID: #{passcode_id}")
        Logger.info("  Passcode: #{passcode}")
        Logger.info("  Name: 24h Delivery")
        Logger.info("  Activation: #{DateTime.to_string(start_time)}")
        Logger.info("  Expiration: #{DateTime.to_string(end_time)}")
        Logger.info("  Add method: Gateway/WiFi")

      {:error, %{error_code: -3009}} ->
        Logger.warning("⚠️  Lock passcode storage is full (250 passcode limit)")

      {:error, reason} ->
        Logger.error("✗ Failed to add custom passcode: #{inspect(reason)}")
    end
  end

  defp list_passcodes_example(lock_id) do
    Logger.info("Listing all passcodes for the lock...")

    case TTlockClient.get_lock_passcodes(lock_id) do
      {:ok, %{list: passcodes, total: total}} ->
        Logger.info("✓ Found #{total} passcodes for this lock")

        if total > 0 do
          Logger.info("Passcode details:")

          Enum.each(passcodes, fn passcode ->
            name = passcode["keyboardPwdName"] || "Unnamed"
            pwd = passcode["keyboardPwd"]
            type_str = case passcode["keyboardPwdType"] do
              "2" -> "Permanent"
              "3" -> "Temporary"
              _ -> "Unknown"
            end
            is_custom = if passcode["isCustom"] == 1, do: "Custom", else: "Random"

            Logger.info("  - #{name} (#{pwd})")
            Logger.info("    Type: #{type_str}, Method: #{is_custom}")
            Logger.info("    ID: #{passcode["keyboardPwdId"]}")

            if passcode["keyboardPwdType"] == "3" do
              start_date = DateTime.from_unix!(passcode["startDate"], :millisecond)
              end_date = DateTime.from_unix!(passcode["endDate"], :millisecond)
              Logger.info("    Valid: #{DateTime.to_string(start_date)} to #{DateTime.to_string(end_date)}")
            end
          end)
        else
          Logger.info("No passcodes found for this lock")
        end

      {:error, reason} ->
        Logger.error("✗ Failed to list passcodes: #{inspect(reason)}")
    end
  end

  defp search_passcodes_example(lock_id) do
    Logger.info("Searching for passcodes containing 'Guest'...")

    case TTlockClient.search_passcodes(lock_id, "Guest") do
      {:ok, %{list: results, total: total}} ->
        Logger.info("✓ Found #{total} passcode(s) matching 'Guest'")

        Enum.each(results, fn passcode ->
          name = passcode["keyboardPwdName"]
          pwd = passcode["keyboardPwd"]
          Logger.info("  - #{name}: #{pwd}")
        end)

      {:error, reason} ->
        Logger.error("✗ Failed to search passcodes: #{inspect(reason)}")
    end
  end
end

defmodule PasscodeDeletionExample do
  @moduledoc """
  Example showing passcode deletion operations.
  """

  require Logger

  def run do
    Logger.info("Starting TTlockClient Passcode Deletion example")

    case TTlockClient.start_with_env() do
      :ok ->
        Logger.info("✓ Authentication successful")
        demonstrate_deletion_operations()

      {:error, {:missing_env_var, var_name}} ->
        Logger.error("✗ Missing environment variable: #{var_name}")
        Logger.info("Please set #{var_name} in your .env file")

      {:error, reason} ->
        Logger.error("✗ Authentication failed: #{inspect(reason)}")
        exit(:authentication_failed)
    end
  end

  defp demonstrate_deletion_operations do
    Logger.info("Demonstrating passcode deletion operations...")

    case get_first_lock() do
      {:ok, lock_id} ->
        Logger.info("Using lock ID: #{lock_id}")

        # First, add some test passcodes to delete
        test_passcode_ids = add_test_passcodes(lock_id)

        if length(test_passcode_ids) > 0 do
          # Demonstrate different deletion methods
          demonstrate_gateway_deletion(lock_id, test_passcode_ids)
          demonstrate_using_types_module(lock_id, test_passcode_ids)
          list_remaining_passcodes(lock_id)
        else
          Logger.info("No test passcodes were created, skipping deletion examples")
        end

      {:error, reason} ->
        Logger.error("✗ Could not get a lock to work with: #{inspect(reason)}")
        Logger.info("Make sure you have at least one lock in your account")
    end
  end

  defp get_first_lock do
    case TTlockClient.get_locks(1, 1) do
      {:ok, %{list: [first_lock | _]}} ->
        {:ok, first_lock["lockId"]}

      {:ok, %{list: []}} ->
        {:error, :no_locks_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp add_test_passcodes(lock_id) do
    Logger.info("Adding test passcodes for deletion examples...")

    test_passcodes = [
      {111111, "Test Delete 1"},
      {222222, "Test Delete 2"},
      {333333, "Test Delete 3"}
    ]

    Enum.reduce(test_passcodes, [], fn {passcode, name}, acc ->
      case TTlockClient.add_permanent_passcode(lock_id, passcode, name) do
        {:ok, %{keyboardPwdId: passcode_id}} ->
          Logger.info("✓ Added test passcode: #{name} (ID: #{passcode_id})")
          [passcode_id | acc]

        {:error, reason} ->
          Logger.warning("⚠️  Failed to add test passcode #{name}: #{inspect(reason)}")
          acc
      end
    end)
    |> Enum.reverse()
  end

  defp demonstrate_gateway_deletion(lock_id, [first_passcode_id | rest]) do
    Logger.info("Demonstrating passcode deletion via gateway...")

    case TTlockClient.delete_passcode_via_gateway(lock_id, first_passcode_id) do
      {:ok, %{errcode: 0, errmsg: message}} ->
        Logger.info("✓ Successfully deleted passcode via gateway!")
        Logger.info("  Passcode ID: #{first_passcode_id}")
        Logger.info("  Method: Gateway/WiFi")
        Logger.info("  Response: #{message}")

      {:ok, %{errcode: error_code, errmsg: error_message}} ->
        Logger.error("✗ Gateway deletion failed with error #{error_code}: #{error_message}")

      {:error, reason} ->
        Logger.error("✗ Failed to delete passcode via gateway: #{inspect(reason)}")
    end

    rest
  end

  defp demonstrate_gateway_deletion(_lock_id, []) do
    Logger.info("No passcode IDs available for gateway deletion example")
    []
  end

  defp demonstrate_using_types_module(lock_id, [second_passcode_id | rest]) do
    Logger.info("Using Types module for advanced deletion control...")

    # Create delete parameters using the Types module
    delete_params = TTlockClient.Types.new_passcode_delete_params(
      lock_id,
      second_passcode_id
    )

    Logger.info("Created delete parameters:")
    Logger.info("  Lock ID: #{TTlockClient.Types.passcode_delete_params(delete_params, :lock_id)}")
    Logger.info("  Passcode ID: #{TTlockClient.Types.passcode_delete_params(delete_params, :keyboard_pwd_id)}")

    case TTlockClient.Passcodes.delete_passcode(delete_params) do
      {:ok, %{errcode: 0, errmsg: message}} ->
        Logger.info("✓ Successfully deleted passcode using Types module!")
        Logger.info("  Response: #{message}")

      {:ok, %{errcode: error_code, errmsg: error_message}} ->
        Logger.error("✗ Types module deletion failed with error #{error_code}: #{error_message}")

      {:error, reason} ->
        Logger.error("✗ Failed to delete passcode using Types module: #{inspect(reason)}")
    end

    rest
  end

  defp demonstrate_using_types_module(_lock_id, []) do
    Logger.info("No passcode IDs available for Types module deletion example")
    []
  end

  defp list_remaining_passcodes(lock_id) do
    Logger.info("Listing remaining test passcodes...")

    case TTlockClient.search_passcodes(lock_id, "Test Delete") do
      {:ok, %{list: results, total: total}} ->
        Logger.info("✓ Found #{total} remaining test passcode(s)")

        if total > 0 do
          Logger.info("Remaining test passcodes:")
          Enum.each(results, fn passcode ->
            name = passcode["keyboardPwdName"]
            pwd = passcode["keyboardPwd"]
            id = passcode["keyboardPwdId"]
            Logger.info("  - #{name} (#{pwd}) - ID: #{id}")
          end)

          Logger.info("")
          Logger.info("You can delete these manually using:")
          Enum.each(results, fn passcode ->
            id = passcode["keyboardPwdId"]
            Logger.info("  TTlockClient.delete_passcode(#{lock_id}, #{id})")
          end)
        else
          Logger.info("All test passcodes have been deleted successfully!")
        end

      {:error, reason} ->
        Logger.error("✗ Failed to search for remaining test passcodes: #{inspect(reason)}")
    end
  end
end

defmodule AdvancedPasscodesExample do
  @moduledoc """
  Advanced example showing passcode management patterns and best practices.
  """

  require Logger

  def run do
    Logger.info("Starting advanced passcodes example")

    case TTlockClient.start_with_env() do
      :ok ->
        demonstrate_advanced_patterns()

      {:error, reason} ->
        Logger.error("Authentication failed: #{inspect(reason)}")
        exit(:authentication_failed)
    end
  end

  defp demonstrate_advanced_patterns do
    case get_lock_for_demo() do
      {:ok, lock_id} ->
        Logger.info("Using lock ID: #{lock_id} for advanced examples")

        show_passcode_types()
        show_add_types()
        show_order_by_options()
        demonstrate_validation()
        demonstrate_using_types_module(lock_id)
        demonstrate_advanced_listing(lock_id)

      {:error, reason} ->
        Logger.error("Could not get lock: #{inspect(reason)}")
    end
  end

  defp get_lock_for_demo do
    case TTlockClient.get_locks() do
      {:ok, %{list: [first_lock | _]}} ->
        {:ok, first_lock["lockId"]}
      _ ->
        {:error, :no_locks}
    end
  end

  defp show_passcode_types do
    Logger.info("Available passcode types:")
    types = TTlockClient.Passcodes.passcode_types()
    Logger.info("  Permanent: #{types.permanent}")
    Logger.info("  Period: #{types.period}")
  end

  defp show_add_types do
    Logger.info("Available add types:")
    types = TTlockClient.Passcodes.add_types()
    Logger.info("  Bluetooth: #{types.bluetooth} (use mobile app first, then sync)")
    Logger.info("  Gateway: #{types.gateway} (direct via gateway or WiFi lock)")
  end

  defp show_order_by_options do
    Logger.info("Available sorting options:")
    options = TTlockClient.Passcodes.order_by_options()
    Logger.info("  By name: #{options.name}")
    Logger.info("  By time (newest first): #{options.time_desc}")
    Logger.info("  By name (reverse): #{options.name_desc}")
  end

  defp demonstrate_validation do
    Logger.info("Demonstrating parameter validation...")

    # This will show validation errors
    invalid_params = TTlockClient.Types.new_passcode_add_params(
      -1,      # invalid lock_id
      123,     # too short passcode
      "Test",
      3,       # period type
      nil,     # missing start_date
      nil,     # missing end_date
      2
    )

    case TTlockClient.Passcodes.add_passcode(invalid_params) do
      {:error, {:validation_error, message}} ->
        Logger.info("✓ Add validation caught error: #{message}")
      other ->
        Logger.info("Unexpected add result: #{inspect(other)}")
    end

    # Test delete validation
    invalid_delete_params = TTlockClient.Types.new_passcode_delete_params(
      -1,  # invalid lock_id
      -1   # invalid passcode_id
    )

    case TTlockClient.Passcodes.delete_passcode(invalid_delete_params) do
      {:error, {:validation_error, message}} ->
        Logger.info("✓ Delete validation caught error: #{message}")
      other ->
        Logger.info("Unexpected delete result: #{inspect(other)}")
    end
  end

  defp demonstrate_using_types_module(lock_id) do
    Logger.info("Using Types module for advanced parameter control...")

    # Create parameters using the Types module
    start_time = DateTime.add(DateTime.utc_now(), 2, :hour)
    end_time = DateTime.add(start_time, 6, :hour)

    params = TTlockClient.Types.new_passcode_add_params(
      lock_id,
      555666,  # passcode
      "Service Window",  # name
      3,  # period type
      DateTime.to_unix(start_time, :millisecond),
      DateTime.to_unix(end_time, :millisecond),
      2   # gateway type
    )

    Logger.info("Created add parameters:")
    Logger.info("  Lock ID: #{TTlockClient.Types.passcode_add_params(params, :lock_id)}")
    Logger.info("  Passcode: #{TTlockClient.Types.passcode_add_params(params, :keyboard_pwd)}")
    Logger.info("  Name: #{TTlockClient.Types.passcode_add_params(params, :keyboard_pwd_name)}")
    Logger.info("  Type: #{TTlockClient.Types.passcode_add_params(params, :keyboard_pwd_type)}")
    Logger.info("  Add Type: #{TTlockClient.Types.passcode_add_params(params, :add_type)}")

    case TTlockClient.Passcodes.add_passcode(params) do
      {:ok, result} ->
        Logger.info("✓ Advanced passcode added: #{inspect(result)}")
      {:error, reason} ->
        Logger.info("Could not add passcode (expected): #{inspect(reason)}")
    end
  end

  defp demonstrate_advanced_listing(lock_id) do
    Logger.info("Demonstrating advanced passcode listing...")

    # Using the Types module for advanced parameter control
    params = TTlockClient.Types.new_passcode_list_params(
      lock_id,
      nil,  # no search filter
      1,    # first page
      10,   # 10 items per page
      1     # sort by time descending
    )

    case TTlockClient.Passcodes.get_passcode_list(params) do
      {:ok, %{list: passcodes, total: total, pages: pages}} ->
        Logger.info("✓ Advanced listing successful:")
        Logger.info("  Total passcodes: #{total}")
        Logger.info("  Total pages: #{pages}")
        Logger.info("  Passcodes on this page: #{length(passcodes)}")

        # Show pagination example
        if pages > 1 do
          Logger.info("Getting page 2...")
          page2_params = TTlockClient.Types.new_passcode_list_params(lock_id, nil, 2, 10, 1)

          case TTlockClient.Passcodes.get_passcode_list(page2_params) do
            {:ok, %{list: page2_passcodes}} ->
              Logger.info("✓ Page 2 retrieved: #{length(page2_passcodes)} passcodes")
            {:error, reason} ->
              Logger.info("Page 2 error: #{inspect(reason)}")
          end
        end

      {:error, reason} ->
        Logger.info("Advanced listing error: #{inspect(reason)}")
    end
  end
end

# Helper functions for time management
defmodule PasscodeTimeHelpers do
  @moduledoc """
  Utility functions for working with passcode time periods.
  """

  @doc """
  Creates a passcode valid for a specific number of hours from now.
  """
  def hours_from_now(lock_id, passcode, hours, name \\ nil) do
    start_time = DateTime.utc_now()
    end_time = DateTime.add(start_time, hours, :hour)

    TTlockClient.add_temporary_passcode(lock_id, passcode, start_time, end_time, name)
  end

  @doc """
  Creates a passcode valid for business hours today.
  """
  def business_hours_today(lock_id, passcode, name \\ nil) do
    now = DateTime.utc_now()

    # 9 AM today
    start_time = %{now | hour: 9, minute: 0, second: 0, microsecond: {0, 0}}

    # 5 PM today
    end_time = %{now | hour: 17, minute: 0, second: 0, microsecond: {0, 0}}

    TTlockClient.add_temporary_passcode(lock_id, passcode, start_time, end_time, name)
  end

  @doc """
  Creates a passcode valid for a weekend (Saturday and Sunday).
  """
  def weekend_passcode(lock_id, passcode, name \\ nil) do
    now = DateTime.utc_now()

    # Find next Saturday
    days_until_saturday = rem(7 - Date.day_of_week(DateTime.to_date(now)), 7)
    saturday = DateTime.add(now, days_until_saturday, :day)

    # Saturday at midnight
    start_time = %{saturday | hour: 0, minute: 0, second: 0, microsecond: {0, 0}}

    # Monday at midnight (end of Sunday)
    end_time = DateTime.add(start_time, 2, :day)

    TTlockClient.add_temporary_passcode(lock_id, passcode, start_time, end_time, name)
  end
end

# Run the appropriate example based on command line arguments
case System.argv() do
  ["advanced"] ->
    AdvancedPasscodesExample.run()
  ["delete"] ->
    PasscodeDeletionExample.run()
  ["helpers"] ->
    # Example using helper functions
    IO.puts("Time helper examples:")
    IO.puts("PasscodeTimeHelpers.hours_from_now(12345, 123456, 24, \"24h Access\")")
    IO.puts("PasscodeTimeHelpers.business_hours_today(12345, 987654, \"Office Access\")")
    IO.puts("PasscodeTimeHelpers.weekend_passcode(12345, 555888, \"Weekend Guest\")")
  _ ->
    PasscodesExample.run()
end
