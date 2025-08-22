# Application Architecture

## OTP Application Structure

### Application Module: TTlockClient.Application
**Location**: `lib/ttlock_client/application.ex`

The application starts with a supervision tree containing:
1. **Finch HTTP Client**: Named `TTlockClient.Finch` for HTTP requests
2. **AuthManager GenServer**: Centralized OAuth token management

### Startup Process
```elixir
def start(_type, _args) do
  # Load .env file in development and test environments
  if Mix.env() in [:dev, :test] do
    Dotenv.load()
  end

  children = [
    # Start Finch HTTP client
    {Finch, name: TTlockClient.Finch},
    # Start the authentication manager
    TTlockClient.AuthManager
  ]

  opts = [strategy: :one_for_one, name: TTlockClient.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## Centralized Authentication Pattern

### AuthManager GenServer
- **Purpose**: Single point for all OAuth token management
- **Features**:
  - Automatic token refresh 5 minutes before expiry
  - Thread-safe concurrent access
  - Centralized authentication state
  - Fault-tolerant with proper supervision

### Benefits
1. **No Module Dependencies**: API modules get tokens without OAuth knowledge
2. **Automatic Refresh**: Proactive token management
3. **Thread Safety**: Safe concurrent access from multiple processes  
4. **Fault Tolerance**: Proper OTP supervision and error recovery
5. **Centralized Logic**: All authentication logic in one place

## Module Hierarchy

```
TTlockClient (main API)
├── TTlockClient.Application (OTP app)
├── TTlockClient.AuthManager (GenServer)
├── TTlockClient.OAuthClient (OAuth API)
├── TTlockClient.Locks (Lock management)
├── TTlockClient.Passcodes (Passcode management)
└── TTlockClient.Types (Type definitions)
```

## Data Flow

```
User Request
    ↓
TTlockClient API
    ↓
AuthManager (get valid token)
    ↓
API Module (Locks/Passcodes)
    ↓
Finch HTTP Client
    ↓
TTLock Cloud API
```

## Configuration Management
- **Development**: Automatic .env file loading via Dotenv
- **Production**: Environment variables
- **Runtime**: Dynamic configuration support
- **Security**: No secrets in code, proper .gitignore usage

## Error Handling Strategy
- **Structured Errors**: `{:ok, result}` and `{:error, reason}` patterns
- **Network Errors**: Transport error handling
- **API Errors**: TTLock-specific error code handling  
- **State Errors**: Authentication state management
- **Recovery**: Automatic retry and refresh mechanisms