# Project Overview: ex_ttlock

## Purpose
This is an Elixir library for TTlock integration, providing a client for interacting with TTLock smart lock APIs. The project is structured as a library package intended for Hex publication.

## Tech Stack
- **Language**: Elixir 1.18+
- **HTTP Client**: HTTPoison (~> 2.0)
- **JSON Parser**: Jason (~> 1.4)
- **Testing Framework**: ExUnit
- **Build Tool**: Mix

## Project Structure
```
lib/
├── t_tlock_client.ex                    # Main module (placeholder)
└── ttlock_client/
    ├── oauth.ex                         # OAuth2 authentication
    ├── lock_management.ex               # Lock operations
    └── passcode_management.ex           # Passcode operations

test/
├── test_helper.exs                      # Test configuration
├── t_tlock_client_test.exs             # Main module tests
└── ttlock_client/
    ├── oauth_test.exs                  # OAuth tests
    ├── lock_management_test.exs        # Lock management tests
    └── passcode_management_test.exs    # Passcode management tests

config/
├── config.exs                          # Main config with env vars
├── dev.exs                             # Development config
├── test.exs                            # Test config
└── prod.exs                            # Production config
```

## Key Features
- OAuth2 authentication with TTLock API
- Lock management operations (list, details)
- Passcode management (add, delete, change, list)
- Environment variable configuration support
- Comprehensive test coverage