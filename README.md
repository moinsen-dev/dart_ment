# dart_ment

[![pub package](https://img.shields.io/pub/v/dart_ment.svg)](https://pub.dev/packages/dart_ment)
![coverage][coverage_badge]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

An intelligent automated error-fixing system for Dart projects, powered by LLM technology.

## Overview 🎯

dart_ment is an ambitious project that aims to automate the process of fixing common Dart code issues and enforcing coding standards. It leverages both cloud-based (OpenAI) and local (llama-cpp) Language Learning Models to analyze linter outputs and automatically generate fixes.

### Key Features (Planned) 🚀

- Automated analysis and fixing of Dart linter warnings and errors
- Support for both cloud-based (OpenAI) and local (llama-cpp) LLM processing
- JSON-based transformation rules for code modifications
- CI/CD pipeline integration
- Iterative refinement of fixes with feedback loop
- Backup and logging of all code changes

## Project Status 🏗️

Current development status:
- 🟢 Project specification and planning
- 🟡 Core architecture design and initial setup
- 🟡 Basic package structure on pub.dev
- 🔴 Core components implementation
- 🔴 Integration and testing
- 🔴 Documentation

See our [SPEC.md](SPEC.md) for detailed implementation plans.

### How You Can Help 🤝

We're looking for contributors interested in:

- Core development
- Testing and feedback
- Documentation
- Use case suggestions
- Integration ideas
- Performance optimization

## Installation 📦

```sh
dart pub add dart_ment
```

Or add it to your `pubspec.yaml`:

```yaml
dependencies:
  dart_ment: ^0.0.1
```

## Development Setup 💻

To contribute or test locally:

```sh
# Clone the repository
git clone https://github.com/yourusername/dart_ment

# Install dependencies
dart pub get

# Run tests
dart test
```

For local development:

```sh
# Activate locally
dart pub global activate --source=path <path to this package>

# Run the CLI (when implemented)
dart_ment --help
```

## Running Tests 🧪

To run all unit tests:

```sh
$ dart pub global activate coverage 1.2.0
$ dart test --coverage=coverage
$ dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov):

```sh
# Generate Coverage Report
$ genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
$ open coverage/index.html
```

## Contributing 🤝

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details. Here are some ways you can help:

- Report bugs and suggest features
- Submit Pull Requests
- Improve documentation
- Share your ideas and use cases
- Help with testing

## Roadmap 🗺️

See our [SPEC.md](SPEC.md) for detailed implementation plans and future directions.

## Contact 📬

- Create an issue for bug reports or feature requests
- Start a discussion for general questions
- Join our community (coming soon)

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

[coverage_badge]: coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis