defmodule TTlockClientTest do
  use ExUnit.Case, async: false
  doctest TTlockClient

  import TTlockClient.Types

  setup do
    # Reset state before each test
    TTlockClient.reset()
    :ok
  end

  test "can configure client credentials" do
    assert :ok = TTlockClient.configure("test_client_id", "test_client_secret")
    assert TTlockClient.status() == :configured
  end

  test "can configure with custom base URL" do
    assert :ok =
             TTlockClient.configure(
               "test_client_id",
               "test_client_secret",
               "https://custom.api.com"
             )

    assert TTlockClient.status() == :configured
  end

  test "starts in not_configured state" do
    assert TTlockClient.status() == :not_configured
  end

  test "moves to configured state after configuration" do
    TTlockClient.configure("client_id", "client_secret")
    assert TTlockClient.status() == :configured
  end

  test "ready? returns false when not authenticated" do
    refute TTlockClient.ready?()

    TTlockClient.configure("client_id", "client_secret")
    refute TTlockClient.ready?()
  end

  test "get_valid_token returns error when not configured" do
    assert {:error, :not_authenticated} = TTlockClient.get_valid_token()
  end

  test "get_valid_token returns error when configured but not authenticated" do
    TTlockClient.configure("client_id", "client_secret")
    assert {:error, :not_authenticated} = TTlockClient.get_valid_token()
  end

  test "get_user_id returns error when not authenticated" do
    assert {:error, :not_authenticated} = TTlockClient.get_user_id()
  end

  test "reset clears all state" do
    TTlockClient.configure("client_id", "client_secret")
    assert TTlockClient.status() == :configured

    TTlockClient.reset()
    assert TTlockClient.status() == :not_configured
  end

  test "get_locks returns error when not authenticated" do
    assert {:error, :not_authenticated} = TTlockClient.get_locks()
  end

  test "get_lock returns error when not authenticated" do
    assert {:error, :not_authenticated} = TTlockClient.get_lock(12345)
  end

  test "get_all_locks returns error when not authenticated" do
    assert {:error, :not_authenticated} = TTlockClient.get_all_locks()
  end

  test "add_permanent_passcode returns error when not authenticated" do
    assert {:error, :not_authenticated} =
             TTlockClient.add_permanent_passcode(12345, 123_456, "Guest")
  end

  test "add_temporary_passcode returns error when not authenticated" do
    start_time = DateTime.utc_now()
    end_time = DateTime.add(start_time, 7, :day)

    assert {:error, :not_authenticated} =
             TTlockClient.add_temporary_passcode(12345, 987_654, start_time, end_time, "Visitor")
  end

  test "add_passcode returns error when not authenticated" do
    assert {:error, :not_authenticated} =
             TTlockClient.add_passcode(12345, 123_456, "Guest", 2, nil, nil, 2)
  end

  test "delete_passcode returns error when not authenticated" do
    assert {:error, :not_authenticated} = TTlockClient.delete_passcode(12345, 67890)
  end

  test "delete_passcode_via_gateway returns error when not authenticated" do
    assert {:error, :not_authenticated} = TTlockClient.delete_passcode_via_gateway(12345, 67890)
  end
end

defmodule TTlockClient.TypesTest do
  use ExUnit.Case
  doctest TTlockClient.Types

  import TTlockClient.Types

  test "creates client config with defaults" do
    config = new_client_config("client_id", "client_secret")

    assert client_config(config, :client_id) == "client_id"
    assert client_config(config, :client_secret) == "client_secret"
    assert client_config(config, :base_url) == "https://euapi.ttlock.com"
  end

  test "creates client config with custom base URL" do
    config = new_client_config("client_id", "client_secret", "https://custom.api.com")

    assert client_config(config, :base_url) == "https://custom.api.com"
  end

  test "creates token info from OAuth response" do
    oauth_response = %{
      access_token: "token123",
      refresh_token: "refresh123",
      expires_in: 7_776_000,
      uid: 1234
    }

    token_info = new_token_info(oauth_response)

    assert token_info(token_info, :access_token) == "token123"
    assert token_info(token_info, :refresh_token) == "refresh123"
    assert token_info(token_info, :uid) == 1234
    assert is_struct(token_info(token_info, :expires_at), DateTime)
  end

  test "creates credentials with MD5 hashed password" do
    credentials = new_auth_credentials("username", "password")

    assert auth_credentials(credentials, :username) == "username"
    # MD5 of "password" in lowercase hex
    assert auth_credentials(credentials, :password_hash) ==
             "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"
  end

  test "creates passcode delete params" do
    params = new_passcode_delete_params(12345, 67890)

    assert passcode_delete_params(params, :lock_id) == 12345
    assert passcode_delete_params(params, :keyboard_pwd_id) == 67890
  end

  test "token_expired? returns true for nil expires_at" do
    token_info = token_info(expires_at: nil)
    assert token_expired?(token_info)
  end

  test "token_expired? returns true for expired token" do
    # 1 hour ago
    expires_at = DateTime.add(DateTime.utc_now(), -3600, :second)
    token_info = token_info(expires_at: expires_at)
    assert token_expired?(token_info)
  end

  test "token_expired? returns true for token expiring within buffer" do
    # 1 minute from now
    expires_at = DateTime.add(DateTime.utc_now(), 60, :second)
    token_info = token_info(expires_at: expires_at)
    # 5 minute buffer
    assert token_expired?(token_info, 300)
  end

  test "token_expired? returns false for valid token" do
    # 1 hour from now
    expires_at = DateTime.add(DateTime.utc_now(), 3600, :second)
    token_info = token_info(expires_at: expires_at)
    refute token_expired?(token_info)
  end

  test "valid_token_info? returns true for valid token info" do
    token_info = token_info(access_token: "token", refresh_token: "refresh")
    assert valid_token_info?(token_info)
  end

  test "valid_token_info? returns false for missing access token" do
    token_info = token_info(access_token: nil, refresh_token: "refresh")
    refute valid_token_info?(token_info)
  end

  test "valid_token_info? returns false for missing refresh token" do
    token_info = token_info(access_token: "token", refresh_token: nil)
    refute valid_token_info?(token_info)
  end
end

defmodule TTlockClient.LocksTest do
  use ExUnit.Case
  alias TTlockClient.Locks
  import TTlockClient.Types

  setup do
    # Reset state before each test
    TTlockClient.reset()
    :ok
  end

  test "get_lock_list returns error when not authenticated" do
    params = new_lock_list_params()
    assert {:error, :not_authenticated} = Locks.get_lock_list(params)
  end

  test "get_lock_detail returns error when not authenticated" do
    params = new_lock_detail_params(12345)
    assert {:error, :not_authenticated} = Locks.get_lock_detail(params)
  end

  test "get_lock returns error when not authenticated" do
    assert {:error, :not_authenticated} = Locks.get_lock(12345)
  end

  test "get_all_locks returns error when not authenticated" do
    assert {:error, :not_authenticated} = Locks.get_all_locks()
  end
end

defmodule TTlockClient.PasscodesTest do
  use ExUnit.Case
  alias TTlockClient.Passcodes
  import TTlockClient.Types

  setup do
    # Reset state before each test
    TTlockClient.reset()
    :ok
  end

  test "add_passcode returns error when not authenticated" do
    params = new_passcode_add_params(12345, 123_456, "Guest", 2, nil, nil, 2)
    assert {:error, :not_authenticated} = Passcodes.add_passcode(params)
  end

  test "validates passcode parameters - invalid lock_id" do
    params = new_passcode_add_params(-1, 123_456, "Guest", 2, nil, nil, 2)
    assert {:error, {:validation_error, _}} = Passcodes.add_passcode(params)
  end

  test "validates passcode parameters - passcode too short" do
    params = new_passcode_add_params(12345, 123, "Guest", 2, nil, nil, 2)
    assert {:error, {:validation_error, _}} = Passcodes.add_passcode(params)
  end

  test "validates passcode parameters - passcode too long" do
    params = new_passcode_add_params(12345, 1_234_567_890, "Guest", 2, nil, nil, 2)
    assert {:error, {:validation_error, _}} = Passcodes.add_passcode(params)
  end

  test "validates passcode parameters - period type without dates" do
    params = new_passcode_add_params(12345, 123_456, "Guest", 3, nil, nil, 2)
    assert {:error, {:validation_error, _}} = Passcodes.add_passcode(params)
  end

  test "validates passcode parameters - start date after end date" do
    params = new_passcode_add_params(12345, 123_456, "Guest", 3, 2000, 1000, 2)
    assert {:error, {:validation_error, _}} = Passcodes.add_passcode(params)
  end

  test "delete_passcode returns error when not authenticated" do
    params = new_passcode_delete_params(12345, 67890)
    assert {:error, :not_authenticated} = Passcodes.delete_passcode(params)
  end

  test "validates delete passcode parameters - invalid lock_id" do
    params = new_passcode_delete_params(-1, 67890)
    assert {:error, {:validation_error, _}} = Passcodes.delete_passcode(params)
  end

  test "validates delete passcode parameters - invalid passcode_id" do
    params = new_passcode_delete_params(12345, -1)
    assert {:error, {:validation_error, _}} = Passcodes.delete_passcode(params)
  end

  test "add_permanent_passcode returns error when not authenticated" do
    assert {:error, :not_authenticated} =
             Passcodes.add_permanent_passcode(12345, 123_456, "Guest")
  end

  test "add_temporary_passcode returns error when not authenticated" do
    start_time = DateTime.utc_now()
    end_time = DateTime.add(start_time, 7, :day)

    assert {:error, :not_authenticated} =
             Passcodes.add_temporary_passcode(12345, 987_654, start_time, end_time, "Visitor")
  end

  test "delete_passcode_via_gateway returns error when not authenticated" do
    assert {:error, :not_authenticated} = Passcodes.delete_passcode_via_gateway(12345, 67890)
  end

  test "passcode_types returns correct type constants" do
    types = Passcodes.passcode_types()
    assert types.permanent == 2
    assert types.period == 3
  end

  test "add_types returns correct add type constants" do
    types = Passcodes.add_types()
    assert types.bluetooth == 1
    assert types.gateway == 2
  end
end
