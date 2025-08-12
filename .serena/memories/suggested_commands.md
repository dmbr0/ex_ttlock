# Suggested Commands for ex_ttlock Development

## Development Commands

### Dependencies
```bash
# Install/update dependencies
mix deps.get

# Check dependency status
mix deps
```

### Compilation
```bash
# Compile the project
mix compile

# Clean build artifacts
mix clean
```

### Code Quality
```bash
# Format code according to .formatter.exs
mix format

# Check if code is formatted
mix format --check-formatted
```

### Testing
```bash
# Run all tests
mix test

# Run specific test file
mix test test/ttlock_client/oauth_test.exs

# Run tests with coverage
mix test --cover

# Run tests in verbose mode
mix test --trace
```

### Documentation
```bash
# Generate documentation
mix docs

# Start IEx with project loaded
iex -S mix
```

### Environment Setup
```bash
# Set required environment variables
export TTLOCK_CLIENT_ID="your_client_id"
export TTLOCK_CLIENT_SECRET="your_client_secret" 
export TTLOCK_USERNAME="your_username"
export TTLOCK_PASSWORD="your_password"
```

### System Commands (Linux)
```bash
# File operations
ls -la
find . -name "*.ex" -type f
grep -r "pattern" lib/

# Git operations
git status
git add .
git commit -m "message"
git push
```

## Task Completion Workflow
When completing a task, run these commands in order:
1. `mix format` - Format code
2. `mix test` - Ensure tests pass
3. `mix compile` - Verify compilation
4. Git operations if committing changes