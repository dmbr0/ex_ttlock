# Code Style and Conventions

## Elixir Style Guide
The project follows standard Elixir conventions:

### File Organization
- Module files use snake_case naming (e.g., `oauth.ex`, `lock_management.ex`)
- Main module: `lib/t_tlock_client.ex`
- Submodules: `lib/ttlock_client/` directory

### Naming Conventions
- Modules: PascalCase (e.g., `TTlockClient.OAuth`)
- Functions: snake_case (e.g., `get_access_token/1`)
- Variables: snake_case
- Atoms: snake_case

### Code Formatting
Configured in `.formatter.exs`:
```elixir
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
```

### Documentation Style
- Use `@moduledoc` for module documentation
- Use `@doc` for function documentation
- Include examples in docstrings
- Use `@spec` for type specifications

Example from `oauth.ex`:
```elixir
@doc """
Get an access token using TTLock app account credentials.

## Parameters
- `client_id`: Application clientId from TTLock Create Application page
- `client_secret`: Application clientSecret from TTLock Create Application page  

## Returns
- `{:ok, token_response}` on success
- `{:error, reason}` on failure

## Example
    {:ok, %{"access_token" => "...", "uid" => 2340}} = 
      TTlockClient.OAuth.get_access_token(...)
"""
@spec get_access_token(oauth_config()) :: {:ok, token_response()} | {:error, term()}
```

### Type Specifications
- Define custom types using `@type`
- Use descriptive type names
- Include comprehensive specs for public functions

### Error Handling
- Use `{:ok, result}` | `{:error, reason}` pattern
- Provide meaningful error messages
- Use `Keyword.fetch!/2` for required options
- Raise `ArgumentError` for configuration issues

### Configuration Pattern
- Support both runtime options and application config
- Fall back gracefully: runtime → app config → error
- Use `get_config_value/2` helper pattern

### Test Style
- One test file per module
- Use descriptive test names
- Set up test configuration in `test_helper.exs`
- Mock external dependencies appropriately