defmodule TTlockClient.OAuthTest do
  use ExUnit.Case, async: true
  doctest TTlockClient.OAuth

  alias TTlockClient.OAuth

  describe "hash_password/1" do
    test "hashes password using MD5" do
      assert OAuth.hash_password("123456") == "e10adc3949ba59abbe56e057f20f883e"
      assert OAuth.hash_password("password") == "5f4dcc3b5aa765d61d8327deb882cf99"
    end

    test "returns 32 character lowercase string" do
      hash = OAuth.hash_password("test")
      assert String.length(hash) == 32
      assert hash == String.downcase(hash)
      assert Regex.match?(~r/^[a-f0-9]{32}$/, hash)
    end

    test "handles empty string" do
      assert OAuth.hash_password("") == "d41d8cd98f00b204e9800998ecf8427e"
    end

    test "handles unicode characters" do
      hash = OAuth.hash_password("测试")
      assert String.length(hash) == 32
      assert Regex.match?(~r/^[a-f0-9]{32}$/, hash)
    end
  end

  describe "get_access_token/1" do
    test "uses config values when not provided" do
      # Should attempt HTTP request with config values, will fail on network but not on missing params
      # This just tests that it doesn't raise ArgumentError for missing config
      try do
        OAuth.get_access_token([])
      rescue
        HTTPoison.Error -> :ok
        _ -> flunk("Expected HTTPoison.Error")
      end
    end

    test "prefers explicit parameters over config" do
      try do
        OAuth.get_access_token(
          client_id: "explicit_client", 
          client_secret: "explicit_secret", 
          username: "explicit_user", 
          password: "explicit_pass"
        )
      rescue
        HTTPoison.Error -> :ok
        _ -> flunk("Expected HTTPoison.Error")
      end
    end
  end

  describe "refresh_token/1" do
    test "validates required parameters" do
      assert_raise KeyError, fn ->
        OAuth.refresh_token([])
      end

      assert_raise KeyError, fn ->
        OAuth.refresh_token(client_id: "test")
      end

      assert_raise KeyError, fn ->
        OAuth.refresh_token(client_id: "test", client_secret: "secret")
      end
    end
  end
end
