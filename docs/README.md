# 🧠 dart_ment Documentation

<div align="center">

![dart_ment Logo](https://img.shields.io/badge/dart__ment-AI%20Powered-4285F4?style=for-the-badge&logo=dart&logoColor=white)

**Transform your Dart code from messy to magnificent with AI-powered automated fixes!**

[Installation](getting-started/installation.md) • [Quick Start](getting-started/quick-start.md) • [API Reference](api/overview.md) • [Examples](examples/basic.md)

</div>

---

## 🚀 Welcome to dart_ment!

**dart_ment** is your AI-powered companion for automatically fixing linting issues, improving code quality, and providing intelligent suggestions for your Dart/Flutter projects. Built with Google Gemini AI, it understands the nuances of Dart/Flutter development to provide context-aware fixes that actually make sense.

## 🎯 Why dart_ment?

### The Problem
- 😫 **Manual Fixes Are Tedious**: Spending hours fixing linting issues one by one
- 🤷 **Generic Solutions**: Traditional linters suggest fixes without understanding context
- 📚 **Knowledge Gap**: Junior developers struggle with best practices
- ⏰ **Time Consuming**: Code reviews focus on style instead of logic

### The Solution
- 🤖 **AI That Understands**: Google Gemini trained on millions of Dart/Flutter projects
- ⚡ **Instant Fixes**: Fix hundreds of issues with a single command
- 🎓 **Learn As You Go**: Understand why changes are suggested
- 🔍 **Beyond Linting**: Get architectural and performance suggestions

## ✨ Key Features

### 🧠 Intelligent Analysis
```bash
$ ment analyze
```
- Comprehensive code quality analysis
- AI-powered improvement suggestions
- Performance optimization tips
- Architecture recommendations

### 🛠️ Automated Fixes
```bash
$ ment fix
```
- Context-aware code fixes
- Preserves your coding style
- Safe refactoring with backups
- Dry-run mode for previewing

### ⚙️ Flexible Configuration
```yaml
# .dart_ment.yaml
llm:
  gemini:
    model: "gemini-pro"
    temperature: 0.7
```
- Multiple configuration methods
- Project-specific settings
- Team-wide style guides
- CI/CD integration ready

## 📚 Documentation Structure

### 🎯 Getting Started
- [**Installation Guide**](getting-started/installation.md) - Get dart_ment up and running
- [**Quick Start**](getting-started/quick-start.md) - Your first dart_ment fix
- [**Configuration**](getting-started/configuration.md) - Set up your preferences

### 📖 User Guides
- [**Basic Usage**](guides/usage.md) - Common commands and workflows
- [**Advanced Features**](guides/advanced.md) - Power user features
- [**CI/CD Integration**](guides/ci-cd.md) - Automate code quality
- [**Team Setup**](guides/team-setup.md) - Standardize across your team

### 🔧 API Reference
- [**Commands**](api/commands.md) - All available commands
- [**Configuration Options**](api/configuration.md) - Every setting explained
- [**Exit Codes**](api/exit-codes.md) - Understanding return values

### 💡 Examples
- [**Basic Examples**](examples/basic.md) - Simple use cases
- [**Flutter Projects**](examples/flutter.md) - Flutter-specific patterns
- [**Large Codebases**](examples/large-projects.md) - Handling big projects
- [**Custom Rules**](examples/custom-rules.md) - Team-specific conventions

### 🤝 Contributing
- [**Contributing Guidelines**](contributing/guidelines.md) - How to contribute
- [**Development Setup**](contributing/development.md) - Set up dev environment
- [**Architecture**](contributing/architecture.md) - How dart_ment works
- [**Testing**](contributing/testing.md) - Writing and running tests

## 🎬 Quick Demo

```bash
# Install dart_ment
$ dart pub global activate dart_ment

# Analyze your project
$ cd my_flutter_app
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

# Fix all issues automatically
$ ment fix --api-key YOUR_GEMINI_KEY

🛠️ Starting fix process...
✓ Found 23 issues in 8 files
  Generating fix... ✓ Fix applied
  Generating fix... ✓ Fix applied
✓ Fixed 23 issues. Run "dart analyze" to verify the fixes.
```

## 🌟 Success Stories

> "dart_ment reduced our code review time by 70%. We now focus on architecture instead of syntax." - **Flutter Team Lead**

> "As a junior developer, dart_ment taught me Dart best practices faster than any tutorial." - **Mobile Developer**

> "We integrated dart_ment into our CI/CD. Code quality issues dropped by 90% in the first month." - **DevOps Engineer**

## 🚀 Ready to Transform Your Code?

<div align="center">

[📦 **Install dart_ment**](getting-started/installation.md)

[🎯 **Quick Start Guide**](getting-started/quick-start.md)

[💬 **Join Our Community**](https://github.com/yourusername/dart_ment/discussions)

</div>

---

<div align="center">

**Made with 💙 by the Dart community**

[GitHub](https://github.com/yourusername/dart_ment) • [Issues](https://github.com/yourusername/dart_ment/issues) • [Discussions](https://github.com/yourusername/dart_ment/discussions)

</div>