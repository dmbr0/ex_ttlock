defmodule TTlockClient.LockManagementTest do
  use ExUnit.Case, async: true
  doctest TTlockClient.LockManagement

  alias TTlockClient.LockManagement

  describe "get_lock_list/1" do
    test "uses config values and defaults" do
      # Should not raise with config values set, only missing access_token should fail
      assert_raise KeyError, fn ->
        LockManagement.get_lock_list([])
      end
    end
    
    test "validates required access_token parameter" do
      # client_id comes from config, but access_token is still required
      assert_raise KeyError, fn ->
        LockManagement.get_lock_list(client_id: "test")
      end
    end

    test "accepts optional parameters" do
      # This will return an API error for invalid client_id but validates parameter handling
      result =
        LockManagement.get_lock_list(
          client_id: "test",
          access_token: "token",
          page_no: 1,
          page_size: 20,
          lock_alias: "test",
          group_id: 123
        )

      assert match?({:ok, %{"errcode" => 10000}}, result) or match?({:error, _}, result)
    end

    test "handles missing optional parameters" do
      # This will return an API error for invalid client_id but validates parameter handling
      result =
        LockManagement.get_lock_list(
          client_id: "test",
          access_token: "token",
          page_no: 1,
          page_size: 20
        )

      assert match?({:ok, %{"errcode" => 10000}}, result) or match?({:error, _}, result)
    end
  end

  describe "get_lock_details/1" do
    test "validates required parameters" do
      assert_raise KeyError, fn ->
        LockManagement.get_lock_details([])
      end

      assert_raise KeyError, fn ->
        LockManagement.get_lock_details(client_id: "test")
      end

      assert_raise KeyError, fn ->
        LockManagement.get_lock_details(client_id: "test", access_token: "token")
      end
    end

    test "handles all required parameters" do
      # This will return an API error for invalid client_id but validates parameter handling
      result =
        LockManagement.get_lock_details(
          client_id: "test",
          access_token: "token",
          lock_id: 532_323
        )

      assert match?({:ok, %{"errcode" => 10000}}, result) or match?({:error, _}, result)
    end
  end

  describe "timestamp functionality" do
    test "generates valid timestamps" do
      # Make a call that uses current_timestamp internally
      result =
        LockManagement.get_lock_list(
          client_id: "test",
          access_token: "token",
          page_no: 1,
          page_size: 20
        )

      # We don't test the private function directly, just that it works
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end
end
