<div align="center">

# 🧠 dart_ment

### AI-Powered Code Repair & Refactoring for Dart

[![pub package](https://img.shields.io/pub/v/dart_ment.svg?label=pub&color=blue)](https://pub.dev/packages/dart_ment)
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]
[![Powered by Gemini](https://img.shields.io/badge/Powered%20by-Google%20Gemini-4285F4?logo=google&logoColor=white)](https://ai.google.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.5.0-00579d?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)](https://dart.dev/get-dart)

<p align="center">
  <strong>Transform your Dart code from messy to magnificent with AI-powered automated fixes! 🚀</strong>
</p>

<p align="center">
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-demo">Demo</a> •
  <a href="#-features">Features</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-usage">Usage</a> •
  <a href="#-configuration">Configuration</a>
</p>

</div>

---

## 🎯 What is dart_ment?

**dart_ment** is your AI-powered companion that automatically fixes linting issues, improves code quality, and provides intelligent suggestions for your Dart/Flutter projects. Think of it as having a senior Dart developer reviewing and fixing your code 24/7!

### 🤔 Why dart_ment?

- **Save Hours**: Stop manually fixing repetitive linting issues
- **Learn Best Practices**: Get AI-powered suggestions based on Dart/Flutter guidelines
- **Improve Code Quality**: Maintain consistent, clean code across your project
- **Boost Productivity**: Focus on features, not formatting

## 📸 Demo

```bash
$ ment analyze

🔍 Starting code analysis...
✓ Found 142 Dart files
✓ Analysis complete: 23 issues, 47 suggestions

📄 lib/src/user_service.dart
  Issues (3):
    ❌ Missing type annotation for 'data'
    ❌ Avoid using 'dynamic' as a type
    ❌ Prefer const constructors
  Suggestions (2):
    💡 Consider using a more specific return type
    💡 Extract this logic into a separate method

$ ment fix

🛠️ Starting fix process...
✓ Found 23 issues in 8 files
  Generating fix... ✓ Fix applied
  Generating fix... ✓ Fix applied
✓ Fixed 23 issues. Run "dart analyze" to verify the fixes.
```

## ✨ Features

<table>
<tr>
<td>

### 🤖 AI-Powered Intelligence
Leverages Google Gemini's understanding of Dart/Flutter to provide context-aware fixes

</td>
<td>

### 🔍 Deep Code Analysis
Comprehensive static analysis that catches issues `dart analyze` might miss

</td>
</tr>
<tr>
<td>

### 🛡️ Safe Refactoring
Preview changes with `--dry-run` before applying them to your codebase

</td>
<td>

### ⚡ Lightning Fast
Analyzes and fixes hundreds of files in seconds with smart token optimization

</td>
</tr>
<tr>
<td>

### 🎨 Style Consistency
Enforces consistent code style across your entire project

</td>
<td>

### 📊 Smart Suggestions
Get improvement recommendations beyond just linting fixes

</td>
</tr>
<tr>
<td>

### 📁 Flexible Targeting
Analyze and fix specific directories without changing your working directory

</td>
<td>

### 💰 Token Efficient
Only analyzes files with errors by default, saving API costs

</td>
</tr>
</table>

## 🚀 Quick Start

```bash
# 1. Install dart_ment globally
dart pub global activate dart_ment

# 2. Get your Gemini API key (free)
# Visit: https://makersuite.google.com/app/apikey

# 3. Run in your Dart/Flutter project
cd your_project
ment fix --api-key YOUR_GEMINI_API_KEY

# That's it! 🎉
```

## 📦 Installation

### Prerequisites

- Dart SDK `>=3.5.0`
- A Google Gemini API key ([Get one free](https://makersuite.google.com/app/apikey))

### Global Installation (Recommended)

```bash
dart pub global activate dart_ment
```

### Add to Project

```yaml
dev_dependencies:
  dart_ment: ^0.2.0
```

## 💻 Usage

### 🔍 Analyze Your Code

Get a comprehensive analysis of your codebase with AI-powered suggestions:

```bash
# Basic analysis
ment analyze

# Analyze a specific directory
ment analyze lib/src
ment analyze example

# With custom configuration
ment analyze --config analysis_config.yaml

# Disable AI suggestions (faster)
ment analyze --no-suggestions

# Analyze all files with AI (including files without errors)
ment analyze --all-files
```

### 🛠️ Fix Issues Automatically

Let AI fix your linting issues intelligently:

```bash
# Fix with API key as parameter
ment fix --api-key YOUR_KEY

# Fix issues in a specific directory
ment fix lib
ment fix test

# Fix with environment variable
export GEMINI_API_KEY=YOUR_KEY
ment fix

# Preview fixes without applying
ment fix --dry-run

# Select a different AI model
ment fix --model gemini-1.5-pro

# Set maximum fix iterations (default: 3)
ment fix --max-iterations 5
```

### 🤖 Manage AI Models

List and select from available Gemini models:

```bash
# List all available models
ment models --list

# Select a model interactively
ment models --select

# Set a specific model
ment models --set gemini-1.5-pro
```

### ⚙️ Configuration Management

Manage your dart_ment configuration:

```bash
# Show current configuration
ment config show

# Set configuration values
ment config set model gemini-1.5-flash

# Show configuration file paths
ment config path
```

### 🔄 Update dart_ment

Keep dart_ment up to date with the latest improvements:

```bash
ment update
```

## ⚙️ Configuration

dart_ment stores configuration in your home directory at `~/.dart_ment/` for easy access across all projects.

### 1. API Key Setup

Set your Gemini API key using one of these methods:

```bash
# Option 1: Using config command (stored securely)
ment config set gemini_api_key YOUR_API_KEY

# Option 2: Environment variable
export GEMINI_API_KEY=your_api_key_here

# Option 3: Edit ~/.dart_ment/api_keys.yaml directly
```

### 2. Configuration File

Configuration is stored at `~/.dart_ment/config.yaml`:

```yaml
# Default AI model
model: gemini-1.5-flash

# Analysis Settings
analysis:
  include:
    - lib/**/*.dart
    - bin/**/*.dart
    - test/**/*.dart
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

# Fix Settings
fixes:
  backup: true          # Create .backup files
  interactive: false    # Auto-apply fixes
  max_suggestions: 3    # Suggestions per issue
```

### 3. Command Line Flags

```bash
ment fix \
  --api-key YOUR_KEY \
  --config custom_config.yaml \
  --dry-run
```

## 🎯 When to Use dart_ment

### Perfect for:

- 📱 **Flutter Projects**: Optimized for Flutter-specific patterns
- 🏢 **Large Codebases**: Fix hundreds of files in one command
- 👥 **Team Projects**: Enforce consistent code style
- 🎓 **Learning**: Understand why fixes are suggested
- ⏰ **CI/CD Pipelines**: Automated code quality checks

### Use Cases:

1. **Before Code Reviews**: Clean up your code automatically
2. **Legacy Code**: Modernize old Dart code to current standards
3. **After Major Refactoring**: Ensure consistency across changes
4. **New Team Members**: Help them follow project conventions

## 🤝 Contributing

We love contributions! See our [Contributing Guide](CONTRIBUTING.md) for details.

```bash
# Clone the repo
git clone https://github.com/yourusername/dart_ment.git

# Install dependencies
dart pub get

# Run tests
dart test

# Make your changes and submit a PR!
```

### 🚀 Releasing

New releases are automatically created when version tags are pushed:

```bash
# Tag a new version
git tag v0.1.0
git push origin v0.1.0
```

This will automatically:
- Create a GitHub release with changelog
- Publish to pub.dev (if credentials are configured)

See [.github/workflows/README.md](.github/workflows/README.md) for details.

## 📊 Roadmap

- [ ] VS Code Extension
- [ ] Custom Lint Rules
- [ ] Team Style Guides
- [ ] Local LLM Support
- [ ] Fix History & Rollback
- [ ] Performance Metrics

## 🙏 Acknowledgments

<div align="center">
<table>
<tr>
<td align="center">
<a href="https://cli.vgv.dev">
<img src="https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_brand/main/styles/README/vgv_logo_dark.png#gh-dark-mode-only" width="100">
<img src="https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_brand/main/styles/README/vgv_logo_light.png#gh-light-mode-only" width="100">
<br>Very Good CLI
</a>
</td>
<td align="center">
<a href="https://ai.google.dev">
<img src="https://www.gstatic.com/lamda/images/gemini_logo_background_card_2920a0581b779f69e327.svg" width="100">
<br>Google Gemini
</a>
</td>
<td align="center">
<a href="https://dart.dev">
<img src="https://dart.dev/assets/img/shared/dart/logo+text/horizontal/white.svg#gh-dark-mode-only" width="100">
<img src="https://dart.dev/assets/img/shared/dart/logo+text/horizontal/default.svg#gh-light-mode-only" width="100">
<br>Dart
</a>
</td>
</tr>
</table>
</div>

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Made with 💙 by the Dart community**

[Report Bug](https://github.com/moinsen-dev/dart_ment/issues) • [Request Feature](https://github.com/moinsen-dev/dart_ment/issues)

</div>

[coverage_badge]: coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
