defmodule TTlockClientTest do
  use ExUnit.Case, async: false
  doctest TTlockClient

  import TTlockClient.Types

  setup do
    # Reset state before each test
    TTlockClient.reset()
    :ok
  end

  describe "configuration" do
    test "can configure client credentials" do
      assert :ok = TTlockClient.configure("test_client_id", "test_client_secret")
      assert TTlockClient.status() == :configured
    end

    test "can configure with custom base URL" do
      assert :ok = TTlockClient.configure("test_client_id", "test_client_secret", "https://custom.api.com")
      assert TTlockClient.status() == :configured
    end
  end

  describe "authentication status" do
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
  end

  describe "get_valid_token/0" do
    test "returns error when not configured" do
      assert {:error, :not_authenticated} = TTlockClient.get_valid_token()
    end

    test "returns error when configured but not authenticated" do
      TTlockClient.configure("client_id", "client_secret")
      assert {:error, :not_authenticated} = TTlockClient.get_valid_token()
    end
  end

  describe "get_user_id/0" do
    test "returns error when not authenticated" do
      assert {:error, :not_authenticated} = TTlockClient.get_user_id()
    end
  end

  describe "reset/0" do
    test "clears all state" do
      TTlockClient.configure("client_id", "client_secret")
      assert TTlockClient.status() == :configured

      TTlockClient.reset()
      assert TTlockClient.status() == :not_configured
    end
  describe "get_locks/0" do
    test "returns error when not authenticated" do
      assert {:error, :not_authenticated} = TTlockClient.get_locks()
    end
  end

  describe "get_lock/1" do
    test "returns error when not authenticated" do
      assert {:error, :not_authenticated} = TTlockClient.get_lock(12345)
    end
  end

  describe "get_all_locks/0" do
    test "returns error when not authenticated" do
      assert {:error, :not_authenticated} = TTlockClient.get_all_locks()
    end
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

  describe "get_lock_list/1" do
    test "returns error when not authenticated" do
      params = new_lock_list_params()
      assert {:error, :not_authenticated} = Locks.get_lock_list(params)
    end
  end

  describe "get_lock_detail/1" do
    test "returns error when not authenticated" do
      params = new_lock_detail_params(12345)
      assert {:error, :not_authenticated} = Locks.get_lock_detail(params)
    end
  end

  describe "get_lock/1" do
    test "returns error when not authenticated" do
      assert {:error, :not_authenticated} = Locks.get_lock(12345)
    end
  end

  describe "get_all_locks/3" do
    test "returns error when not authenticated" do
      assert {:error, :not_authenticated} = Locks.get_all_locks()
    end
  end
end

defmodule TTlockClient.TypesTest do
  use ExUnit.Case
  doctest TTlockClient.Types

  import TTlockClient.Types

  describe "client_config record" do
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
  end

  describe "token_info record" do
    test "creates token info from OAuth response" do
      oauth_response = %{
        access_token: "token123",
        refresh_token: "refresh123",
        expires_in: 7776000,
        uid: 1234
      }

      token_info = new_token_info(oauth_response)

      assert token_info(token_info, :access_token) == "token123"
      assert token_info(token_info, :refresh_token) == "refresh123"
      assert token_info(token_info, :uid) == 1234
      assert is_struct(token_info(token_info, :expires_at), DateTime)
    end
  end

  describe "auth_credentials record" do
    test "creates credentials with MD5 hashed password" do
      credentials = new_auth_credentials("username", "password")

      assert auth_credentials(credentials, :username) == "username"
      # MD5 of "password" in lowercase hex
      assert auth_credentials(credentials, :password_hash) == "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"
    end
  end

  describe "token_expired?/2" do
    test "returns true for nil expires_at" do
      token_info = token_info(expires_at: nil)
      assert token_expired?(token_info)
    end

    test "returns true for expired token" do
      expires_at = DateTime.add(DateTime.utc_now(), -3600, :second)  # 1 hour ago
      token_info = token_info(expires_at: expires_at)
      assert token_expired?(token_info)
    end

    test "returns true for token expiring within buffer" do
      expires_at = DateTime.add(DateTime.utc_now(), 60, :second)  # 1 minute from now
      token_info = token_info(expires_at: expires_at)
      assert token_expired?(token_info, 300)  # 5 minute buffer
    end

    test "returns false for valid token" do
      expires_at = DateTime.add(DateTime.utc_now(), 3600, :second)  # 1 hour from now
      token_info = token_info(expires_at: expires_at)
      refute token_expired?(token_info)
    end
  end

  describe "valid_token_info?/1" do
    test "returns true for valid token info" do
      token_info = token_info(access_token: "token", refresh_token: "refresh")
      assert valid_token_info?(token_info)
    end

    test "returns false for missing access token" do
      token_info = token_info(access_token: nil, refresh_token: "refresh")
      refute valid_token_info?(token_info)
    end

    test "returns false for missing refresh token" do
      token_info = token_info(access_token: "token", refresh_token: nil)
      refute valid_token_info?(token_info)
    end
  end
end

defmodule TTlockClient.OAuthClientTest do
  use ExUnit.Case
  alias TTlockClient.OAuthClient
  import TTlockClient.Types

  setup do
    bypass = Bypass.open()
    config = new_client_config("test_client", "test_secret", "http://localhost:#{bypass.port}")
    {:ok, bypass: bypass, config: config}
  end

  describe "get_access_token/3" do
    test "makes correct request and parses successful response", %{bypass: bypass, config: config} do
      Bypass.expect_once(bypass, "POST", "/oauth2/token", fn conn ->
        # Verify request format
        assert conn.method == "POST"
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/x-www-form-urlencoded"]

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)

        assert params["clientId"] == "test_client"
        assert params["clientSecret"] == "test_secret"
        assert params["username"] == "test_user"
        # Verify password is MD5 hashed
        assert params["password"] == "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"

        response = %{
          "access_token" => "test_access_token",
          "refresh_token" => "test_refresh_token",
          "expires_in" => 7776000,
          "uid" => 1234
        }

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(response))
      end)

      assert {:ok, oauth_response} = OAuthClient.get_access_token(config, "test_user", "password")

      assert oauth_response.access_token == "test_access_token"
      assert oauth_response.refresh_token == "test_refresh_token"
      assert oauth_response.expires_in == 7776000
      assert oauth_response.uid == 1234
    end

    test "handles error response", %{bypass: bypass, config: config} do
      Bypass.expect_once(bypass, "POST", "/oauth2/token", fn conn ->
        error_response = %{
          "errcode" => 10001,
          "errmsg" => "Invalid credentials"
        }

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(400, Jason.encode!(error_response))
      end)

      assert {:error, error} = OAuthClient.get_access_token(config, "test_user", "wrong_password")
      assert error.error_code == 10001
      assert error.description == "Invalid credentials"
    end
  end

  describe "refresh_access_token/2" do
    test "makes correct refresh request", %{bypass: bypass, config: config} do
      Bypass.expect_once(bypass, "POST", "/oauth2/token", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)

        assert params["clientId"] == "test_client"
        assert params["clientSecret"] == "test_secret"
        assert params["grant_type"] == "refresh_token"
        assert params["refresh_token"] == "test_refresh_token"

        response = %{
          "access_token" => "new_access_token",
          "refresh_token" => "new_refresh_token",
          "expires_in" => 7776000
        }

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(response))
      end)

      assert {:ok, oauth_response} = OAuthClient.refresh_access_token(config, "test_refresh_token")
      assert oauth_response.access_token == "new_access_token"
    end
  end
end
end
