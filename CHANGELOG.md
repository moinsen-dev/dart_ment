# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-05-29

### Added
- **User Configuration Directory**: Created `~/.dart_ment/` directory for storing user configurations and API keys
- **Model Selection**: Added support for selecting different AI models via `--model` flag
- **Models Command**: New `ment models` command to list and select available Gemini models
  - Interactive model selection with `ment models --select`
  - Table view of available models with token limits
  - Direct model setting with `ment models --set <model-id>`
- **Configuration Manager**: Implemented centralized configuration management in user's home directory
- **Config Command**: Added `ment config` command for managing settings and API keys
- **API Key Security**: Secure storage of API keys in separate file with restrictive permissions (chmod 600)
- **AI Response Parser**: Robust parsing of AI responses to handle various formatting styles
- **Multiple Model Support**: Framework for supporting multiple AI providers (Gemini, OpenAI, Anthropic)
- **Folder Argument Support**: Both `analyze` and `fix` commands now accept an optional directory path
  - Example: `ment analyze lib/src` or `ment fix example`
- **Progress Reporting**: Enhanced progress indicators showing file names and percentages during analysis
- **Token Optimization**: Added `--all-files` flag to analyze command
  - By default, only files with errors are sent to AI for suggestions (saves tokens)
  - Use `--all-files` to analyze all files regardless of errors

### Changed
- **Configuration Location**: Moved from project-local config to user home directory for better usability
- **API Key Management**: Improved API key handling with secure storage and multiple fallback options
- **Error Messages**: Enhanced error messages for missing API keys with clear instructions
- **Models Command Display**: Improved formatting with table layout and visual indicators for selected model
- **Progress Display**: Now shows detailed progress with file paths and completion percentages
- **Analyze Command Efficiency**: Two-phase analysis - first runs Dart analyzer, then only sends files with issues to AI

### Fixed
- **AI Response Formatting**: Fixed issue where AI responses with markdown code blocks were not properly parsed
- **Test File Parsing**: Corrected handling of AI-generated fixes that included code fence markers
- **Config Command Type Casting**: Fixed YamlMap to Map<String, dynamic> conversion errors
- **API Key Loading**: Fixed analyze command not properly loading API keys from user configuration
- **Linting Issues**: Resolved all linting warnings including null-to-bool conversions and async I/O operations

### Removed
- **Sample Command**: Removed the sample command as it was only for development reference and not needed by users

## [0.1.0] - 2025-05-29

### Added
- **Google Gemini AI Integration**: Replaced OpenAI with Google Gemini for better Flutter/Dart support
- **Fix Command**: Implemented `ment fix` command to automatically fix linting issues using AI
- **Analyze Command**: Implemented `ment analyze` command to analyze code quality and provide AI-powered suggestions
- **Services Layer**: Added AnalyzerService for Dart code analysis and GeminiService for AI integration
- **Configuration Support**: Added support for custom configuration files and environment variables
- **Command Options**: Added --api-key, --config, --dry-run flags for fix command, and --suggestions flag for analyze command
- **Test Coverage**: Added comprehensive tests for new commands

### Changed
- Migrated from OpenAI to Google Gemini API (flutter_gemini package v3.0.0)
- Updated project description and documentation to reflect AI integration
- Enhanced command runner with new commands and better descriptions
- Improved error handling and user feedback

### Fixed
- Resolved all TODO comments in the codebase
- Fixed linting issues and improved code organization
- Updated exports in dart_ment.dart to include new services

## [0.0.1-dev.1] - 2025-02-13

### Added
- Initial project setup
- Basic project structure and documentation
- Project specification (SPEC.md)
- Development environment configuration
- Basic CLI structure

### Changed
- Updated README.md with project overview and goals
- Configured analysis options

### Development
This is a pre-release version focused on initial development and project setup. The core functionality is not yet implemented.

[0.0.1-dev.1]: https://github.com/yourusername/dart_ment/releases/tag/v0.0.1-dev.1