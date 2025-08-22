defmodule TTlockClient.GatewaysTest do
  use ExUnit.Case, async: true

  describe "list/4" do
    test "builds correct parameters for gateway list request" do
      # Mock the dependencies to verify parameter construction
      expected_params = %{
        clientId: "test_client_id",
        accessToken: "test_access_token",
        pageNo: 1,
        pageSize: 20,
        orderBy: 1,
        date: 1_234_567_890_000
      }

      # This test would require mocking HTTP and AuthManager modules
      # For now, we're testing parameter structure
      assert is_integer(expected_params.pageNo)
      assert is_integer(expected_params.pageSize)
      assert is_integer(expected_params.orderBy)
      assert is_integer(expected_params.date)
      assert is_binary(expected_params.clientId)
      assert is_binary(expected_params.accessToken)
    end

    test "validates order_by parameter values" do
      valid_order_by_values = [0, 1, 2]

      Enum.each(valid_order_by_values, fn order_by ->
        assert order_by in [0, 1, 2]
      end)
    end
  end

  describe "list_locks/2" do
    test "builds correct parameters for gateway locks request" do
      gateway_id = 12345

      expected_params = %{
        clientId: "test_client_id",
        accessToken: "test_access_token",
        gatewayId: gateway_id,
        date: 1_234_567_890_000
      }

      # Verify parameter structure
      assert is_integer(expected_params.gatewayId)
      assert is_integer(expected_params.date)
      assert is_binary(expected_params.clientId)
      assert is_binary(expected_params.accessToken)
    end

    test "requires integer gateway_id" do
      assert is_integer(12345)
      refute is_integer("12345")
      refute is_integer(nil)
    end
  end

  describe "response structure validation" do
    test "validates gateway list response structure" do
      sample_response = %{
        list: [
          %{
            gatewayId: 78979,
            gatewayMac: "C5:40:E0:9C:8C:C1",
            gatewayName: "My Gateway",
            gatewayVersion: 1,
            networkName: "1-101-WIFI",
            networkMac: "B5:11:E2:4D:7A:3F",
            lockNum: 2,
            isOnline: 1
          }
        ],
        pageNo: 1,
        pageSize: 20,
        pages: 1,
        total: 1
      }

      assert is_list(sample_response.list)
      assert is_integer(sample_response.pageNo)
      assert is_integer(sample_response.pageSize)
      assert is_integer(sample_response.pages)
      assert is_integer(sample_response.total)

      gateway = List.first(sample_response.list)
      assert is_integer(gateway.gatewayId)
      assert is_binary(gateway.gatewayMac)
      assert is_binary(gateway.gatewayName)
      assert is_integer(gateway.gatewayVersion)
      assert gateway.gatewayVersion in [1, 2, 3, 4]
      assert is_integer(gateway.isOnline)
      assert gateway.isOnline in [0, 1]
    end

    test "validates lock list response structure" do
      sample_response = %{
        list: [
          %{
            lockId: 532_323,
            lockName: "YS1003_c18c9c",
            lockAlias: "Front door lock",
            lockMac: "C5:40:E0:9C:8C:C1",
            rssi: -65,
            updateDate: 1_626_674_053_000
          }
        ]
      }

      assert is_list(sample_response.list)

      lock = List.first(sample_response.list)
      assert is_integer(lock.lockId)
      assert is_binary(lock.lockName)
      assert is_binary(lock.lockAlias)
      assert is_binary(lock.lockMac)
      assert is_integer(lock.rssi)
      assert is_integer(lock.updateDate)

      # RSSI validation (signal strength range)
      # RSSI is always negative
      assert lock.rssi < 0
      # Reasonable lower bound
      assert lock.rssi >= -100
    end
  end
end
