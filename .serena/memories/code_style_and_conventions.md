# Code Style and Conventions

## Elixir Style Guidelines
This project follows standard Elixir conventions as outlined in the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide) and [Erlang Guidelines](https://github.com/inaka/erlang_guidelines).

## Code Formatting
- **Formatter**: Uses `mix format` with configuration in `.formatter.exs`
- **Inputs**: Formats `{mix,.formatter}.exs` and `{config,lib,test}/**/*.{ex,exs}`
- **Automatic**: Run `mix format` before committing
- **Quality**: Use `mix quality` for comprehensive formatting + analysis

## Naming Conventions
- **Modules**: PascalCase (e.g., `TTlockClient.AuthManager`)
- **Functions**: snake_case (e.g., `get_valid_token/0`)
- **Variables**: snake_case (e.g., `client_id`)
- **Atoms**: snake_case (e.g., `:not_configured`)
- **Constants**: SCREAMING_SNAKE_CASE in module attributes

## Module Organization
- **Main API**: Single entry point module (`TTlockClient`)
- **Submodules**: Organized by functionality under `TTlockClient.*`
- **Application**: OTP application structure with supervision
- **Separation**: Clear separation of concerns (auth, API, types)

## Documentation
- **Module docs**: Use `@moduledoc` for module-level documentation
- **Function docs**: Use `@doc` for public functions
- **Types**: Define typespecs with `@type` and `@spec`
- **Examples**: Include usage examples in docstrings
- **Internal**: Use `@moduledoc false` for internal modules

## Error Handling
- **Tuples**: Use `{:ok, result}` and `{:error, reason}` patterns
- **Detailed errors**: Provide structured error information
- **Graceful**: Handle network errors, API errors, and state errors
- **Logging**: Use Logger for error reporting

## Code Quality Tools
- **Credo**: Static code analysis (`mix credo --strict`)
- **Dialyzer**: Type analysis (`mix dialyzer`) 
- **ExCoveralls**: Test coverage reporting
- **Mix aliases**: Use defined aliases for common tasks

## Testing Conventions
- **ExUnit**: Standard Elixir testing framework
- **Test files**: Mirror lib structure in test directory
- **Coverage**: Aim for comprehensive test coverage
- **Mocking**: Use Bypass for HTTP mocking in tests

## Configuration Patterns
- **Environment**: Support .env files for development
- **Application config**: Use application configuration
- **Runtime**: Support runtime environment variable configuration
- **Security**: Never commit secrets, use .gitignore for .env files