# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-05-29

### 🎉 First Official Release

This marks the first stable release of dart_ment, an AI-powered automated code repair and refactoring tool for Dart projects.

### Features

- **AI-Powered Code Analysis**: Analyze Dart code quality with AI-powered suggestions using Google Gemini
- **Automated Code Fixes**: Automatically fix linting issues with iterative AI-powered repairs
- **Model Selection**: Support for different Gemini AI models with interactive selection
- **User Configuration**: Home directory configuration with secure API key storage
- **Folder Targeting**: Analyze and fix specific directories or entire projects
- **Progress Reporting**: Enhanced progress indicators with file-by-file status
- **Iterative Fixing**: Intelligent multi-pass fixing to resolve all issues
- **Code Formatting**: Automatic code formatting after fixes

### Commands

- `ment analyze` - Analyze code quality with optional AI suggestions and automatic fixes
- `ment fix` - Fix linting issues using AI with configurable iterations
- `ment models` - List and select available AI models
- `ment config` - Manage configuration settings and API keys
- `ment update` - Check for CLI updates

### Configuration

- User configuration stored in `~/.dart_ment/`
- Secure API key storage with proper file permissions
- Configurable AI models and settings
- Support for multiple AI providers (extensible architecture)

### Installation

```bash
dart pub global activate dart_ment
```

### Usage

```bash
# Analyze your project
ment analyze

# Fix issues automatically
ment fix

# Configure API key
ment config --set-api-key YOUR_GEMINI_API_KEY
```