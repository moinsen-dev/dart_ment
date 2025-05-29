import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Manages dart_ment configuration files
class ConfigManager {
  ConfigManager() {
    final homeDir = _getHomeDirectory();
    configDir = Directory(path.join(homeDir.path, configDirName));
    configFile = File(path.join(configDir.path, configFileName));
    apiKeysFile = File(path.join(configDir.path, apiKeysFileName));
  }
  static const String configDirName = '.dart_ment';
  static const String configFileName = 'config.yaml';
  static const String apiKeysFileName = 'api_keys.yaml';

  late final Directory configDir;
  late final File configFile;
  late final File apiKeysFile;

  /// Get the user's home directory
  Directory _getHomeDirectory() {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) {
      throw Exception('Could not determine home directory');
    }
    return Directory(home);
  }

  /// Initialize configuration directory and files
  Future<void> initialize() async {
    // Create config directory if it doesn't exist
    if (!configDir.existsSync()) {
      await configDir.create(recursive: true);
    }

    // Create default config file if it doesn't exist
    if (!configFile.existsSync()) {
      await _createDefaultConfig();
    }

    // Create API keys file if it doesn't exist
    if (!apiKeysFile.existsSync()) {
      await _createDefaultApiKeysFile();
    }
  }

  /// Create default configuration file
  Future<void> _createDefaultConfig() async {
    const defaultConfig = '''
# dart_ment configuration file
# This file stores your preferences for dart_ment

# Default AI model to use
model: gemini-1.5-flash

# Analysis settings
analysis:
  include:
    - "lib/**/*.dart"
    - "bin/**/*.dart"
    - "test/**/*.dart"
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

# Fix settings
fixes:
  # Create backup files before applying fixes
  backup: false
  # Maximum fixes to apply in a single run
  max_fixes: 100

# Output settings
output:
  # Verbosity level: quiet, normal, verbose
  verbosity: normal
  # Show progress indicators
  show_progress: true
''';

    await configFile.writeAsString(defaultConfig);
  }

  /// Create default API keys file
  Future<void> _createDefaultApiKeysFile() async {
    const defaultApiKeys = '''
# API Keys for dart_ment
# IMPORTANT: Keep this file secure and do not commit to version control

# Google Gemini API Key
# Get your key from: https://makersuite.google.com/app/apikey
gemini_api_key: ""

# OpenAI API Key (future support)
# Get your key from: https://platform.openai.com/api-keys
openai_api_key: ""

# Anthropic API Key (future support)
# Get your key from: https://console.anthropic.com/
anthropic_api_key: ""
''';

    await apiKeysFile.writeAsString(defaultApiKeys);

    // Set restrictive permissions on API keys file (Unix-like systems only)
    if (Platform.isLinux || Platform.isMacOS) {
      await Process.run('chmod', ['600', apiKeysFile.path]);
    }
  }

  /// Load configuration from file
  Future<Map<String, dynamic>> loadConfig() async {
    if (!configFile.existsSync()) {
      await initialize();
    }

    final content = await configFile.readAsString();
    final yaml = loadYaml(content);
    return yaml is Map ? _convertYamlToMap(yaml) : {};
  }

  /// Load API keys from secure file
  Future<Map<String, String>> loadApiKeys() async {
    if (!apiKeysFile.existsSync()) {
      await initialize();
    }

    final content = await apiKeysFile.readAsString();
    final yaml = loadYaml(content);

    if (yaml is! Map) return {};

    final keys = <String, String>{};
    yaml.forEach((key, value) {
      if (value is String && value.isNotEmpty) {
        keys[key.toString()] = value;
      }
    });

    return keys;
  }

  /// Update configuration value
  Future<void> updateConfig(String key, dynamic value) async {
    final config = await loadConfig();
    _updateNestedMap(config, key.split('.'), value);

    // Convert to YAML and write
    final yamlString = _mapToYamlString(config);
    await configFile.writeAsString(yamlString);
  }

  /// Update API key
  Future<void> updateApiKey(String keyName, String value) async {
    final keys = await loadApiKeys();
    keys[keyName] = value;

    // Build YAML content with comments preserved
    final lines = <String>[];
    lines.add('# API Keys for dart_ment');
    lines.add(
      '# IMPORTANT: Keep this file secure and do not commit to version control',
    );
    lines.add('');

    if (keys.containsKey('gemini_api_key')) {
      lines.add('# Google Gemini API Key');
      lines
          .add('# Get your key from: https://makersuite.google.com/app/apikey');
      lines.add('gemini_api_key: "${keys['gemini_api_key']}"');
      lines.add('');
    }

    if (keys.containsKey('openai_api_key')) {
      lines.add('# OpenAI API Key (future support)');
      lines.add('# Get your key from: https://platform.openai.com/api-keys');
      lines.add('openai_api_key: "${keys['openai_api_key']}"');
      lines.add('');
    }

    if (keys.containsKey('anthropic_api_key')) {
      lines.add('# Anthropic API Key (future support)');
      lines.add('# Get your key from: https://console.anthropic.com/');
      lines.add('anthropic_api_key: "${keys['anthropic_api_key']}"');
    }

    await apiKeysFile.writeAsString(lines.join('\n'));
  }

  /// Get the path to the config directory
  String get configPath => configDir.path;

  /// Update nested map with dot notation key
  void _updateNestedMap(
    Map<String, dynamic> map,
    List<String> keys,
    dynamic value,
  ) {
    if (keys.isEmpty) return;

    if (keys.length == 1) {
      map[keys.first] = value;
      return;
    }

    final firstKey = keys.first;
    if (!map.containsKey(firstKey) || map[firstKey] is! Map) {
      map[firstKey] = <String, dynamic>{};
    }

    _updateNestedMap(
      map[firstKey] as Map<String, dynamic>,
      keys.sublist(1),
      value,
    );
  }

  /// Convert map to YAML string with proper formatting
  String _mapToYamlString(Map<String, dynamic> map) {
    final buffer = StringBuffer();
    buffer.writeln('# dart_ment configuration file');
    buffer.writeln('# This file stores your preferences for dart_ment');
    buffer.writeln();

    _writeYamlMap(buffer, map, 0);
    return buffer.toString();
  }

  void _writeYamlMap(
    StringBuffer buffer,
    Map<String, dynamic> map,
    int indent,
  ) {
    final indentStr = ' ' * indent;

    map.forEach((key, value) {
      if (value is Map) {
        buffer.writeln('$indentStr$key:');
        _writeYamlMap(buffer, value as Map<String, dynamic>, indent + 2);
      } else if (value is List) {
        buffer.writeln('$indentStr$key:');
        for (final item in value) {
          // Quote strings that start with special YAML characters
          final quotedItem = _quoteYamlString(item.toString());
          buffer.writeln('$indentStr  - $quotedItem');
        }
      } else {
        // Quote strings if needed
        final quotedValue = value is String ? _quoteYamlString(value) : value;
        buffer.writeln('$indentStr$key: $quotedValue');
      }
    });
  }

  /// Quote YAML string if it contains special characters
  String _quoteYamlString(String value) {
    // Check if string needs quoting
    if (value.contains('*') ||
        value.contains('&') ||
        value.contains('!') ||
        value.contains('[') ||
        value.contains(']') ||
        value.contains('{') ||
        value.contains('}') ||
        value.contains(':') ||
        value.contains(',') ||
        value.contains('>') ||
        value.contains('|') ||
        value.contains('?') ||
        value.contains('@') ||
        value.contains('`') ||
        value.contains('"') ||
        value.contains("'") ||
        value.trim() != value ||
        value.isEmpty) {
      // Use double quotes and escape any double quotes in the string
      return '"${value.replaceAll('"', r'\"')}"';
    }
    return value;
  }

  /// Convert YamlMap to regular Map recursively
  Map<String, dynamic> _convertYamlToMap(dynamic yaml) {
    if (yaml is Map) {
      final map = <String, dynamic>{};
      yaml.forEach((key, value) {
        if (value is Map) {
          map[key.toString()] = _convertYamlToMap(value);
        } else if (value is List) {
          map[key.toString()] = value.map((item) {
            if (item is Map) {
              return _convertYamlToMap(item);
            }
            return item;
          }).toList();
        } else {
          map[key.toString()] = value;
        }
      });
      return map;
    }
    return {};
  }
}
