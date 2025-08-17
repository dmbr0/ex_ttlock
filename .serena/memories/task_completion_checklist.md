# Task Completion Checklist

## When a development task is completed, run these commands:

### 1. Code Formatting
```bash
mix format
```
- Ensures code follows project formatting standards
- Based on `.formatter.exs` configuration
- Required before committing code

### 2. Testing
```bash
mix test
```
- Runs the complete test suite
- All tests must pass before task completion
- Use `mix test --cover` for coverage information if needed

### 3. Compilation Check
```bash
mix compile
```
- Ensures code compiles without warnings
- Catches any compilation errors
- Verifies dependencies are correctly resolved

### 4. Optional: Dependency Check
```bash
mix deps
```
- Only needed if dependencies were modified
- Ensures all dependencies are properly resolved

## Before Committing (if applicable)
### 5. Git Status Check
```bash
git status
```
- Review all changes before committing
- Ensure no unintended files are included

### 6. Environment Variables
Ensure these are set if testing with real API:
```bash
export TTLOCK_CLIENT_ID="your_client_id"
export TTLOCK_CLIENT_SECRET="your_client_secret"
export TTLOCK_USERNAME="your_username" 
export TTLOCK_PASSWORD="your_password"
```

## Notes
- The project uses ExUnit for testing
- Tests are configured to use mock values in `test_helper.exs`
- No additional linting tools are currently configured
- The project targets Elixir 1.18+ and uses standard Mix project structure