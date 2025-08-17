ExUnit.start()

# Set test configuration to avoid requiring environment variables
Application.put_env(:ex_ttlock, :client_id, "test_client_id")
Application.put_env(:ex_ttlock, :client_secret, "test_client_secret")
Application.put_env(:ex_ttlock, :username, "test_username")
Application.put_env(:ex_ttlock, :password, "test_password")
