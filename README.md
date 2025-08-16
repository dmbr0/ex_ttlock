# TTlockClient

An Elixir client library for the TTLock Open Platform API with centralized OAuth 2.0 authentication management.

## Features

- **Centralized Authentication**: Single GenServer manages all OAuth token lifecycle
- **Automatic Token Refresh**: Proactive token refresh before expiry
- **Thread-Safe**: Safe concurrent access to authentication state
- **OTP Compliant**: Proper supervision and fault tolerance
- **Zero Module Dependencies**: No authentication logic scattered across modules

## Installation

Add `ex_ttlock` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_ttlock, "~> 0.1.0"}
  ]
end
```

## Quick Start

### 1. Configuration

Configure your TTLock application credentials:

```elixir
# Configure with client credentials from TTLock developer portal
TTlockClient.configure("your_client_id", "your_client_secret")

# Optional: specify different API region
TTlockClient.configure("client_id", "client_secret", "https://usapi.ttlock.com")
```

### 2. Authentication

Authenticate using your TTLock mobile app credentials (**not** developer portal credentials):

```elixir
# Use your TTLock mobile app username and password
TTlockClient.authenticate("+8618966498228", "your_app_password")
# or
TTlockClient.authenticate("your_email@example.com", "your_app_password")
```

### 3. Making API Calls

Get valid tokens for your API requests:

```elixir
case TTlockClient.get_valid_token() do
  {:ok, token} ->
    # Token is automatically refreshed if needed
    headers = [{"Authorization", "Bearer #{token}"}]
    # Make your TTLock API calls
    
  {:error, :not_authenticated} ->
    # Need to authenticate first
    TTlockClient.authenticate("username", "password")
    
  {:error, reason} ->
    # Handle authentication errors
    Logger.error("Auth error: #{inspect(reason)}")
end
```

## Advanced Usage

### All-in-One Setup

```elixir
# Configure and authenticate in one call
case TTlockClient.start("client_id", "client_secret", "username", "password") do
  :ok -> 
    {:ok, token} = TTlockClient.get_valid_token()
    # Ready to make API calls
    
  {:error, reason} ->
    # Handle setup error
end
```

### Status Checking

```elixir
case TTlockClient.status() do
  :not_configured -> 
    # Need to call TTlockClient.configure/2
  :configured -> 
    # Configured but need to authenticate
  :authenticated -> 
    # Ready for API calls
end

# Or use the convenience function
if TTlockClient.ready?() do
  # Make API calls
end
```

### Manual Token Management

```elixir
# Force token refresh (usually not needed)
TTlockClient.refresh_token()

# Get current user ID
{:ok, user_id} = TTlockClient.get_user_id()

# Reset all authentication state
TTlockClient.reset()
```

## Configuration Options

### Application Configuration

```elixir
# config/config.exs
config :ex_ttlock,
  client_id: "your_client_id",
  client_secret: "your_client_secret",
  base_url: "https://euapi.ttlock.com"  # optional
```

### Environment Variables

```bash
export TTLOCK_CLIENT_ID="your_client_id"
export TTLOCK_CLIENT_SECRET="your_client_secret"
export TTLOCK_BASE_URL="https://euapi.ttlock.com"  # optional
```

## API Reference

### TTlockClient

- `configure/2,3` - Set client credentials
- `authenticate/2` - Authenticate with username/password
- `get_valid_token/0` - Get current valid access token
- `get_user_id/0` - Get authenticated user ID
- `refresh_token/0` - Manually refresh token
- `status/0` - Get authentication status
- `ready?/0` - Check if ready for API calls
- `reset/0` - Clear all authentication state
- `start/4,5` - Configure and authenticate in one call

### Authentication States

- `:not_configured` - No client credentials set
- `:configured` - Client configured but not authenticated
- `:authenticated` - Fully authenticated and ready

## Architecture

The library uses a centralized authentication pattern with a GenServer that manages all OAuth state:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Your App      │───▶│  TTlockClient   │───▶│ TTlockClient    │
│                 │    │ .API            │    │ .AuthManager    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                               ┌───────▼────────┐
                                               │ TTlockClient   │
                                               │ .OAuthClient   │
                                               └────────────────┘
```

### Key Benefits

1. **No Module Dependencies**: Each module gets tokens without knowing about OAuth
2. **Automatic Refresh**: Tokens refreshed 5 minutes before expiry
3. **Thread Safety**: Safe concurrent access from multiple processes
4. **Fault Tolerance**: Proper OTP supervision and error recovery
5. **Centralized Logic**: All authentication logic in one place

## Error Handling

The library provides detailed error information:

```elixir
case TTlockClient.authenticate("username", "password") do
  :ok -> 
    # Success
    
  {:error, %{error_code: 10001, description: "Invalid credentials"}} ->
    # TTLock API error
    
  {:error, :not_configured} ->
    # Need to configure client first
    
  {:error, {:transport_error, reason}} ->
    # Network error
    
  {:error, reason} ->
    # Other errors
end
```

### Common Error Codes

- `10001` - Invalid credentials
- `10004` - Token expired (handled automatically)
- `10005` - Invalid client credentials

## Testing

```bash
# Run tests
mix test

# Run with coverage
mix test.coverage

# Run specific test file
mix test test/ttlock_client_test.exs

# Watch mode for development
mix test.watch
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the style guides:
   - [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
   - [Erlang Guidelines](https://github.com/inaka/erlang_guidelines)
4. Add tests for your changes
5. Ensure all tests pass (`mix test`)
6. Run code analysis (`mix credo`)
7. Commit your changes (`git commit -m 'Add amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## TTLock API Documentation

For complete TTLock API documentation, visit:
- [TTLock Open Platform](https://open.ttlock.com/)
- [API Documentation](https://open.ttlock.com/doc/api)

## Support

- Create an issue for bug reports or feature requests
- Check existing issues before creating new ones
- Provide clear reproduction steps for bugs