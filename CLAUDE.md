# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

dart_ment is an AI-powered automated code repair and refactoring CLI tool for Dart projects. It analyzes Dart code for linting issues and uses AI to automatically fix them.

## 🚨 IMPORTANT: Release Checklist

When preparing a new release, ALWAYS:

1. **Update Version Numbers**:
   - Update version in `pubspec.yaml`
   - Update version in `lib/src/version.dart` (should match pubspec.yaml)
   - Use semantic versioning: MAJOR.MINOR.PATCH

2. **Update CHANGELOG.md**:
   - Add a new section for the version with today's date
   - List all changes under appropriate categories:
     - `Added` for new features
     - `Changed` for changes in existing functionality
     - `Fixed` for bug fixes
     - `Deprecated` for soon-to-be removed features
     - `Removed` for removed features
     - `Security` for vulnerability fixes
   - Follow the [Keep a Changelog](https://keepachangelog.com) format

3. **Update Documentation**:
   - Update README.md if new commands or features were added
   - Update any affected documentation
   - Ensure examples reflect the new version

4. **Version Consistency**:
   - Ensure all version references are consistent across:
     - pubspec.yaml
     - lib/src/version.dart
     - CHANGELOG.md
     - Git tags (when creating release)

## Development Commands

### Essential Commands
```bash
# Install dependencies
dart pub get

# Run all tests
dart test

# Run a specific test
dart test test/path/to/specific_test.dart

# Run the CLI locally during development
dart run bin/ment.dart [command]

# Install globally for testing
dart pub global activate --source path .
```

### Available CLI Commands
- `ment analyze` - Analyze code quality metrics with AI-powered suggestions
- `ment config` - Manage configuration settings and API keys
- `ment fix` - Fix linting issues using AI (supports --model flag for model selection)
- `ment models` - List and select available AI models from Gemini API
- `ment update` - Check for CLI updates

## Architecture

### Command Structure
The CLI uses the `CommandRunner` pattern from the `args` package. Each command is a separate class extending `Command<int>` in `lib/src/commands/`:
- Commands are registered in `MentCommandRunner` (lib/src/command_runner.dart)
- Commands use `MasonLogger` for formatted console output
- Return codes: 0 for success, non-zero for errors

### Core Components
1. **Command Runner** (`lib/src/command_runner.dart`): Main entry point that manages commands
2. **Commands** (`lib/src/commands/`): Individual command implementations
3. **Configuration** (`lib/src/config/`): YAML-based configuration system
4. **Utils** (`lib/src/utils/`): Shared utilities like logger

### AI Integration Design
The tool is designed to support both:
- Google Gemini API (via `flutter_gemini` package)
- Local LLMs (via `llama-cpp` bindings)

Configuration is loaded from `default_config.yaml` and can be overridden by user config.

## Implementation Status

Current implementation status:
- Phase 1 (Setup): Complete ✅
- Phase 2 (Architecture): Complete ✅
- Phase 3 (Core Features): Complete ✅
  - `fix` command: Implemented with AI-powered fixes
  - `analyze` command: Implemented with suggestions
  - Configuration system: User home directory based
  - Model selection: Dynamic model listing and selection
  - AI response parsing: Robust markdown handling

### Recent Additions (v0.2.0)
- User configuration directory (`~/.dart_ment/`)
- Model selection via `--model` flag
- `ment models` command for model management
- `ment config` command for settings management
- Secure API key storage
- AI response parser for handling various formats

When implementing new features, follow the existing command pattern and ensure proper error handling with meaningful exit codes.