# Configuration and Environment Support

## Configuration System
The ex_ttlock library has comprehensive config/environment variable support implemented:

### Main Configuration File
**Location**: `config/config.exs`

```elixir
import Config

config :ex_ttlock,
  client_id: System.get_env("TTLOCK_CLIENT_ID"),
  client_secret: System.get_env("TTLOCK_CLIENT_SECRET"),
  username: System.get_env("TTLOCK_USERNAME"),
  password: System.get_env("TTLOCK_PASSWORD")

# Import environment specific config
import_config "#{config_env()}.exs"
```

### Environment-Specific Configs
- `config/dev.exs` - Development environment (currently minimal)
- `config/test.exs` - Test environment (currently minimal)
- `config/prod.exs` - Production environment (currently minimal)

### Environment Variables
The library expects these environment variables:
- `TTLOCK_CLIENT_ID` - TTLock application client ID
- `TTLOCK_CLIENT_SECRET` - TTLock application client secret
- `TTLOCK_USERNAME` - TTLock app account username
- `TTLOCK_PASSWORD` - TTLock app account password

### Configuration Resolution
The OAuth module (`lib/ttlock_client/oauth.ex`) implements a configuration resolution pattern:

```elixir
defp get_config_value(opts, key) do
  case Keyword.get(opts, key) do
    nil -> 
      case Application.get_env(:ex_ttlock, key) do
        nil -> raise ArgumentError, "#{key} is required either as option or in config"
        value -> value
      end
    value -> value
  end
end
```

This allows for:
1. **Runtime options**: Pass values directly to function calls
2. **Application config**: Fall back to configured values
3. **Environment variables**: Configured values can come from env vars
4. **Error handling**: Raises clear error if value is missing

### Test Configuration
`test/test_helper.exs` sets up test values to avoid requiring real environment variables:

```elixir
Application.put_env(:ex_ttlock, :client_id, "test_client_id")
Application.put_env(:ex_ttlock, :client_secret, "test_client_secret")
Application.put_env(:ex_ttlock, :username, "test_username")
Application.put_env(:ex_ttlock, :password, "test_password")
```

## Status: ✅ Complete
The config/env support is well-implemented with:
- Environment variable support via `System.get_env/1`
- Multiple configuration levels (runtime, app config, env vars)
- Environment-specific configuration files
- Proper test isolation
- Clear error messages for missing configuration