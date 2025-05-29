# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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