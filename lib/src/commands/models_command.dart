import 'dart:io' show Platform;

import 'package:args/command_runner.dart';
import 'package:dart_ment/src/config/config_manager.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template models_command}
/// `ment models` command to list and select AI models.
/// {@endtemplate}
class ModelsCommand extends Command<int> {
  /// {@macro models_command}
  ModelsCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addFlag(
        'list',
        abbr: 'l',
        help: 'List all available models',
        negatable: false,
      )
      ..addFlag(
        'select',
        abbr: 's',
        help: 'Select a model interactively',
        negatable: false,
      )
      ..addOption(
        'set',
        help: 'Set a specific model by ID',
        valueHelp: 'model-id',
      );
  }

  final Logger _logger;

  @override
  String get description => 'List and select AI models for dart_ment.';

  @override
  String get name => 'models';

  @override
  Future<int> run() async {
    final configManager = ConfigManager();
    await configManager.initialize();

    // Get API key
    final apiKeys = await configManager.loadApiKeys();
    final apiKey = apiKeys['gemini_api_key'] ?? 
        Platform.environment['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      _logger.err(
        'Gemini API key not found. Please set it using:\n'
        '  1. ment config set gemini_api_key <your-key>\n'
        '  2. Or set GEMINI_API_KEY environment variable',
      );
      return ExitCode.config.code;
    }

    // Initialize Gemini
    Gemini.init(apiKey: apiKey);

    // Handle different options
    final showList = argResults?['list'] as bool? ?? false;
    final selectMode = argResults?['select'] as bool? ?? false;
    final setModel = argResults?['set'] as String?;

    if (setModel != null) {
      return _setModel(configManager, setModel);
    } else if (selectMode) {
      return _selectModelInteractively(configManager);
    } else if (showList || (!showList && !selectMode && setModel == null)) {
      return _listModels(configManager);
    }

    return ExitCode.success.code;
  }

  Future<int> _listModels(ConfigManager configManager) async {
    final progress = _logger.progress('Fetching available models from Gemini API');
    
    try {
      final models = await Gemini.instance.listModels();
      progress.complete('Found ${models.length} available models');
      
      if (models.isEmpty) {
        _logger.warn('No models available');
        return ExitCode.success.code;
      }

      // Get current model from config
      final config = await configManager.loadConfig();
      final currentModel = config['model'] as String?;

      _logger.info('\nAvailable Gemini Models:');
      _logger.info('------------------------');
      
      for (final model in models) {
        final isSelected = model.name == currentModel || 
            (currentModel != null && model.name?.contains(currentModel) == true);
        final marker = isSelected ? ' ✓' : '  ';
        
        _logger.info('$marker ${_formatModelInfo(model)}');
      }
      
      _logger.info('\nCurrent model: ${currentModel ?? 'gemini-1.5-flash (default)'}');
      _logger.info('\nTo select a model, use: ment models --set <model-id>');
      
      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Failed to fetch models');
      _logger.err('Error: $e');
      return ExitCode.software.code;
    }
  }

  Future<int> _selectModelInteractively(ConfigManager configManager) async {
    final progress = _logger.progress('Fetching available models from Gemini API');
    
    try {
      final models = await Gemini.instance.listModels();
      progress.complete('Found ${models.length} available models');
      
      if (models.isEmpty) {
        _logger.warn('No models available');
        return ExitCode.success.code;
      }

      // Filter to only generative models
      final generativeModels = models.where((m) => 
        m.name?.contains('gemini') == true &&
        m.supportedGenerationMethods?.contains('generateContent') == true
      ).toList();

      if (generativeModels.isEmpty) {
        _logger.warn('No generative models available');
        return ExitCode.success.code;
      }

      // Create choices for selection
      final choices = generativeModels.map((model) {
        final name = model.name ?? 'Unknown';
        final displayName = model.displayName ?? name;
        return '$displayName (${name.replaceAll('models/', '')})';
      }).toList();

      final selection = _logger.chooseOne(
        'Select a model:',
        choices: choices,
        defaultValue: choices.first,
      );

      final selectedIndex = choices.indexOf(selection);
      final selectedModel = generativeModels[selectedIndex];
      final modelId = selectedModel.name?.replaceAll('models/', '') ?? '';

      if (modelId.isEmpty) {
        _logger.err('Invalid model selected');
        return ExitCode.software.code;
      }

      // Save to config
      await configManager.updateConfig('model', modelId);
      _logger.success('Model set to: $modelId');
      
      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Failed to fetch models');
      _logger.err('Error: $e');
      return ExitCode.software.code;
    }
  }

  Future<int> _setModel(ConfigManager configManager, String modelId) async {
    // Normalize model ID (remove 'models/' prefix if present)
    final normalizedId = modelId.replaceAll('models/', '');
    
    // Validate model exists
    final progress = _logger.progress('Validating model');
    
    try {
      final models = await Gemini.instance.listModels();
      final modelExists = models.any((m) => 
        m.name == 'models/$normalizedId' || 
        m.name == normalizedId
      );
      
      if (!modelExists) {
        progress.fail('Model not found: $normalizedId');
        _logger.info('Use "ment models --list" to see available models');
        return ExitCode.config.code;
      }
      
      progress.complete('Model validated');
      
      // Save to config
      await configManager.updateConfig('model', normalizedId);
      _logger.success('Model set to: $normalizedId');
      
      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Failed to validate model');
      _logger.err('Error: $e');
      return ExitCode.software.code;
    }
  }

  String _formatModelInfo(GeminiModel model) {
    final name = model.name?.replaceAll('models/', '') ?? 'Unknown';
    final displayName = model.displayName ?? name;
    
    final details = <String>[];
    
    if (model.version != null) {
      details.add('v${model.version}');
    }
    
    if (model.inputTokenLimit != null) {
      details.add('${model.inputTokenLimit} input tokens');
    }
    
    if (model.outputTokenLimit != null) {
      details.add('${model.outputTokenLimit} output tokens');
    }
    
    final detailsStr = details.isNotEmpty ? ' (${details.join(', ')})' : '';
    
    return '$displayName - $name$detailsStr';
  }
}


