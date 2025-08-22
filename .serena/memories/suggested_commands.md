# Suggested Development Commands

## Core Development Commands

### Project Setup
```bash
# Install dependencies
mix deps.get

# Compile the project
mix compile
```

### Code Quality & Formatting
```bash
# Format code according to .formatter.exs
mix format

# Run code quality checks (format + credo + dialyzer)
mix quality

# Fix code quality issues automatically
mix quality.fix

# Run strict Credo analysis
mix credo --strict

# Run Dialyzer for type analysis
mix dialyzer
```

### Testing
```bash
# Run all tests
mix test

# Run tests with coverage report (HTML)
mix test.coverage

# Run tests with coverage for CI (JSON)
mix test.ci

# Run specific test file
mix test test/ttlock_client_test.exs

# Watch mode for continuous testing
mix test.watch

# Watch mode for stale tests only  
mix test.watch --stale
```

### Documentation
```bash
# Generate documentation
mix docs

# View docs locally after generation
open doc/index.html
```

### Project Management
```bash
# Check dependency status
mix deps

# Update dependencies
mix deps.update --all

# Clean compiled files
mix clean

# Get project info
mix app.tree
```

### Example Scripts
```bash
# Basic authentication example
elixir example.exs

# Simple setup with .env
elixir example.exs simple

# Real-time token monitoring
elixir example.exs monitor

# Lock management examples
elixir locks_example.exs

# Advanced lock operations
elixir locks_example.exs detail

# Passcode management examples  
elixir passcodes_example.exs

# Advanced passcode operations
elixir passcodes_example.exs advanced
```

### System Commands (Linux)
```bash
# File operations
ls -la                    # List files with details
find . -name "*.ex"       # Find Elixir source files
grep -r "pattern" lib/    # Search in lib directory

# Git operations
git status               # Check repository status
git add .                # Stage all changes
git commit -m "message"  # Commit changes
git push                 # Push to remote

# Process management
ps aux | grep beam       # Find Elixir/Erlang processes
kill -9 <pid>           # Kill process if needed
```