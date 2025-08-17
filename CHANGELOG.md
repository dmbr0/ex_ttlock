# Changelog

All notable changes to this project will be documented in this file.

## [0.1.3] - 2025-08-17

### Added

- **Passcode Change Functionality**: Complete implementation of TTLock's change passcode API
  - `change_passcode/6` - Change passcode name, value, or validity period
  - `change_passcode_name/3` - Change only the passcode name
  - `change_passcode_value/3` - Change only the passcode value
  - `change_passcode_period/4` - Change only the validity period
  - Support for changing multiple passcode properties simultaneously
- **New Type System Support**:
  - `passcode_change_params` record for type-safe change operations
  - `new_passcode_change_params/7` constructor function
  - `passcode_change_response` type definition
- **Enhanced Validation**:
  - Comprehensive parameter validation for change operations
  - Clear error messages for invalid parameters
  - Validation for passcode value ranges (4-9 digits)
  - Date validation for validity period changes
- **Extended Test Coverage**:
  - Tests for all change passcode functions
  - Validation error testing
  - Authentication requirement testing
- **Documentation Updates**:
  - Updated README with change passcode examples
  - Added change passcode section to API reference
  - Enhanced passcodes_example.exs with change demonstrations
- **Helper Functions**:
  - `change_types/0` - Get available change type constants
  - Support for DateTime to milliseconds conversion in change operations

### Enhanced

- **Passcodes Module**: Extended with change functionality while maintaining backward compatibility
- **Main TTlockClient Module**: Added convenience functions for common change scenarios
- **Type System**: Enhanced with new records for change operations
- **Example Scripts**: Added comprehensive change passcode examples with error handling
- **Error Handling**: Improved error messages and validation feedback

### Technical Details

- All change operations use TTLock's `/v3/keyboardPwd/change` endpoint
- Changes work via Gateway/WiFi locks (changeType=2)
- Maintains centralized authentication pattern with AuthManager
- Full integration with existing record-based type system
- Follows Erlang/Elixir style guidelines

## [0.1.2] - 2025-08-16

### Added

- **Passcode Listing and Search**: Complete implementation of passcode management
  - `get_passcodes/5` - Get paginated list of passcodes with filtering
  - `get_lock_passcodes/2` - Get all passcodes for a specific lock
  - `search_passcodes/2` - Search passcodes by name or value
  - `get_passcode_list/1` - Low-level API for advanced control
- **Pagination Support**: Full pagination handling for large passcode lists
- **Search Functionality**: Fuzzy search by name and exact match by passcode value
- **Advanced Filtering**: Search, pagination, and sorting options
- **Enhanced Examples**: Comprehensive examples for listing and searching passcodes

### Enhanced

- **Types Module**: Added passcode list parameters and response types
- **Documentation**: Updated with passcode listing examples and API reference

## [0.1.1] - 2025-08-15

### Added

- **Passcode Management**: Core passcode functionality
  - `add_permanent_passcode/3` - Add permanent passcodes via gateway
  - `add_temporary_passcode/5` - Add time-limited passcodes
  - `add_passcode/8` - Full control over passcode parameters
  - `delete_passcode/2` - Delete passcodes via gateway
  - `delete_passcode_via_gateway/2` - Explicit gateway deletion
- **Lock Management**: Complete lock API implementation
  - `get_locks/4` - Get paginated list of locks
  - `get_lock/1` - Get detailed lock information
  - `get_all_locks/2` - Get all locks with automatic pagination
- **Type System**: Comprehensive record-based type definitions
  - `passcode_add_params`, `passcode_delete_params`, `lock_list_params`
  - Helper constructor functions for all parameter types
  - Strong typing with validation
- **Low-Level API Access**: Direct access to specialized modules
  - `TTlockClient.Locks` - Lock-specific operations
  - `TTlockClient.Passcodes` - Passcode-specific operations
  - `TTlockClient.Types` - Type definitions and helpers

### Enhanced

- **Authentication**: Robust error handling and token refresh
- **Validation**: Parameter validation with clear error messages
- **Examples**: Comprehensive example scripts for all functionality

## [0.1.0] - 2025-08-14

### Added

- **Initial Release**: Core TTLock client library
- **Centralized Authentication**: GenServer-based authentication manager
  - Automatic OAuth 2.0 token refresh
  - Thread-safe token access
  - Proper OTP supervision
- **Configuration Management**:
  - `configure/3` - Set client credentials
  - `authenticate/2` - Authenticate with TTLock credentials
  - `start_with_env/0` - Environment variable configuration
- **Token Management**:
  - `get_valid_token/0` - Get valid access token with auto-refresh
  - `refresh_token/0` - Manual token refresh
  - `get_user_id/0` - Get authenticated user ID
- **Status Management**:
  - `status/0` - Get authentication status
  - `ready?/0` - Check if ready for API calls
  - `reset/0` - Clear authentication state
- **Core Architecture**:
  - Centralized authentication with AuthManager GenServer
  - Record-based type system for type safety
  - Comprehensive error handling
  - OTP-compliant design with supervision
- **Development Tools**:
  - `.env` file support for development
  - Example scripts and documentation
  - Comprehensive test suite

### Technical Foundation

- **HTTP Client**: Finch-based HTTP client with proper error handling
- **JSON Processing**: Jason for robust JSON encoding/decoding
- **OAuth 2.0**: Complete OAuth flow implementation
- **MD5 Hashing**: Password hashing for TTLock authentication
- **DateTime Handling**: Proper timestamp and expiry management
- **Validation**: Parameter validation throughout the library

---

## Development Guidelines

### Adding New Features

1. Add type definitions to `TTlockClient.Types`
2. Implement core functionality in appropriate module
3. Add convenience functions to main `TTlockClient` module
4. Write comprehensive tests
5. Update documentation and examples
6. Follow Erlang/Elixir style guidelines

### Version Numbering

- **MAJOR**: Breaking changes to public API
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Links

- [TTLock Open Platform](https://open.ttlock.com/)
- [API Documentation](https://open.ttlock.com/doc/api)
- [GitHub Repository](https://github.com/dmbr0/ex_ttlock)
