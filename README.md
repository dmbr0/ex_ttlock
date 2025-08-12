# TTlockClient

An Elixir client library for TTLock API integration, providing OAuth authentication, lock management, and passcode management functionality.

## Features

- OAuth2 authentication with TTLock API
- Lock management operations (list locks, get lock details)
- Passcode management (add, delete, change, list passcodes)
- Support for different passcode types (permanent, period, single use)
- Automatic token refresh handling
- Comprehensive error handling and response parsing

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_ttlock` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_ttlock, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_ttlock>.

