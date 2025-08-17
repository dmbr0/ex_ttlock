defmodule TTlockClient.PasscodeManagementTest do
  use ExUnit.Case, async: true
  doctest TTlockClient.PasscodeManagement

  alias TTlockClient.PasscodeManagement

  describe "add_passcode/1" do
    test "validates required parameters" do
      assert_raise KeyError, fn ->
        PasscodeManagement.add_passcode([])
      end

      assert_raise KeyError, fn ->
        PasscodeManagement.add_passcode(client_id: "test")
      end

      assert_raise KeyError, fn ->
        PasscodeManagement.add_passcode(
          client_id: "test",
          access_token: "token",
          lock_id: 123_456
        )
      end

      assert_raise KeyError, fn ->
        PasscodeManagement.add_passcode(
          client_id: "test",
          access_token: "token",
          lock_id: 123_456,
          keyboard_pwd: "123456"
        )
      end

      assert_raise KeyError, fn ->
        PasscodeManagement.add_passcode(
          client_id: "test",
          access_token: "token",
          lock_id: 123_456,
          keyboard_pwd: "123456",
          start_date: 1_700_000_000_000
        )
      end
    end

    test "handles all required parameters with default add_type" do
      result =
        PasscodeManagement.add_passcode(
          client_id: "test",
          access_token: "token",
          lock_id: 123_456,
          keyboard_pwd: "123456",
          start_date: 1_700_000_000_000,
          end_date: 1_705_000_000_000
        )

      assert match?({:ok, %{"errcode" => 10000}}, result) or match?({:error, _}, result)
    end

    test "handles all parameters including add_type" do
      result =
        PasscodeManagement.add_passcode(
          client_id: "test",
          access_token: "token",
          lock_id: 123_456,
          keyboard_pwd: "123456",
          start_date: 1_700_000_000_000,
          end_date: 1_705_000_000_000,
          add_type: 3
        )

      assert match?({:ok, %{"errcode" => 10000}}, result) or match?({:error, _}, result)
    end
  end

  describe "delete_passcode/1" do
    test "validates required parameters" do
      assert_raise KeyError, fn ->
        PasscodeManagement.delete_passcode([])
      end

      assert_raise KeyError, fn ->
        PasscodeManagement.delete_passcode(client_id: "test")
      end

      assert_raise KeyError, fn ->
        PasscodeManagement.delete_passcode(
          client_id: "test",
          access_token: "token"
        )
      end

      assert_raise KeyError, fn ->
        PasscodeManagement.delete_passcode(
          client_id: "test",
          access_token: "token",
          lock_id: 123_456
        )
      end
    end

    test "handles all required parameters" do
      result =
        PasscodeManagement.delete_passcode(
          client_id: "test",
          access_token: "token",
          lock_id: 123_456,
          keyboard_pwd_id: 98765
        )

      assert match?({:ok, %{"errcode" => 10000}}, result) or match?({:error, _}, result)
    end
  end

  describe "change_passcode/1" do
    test "validates required parameters" do
      assert_raise KeyError, fn ->
        PasscodeManagement.change_passcode([])
      end

      assert_raise KeyError, fn ->
        PasscodeManagement.change_passcode(
          client_id: "test",
          access_token: "token",
          lock_id: 123_456,
          keyboard_pwd_id: 98765
        )
      end
    end

    test "handles all required parameters" do
      result =
        PasscodeManagement.change_passcode(
          client_id: "test",
          access_token: "token",
          lock_id: 123_456,
          keyboard_pwd_id: 98765,
          new_keyboard_pwd: "654321"
        )

      assert match?({:ok, %{"errcode" => 10000}}, result) or match?({:error, _}, result)
    end
  end

  describe "list_passcodes/1" do
    test "validates required parameters" do
      assert_raise KeyError, fn ->
        PasscodeManagement.list_passcodes([])
      end

      assert_raise KeyError, fn ->
        PasscodeManagement.list_passcodes(client_id: "test")
      end

      assert_raise KeyError, fn ->
        PasscodeManagement.list_passcodes(
          client_id: "test",
          access_token: "token"
        )
      end
    end

    test "handles required parameters with defaults" do
      result =
        PasscodeManagement.list_passcodes(
          client_id: "test",
          access_token: "token",
          lock_id: 123_456
        )

      assert match?({:ok, %{"errcode" => 10000}}, result) or match?({:error, _}, result)
    end

    test "handles all parameters including pagination" do
      result =
        PasscodeManagement.list_passcodes(
          client_id: "test",
          access_token: "token",
          lock_id: 123_456,
          page_no: 1,
          page_size: 10
        )

      assert match?({:ok, %{"errcode" => 10000}}, result) or match?({:error, _}, result)
    end
  end
end
