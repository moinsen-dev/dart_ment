import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_ment/src/config/config_manager.dart';
import 'package:dart_ment/src/models/ai_models.dart';
import 'package:dart_ment/src/services/analyzer_service.dart';
import 'package:dart_ment/src/services/gemini_service.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

/// {@template fix_command}
/// `ment fix` command that fixes linting issues using AI.
/// {@endtemplate}
class FixCommand extends Command<int> {
  /// {@macro fix_command}
  FixCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Path to configuration file',
      )
      ..addOption(
        'api-key',
        help: 'Google Gemini API key',
      )
      ..addOption(
        'model',
        abbr: 'm',
        help: 'AI model to use for fixes',
        defaultsTo: 'gemini-1.5-flash',
        allowed: AIModel.availableModels
            .where((m) => m.isSupported)
            .map((m) => m.id)
            .toList(),
      )
      ..addFlag(
        'dry-run',
        help: 'Show fixes without applying them',
        negatable: false,
      );
  }

  final Logger _logger;

  @override
  String get description => 'Fix linting issues using AI assistance.';

  @override
  String get name => 'fix';

  @override
  Future<int> run() async {
    _logger.info('Starting fix process...');

    try {
      // Initialize config manager
      final configManager = ConfigManager();
      await configManager.initialize();
      
      // Load configurations
      final config = await configManager.loadConfig();
      final apiKeys = await configManager.loadApiKeys();
      
      // Get model selection
      final modelId = argResults?['model'] as String? ?? 
          config['model'] as String? ?? 
          AIModel.gemini15Flash.id;
      final model = AIModel.fromId(modelId);
      
      if (model == null || !model.isSupported) {
        _logger.err('Unsupported model: $modelId');
        _logger.info('Available models:');
        for (final m in AIModel.availableModels.where((m) => m.isSupported)) {
          _logger.info('  - ${m.id}: ${m.description}');
        }
        return ExitCode.config.code;
      }
      
      // Get API key
      final apiKey = argResults?['api-key'] as String? ??
          apiKeys[model.apiKeyName] ??
          Platform.environment['GEMINI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        _logger.err(
          'API key not found. Please provide it via:\n'
          '  1. --api-key flag\n'
          '  2. ${configManager.apiKeysFile.path}\n'
          '  3. GEMINI_API_KEY environment variable',
        );
        return ExitCode.config.code;
      }

      // Initialize services
      final geminiService = GeminiService(apiKey: apiKey, model: model)
        ..initialize();
      
      _logger.info('Using model: ${model.name}');

      final analyzerService = AnalyzerService(
        projectPath: Directory.current.path,
      );
      await analyzerService.initialize();

      // Get Dart files
      final progress = _logger.progress('Scanning for Dart files');
      final analysisConfig = config['analysis'] as Map<String, dynamic>?;
      final dartFiles = await analyzerService.getDartFiles(
        includePaths:
            (analysisConfig?['include'] as List<dynamic>?)?.cast<String>(),
        excludePaths:
            (analysisConfig?['exclude'] as List<dynamic>?)?.cast<String>(),
      );
      progress.complete('Found ${dartFiles.length} Dart files');

      // Analyze files and collect issues
      var totalIssues = 0;
      final filesWithIssues = <String, List<String>>{};

      final analysisProgress = _logger.progress('Analyzing files');
      for (final file in dartFiles) {
        final errors = await analyzerService.analyzeFile(file);
        if (errors.isNotEmpty) {
          filesWithIssues[file] = errors.map((e) => e.message).toList();
          totalIssues += errors.length;
        }
      }
      analysisProgress.complete(
        'Found $totalIssues issues in ${filesWithIssues.length} files',
      );

      if (totalIssues == 0) {
        _logger.success('No issues found! Your code is clean.');
        return ExitCode.success.code;
      }

      // Generate and apply fixes
      final isDryRun = argResults?['dry-run'] as bool? ?? false;
      var fixedCount = 0;

      for (final entry in filesWithIssues.entries) {
        final filePath = entry.key;
        final issues = entry.value;
        final relativePath = path.relative(filePath);

        _logger.info('\nProcessing $relativePath (${issues.length} issues)');

        final fileContent = await analyzerService.getFileContent(filePath);

        for (final issue in issues) {
          _logger.detail('  Issue: $issue');

          final fixProgress = _logger.progress('  Generating fix...');
          try {
            final fixedCode = await geminiService.generateFix(
              code: fileContent,
              issue: issue,
              filePath: relativePath,
            );

            if (fixedCode != null && fixedCode.isNotEmpty) {
              fixProgress.complete('  Fix generated');

              if (isDryRun) {
                _logger.info('  [DRY RUN] Would apply fix');
              } else {
                // Backup original file if configured
                final fixesConfig = config['fixes'] as Map<String, dynamic>?;
                if (fixesConfig?['backup'] == true) {
                  await File(filePath).copy('$filePath.backup');
                }

                // Apply fix
                await File(filePath).writeAsString(fixedCode);
                _logger.success('  Fix applied');
                fixedCount++;
              }
            } else {
              fixProgress.fail('  Could not generate fix');
            }
          } catch (e) {
            fixProgress.fail('  Error: $e');
          }
        }
      }

      if (isDryRun) {
        _logger.info('\nDry run completed. No files were modified.');
      } else {
        _logger.success(
          '\nFixed $fixedCount issues. '
          'Run "dart analyze" to verify the fixes.',
        );
      }

      return ExitCode.success.code;
    } catch (e) {
      _logger.err('Error while applying fixes: $e');
      return ExitCode.software.code;
    }
  }

}
