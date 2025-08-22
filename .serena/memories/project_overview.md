# TTlockClient Project Overview

## Project Purpose
TTlockClient is an Elixir client library for the TTLock Open Platform API with centralized OAuth 2.0 authentication management. It provides a complete interface for managing smart locks and passcodes through the TTLock cloud API.

## Key Features
- **Centralized Authentication**: Single GenServer manages all OAuth token lifecycle
- **Automatic Token Refresh**: Proactive token refresh before expiry  
- **Thread-Safe**: Safe concurrent access to authentication state
- **OTP Compliant**: Proper supervision and fault tolerance
- **Zero Module Dependencies**: No authentication logic scattered across modules

## Tech Stack
- **Language**: Elixir 1.18+
- **HTTP Client**: Finch (~> 0.16)
- **JSON Processing**: Jason (~> 1.4)
- **Environment Variables**: Dotenv (~> 3.1) for dev/test
- **Documentation**: ExDoc (~> 0.30)
- **Code Quality**: Credo (~> 1.7), Dialyxir (~> 1.4)
- **Testing**: ExUnit with Excoveralls (~> 0.18) for coverage
- **Test Tools**: Bypass (~> 2.1), Mix Test Watch (~> 1.0)

## Application Architecture
The application is a proper OTP application with:
- Main module: `TTlockClient`
- Application module: `TTlockClient.Application` 
- Supervision tree with Finch HTTP client and AuthManager GenServer
- Modular structure with separate concerns for auth, locks, and passcodes

## Module Structure
```
lib/
├── ttlock_client.ex                 # Main API module
└── ttlock_client/
    ├── application.ex               # OTP Application startup
    ├── auth_manager.ex              # OAuth token management GenServer
    ├── oauth_client.ex              # OAuth API client
    ├── locks.ex                     # Lock management APIs
    ├── passcodes.ex                 # Passcode management APIs
    └── types.ex                     # Type definitions
```

## Configuration
- Uses .env files for development (automatically loaded)
- Environment variables for production
- Mix project configuration for dependencies and aliases
- Hex package ready for publication