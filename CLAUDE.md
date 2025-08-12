# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Elixir project for TTlock integration (`ex_ttlock`). The project follows standard Elixir/Mix conventions and is structured as a library package intended for Hex publication.

**Project Structure:**
- `lib/t_tlock_client.ex` - Main module containing TTlockClient functionality
- `lib/ttlock_client/oauth.ex` - OAuth2 authentication module for TTLock API
- `test/t_tlock_client_test.exs` - Test suite for the main module
- `test/ttlock_client/oauth_test.exs` - Test suite for OAuth module
- `test/test_helper.exs` - ExUnit test configuration
- `mix.exs` - Project configuration and dependencies
- `.formatter.exs` - Code formatting configuration

## Common Commands

### Development
```bash
# Install dependencies
mix deps.get

# Compile the project
mix compile

# Format code
mix format

# Run tests
mix test

# Run specific test file
mix test test/t_tlock_client_test.exs

# Run tests with coverage
mix test --cover

# Get dependency information
mix deps
```

### Testing
- Tests use ExUnit framework
- Run `mix test` for the full test suite
- Individual test files can be run with `mix test <filepath>`
- Test coverage available with `--cover` flag

### Code Quality
- Code formatting is handled by `mix format`
- Formatter configuration in `.formatter.exs` includes standard Elixir patterns
- No additional linting tools configured currently

## Architecture Notes

- Modular architecture with `TTlockClient` as the main interface
- `TTlockClient.OAuth` module handles authentication and token management
- Uses HTTPoison for HTTP requests and Jason for JSON parsing
- Project is set up for Elixir 1.18+ and uses standard Mix project structure
- Configured for eventual Hex package publication

## OAuth Module

The `TTlockClient.OAuth` module provides:
- `get_access_token/1` - Obtain access token using Resource Owner Password Credentials
- `refresh_token/1` - Refresh expired access tokens
- `hash_password/1` - MD5 password hashing as required by TTLock API
- Automatic JSON response parsing and error handling