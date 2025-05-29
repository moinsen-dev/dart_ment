# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

dart_ment is an AI-powered automated code repair and refactoring CLI tool for Dart projects. It analyzes Dart code for linting issues and uses AI to automatically fix them.

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
- `ment fix` - Main command to fix linting issues using AI (TODO: not yet implemented)
- `ment analyze` - Analyze code quality metrics (TODO: not yet implemented)
- `ment sample` - Sample command from template
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

According to SPEC.md, the project is in early stages:
- Phase 1 (Setup): Complete
- Phase 2 (Architecture): 40% complete
- Main `fix` and `analyze` commands are not yet implemented

When implementing new features, follow the existing command pattern and ensure proper error handling with meaningful exit codes.