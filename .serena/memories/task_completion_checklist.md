# Task Completion Checklist

## Before Completing Any Task

### Code Quality
- [ ] Run `mix format` to format all code
- [ ] Run `mix credo --strict` and fix any issues
- [ ] Run `mix dialyzer` and resolve any type warnings
- [ ] Or use `mix quality` to run all quality checks at once

### Testing
- [ ] Run `mix test` to ensure all tests pass
- [ ] Add tests for any new functionality
- [ ] Run `mix test.coverage` to check test coverage
- [ ] Verify test coverage is adequate for changes

### Documentation
- [ ] Update module documentation (`@moduledoc`) if needed
- [ ] Add function documentation (`@doc`) for public functions
- [ ] Add typespecs (`@spec`) for public functions
- [ ] Update README.md if API changes were made
- [ ] Update CHANGELOG.md with changes

### Configuration & Dependencies
- [ ] Update `mix.exs` if dependencies were added/changed
- [ ] Run `mix deps.get` if dependencies changed
- [ ] Check that .env files are in .gitignore
- [ ] Verify no secrets are committed

### Code Review Checklist
- [ ] Code follows Elixir style conventions
- [ ] Functions have appropriate error handling
- [ ] OTP principles followed (supervision, GenServer patterns)
- [ ] No authentication logic scattered across modules
- [ ] Thread-safe concurrent access maintained
- [ ] Proper use of `{:ok, result}` and `{:error, reason}` patterns

### Application Specific
- [ ] AuthManager GenServer functioning properly
- [ ] Token refresh mechanism working
- [ ] API calls using centralized authentication
- [ ] Environment variable loading working in dev/test
- [ ] Examples scripts still work if API changed

### Final Verification
- [ ] `mix compile` succeeds without warnings
- [ ] `mix quality` passes all checks
- [ ] `mix test` passes all tests
- [ ] Application starts without errors
- [ ] Example scripts execute successfully

## Git Workflow
- [ ] Commit messages are clear and descriptive
- [ ] Changes are logically grouped in commits
- [ ] Branch is up to date with main/master
- [ ] No merge conflicts exist