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
  String get description => 'Fix linting issues using AI assistance.\n'
      'Usage: ment fix [path]';

  @override
  String get name => 'fix';

  @override
  String get invocation => '$name [path]';

  @override
  Future<int> run() async {
    // Get the target directory from positional argument or current directory
    final targetPath =
        (argResults?.rest.isNotEmpty ?? false) ? argResults!.rest.first : '.';

    // Resolve the absolute path
    final resolvedPath = path.isAbsolute(targetPath)
        ? targetPath
        : targetPath == '.'
            ? Directory.current.path
            : path.join(Directory.current.path, targetPath);

    // Validate the path exists and is a directory
    final targetDir = Directory(resolvedPath);
    if (!targetDir.existsSync()) {
      _logger.err('Error: Directory not found: $targetPath');
      return ExitCode.usage.code;
    }

    final displayPath = targetPath == '.' ? '.' : path.relative(resolvedPath);
    _logger.info('Starting fix process in $displayPath...');

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
        projectPath: resolvedPath,
      );
      await analyzerService.initialize();

      // Get Dart files
      final progress = _logger.progress('Scanning for Dart files');
      final analysisConfig = config['analysis'] as Map<String, dynamic>?;

      // If we're not analyzing the current directory, don't use config includes
      final useConfigIncludes = targetPath == '.';
      final dartFiles = await analyzerService.getDartFiles(
        includePaths: useConfigIncludes
            ? (analysisConfig?['include'] as List<dynamic>?)?.cast<String>()
            : null,
        excludePaths:
            (analysisConfig?['exclude'] as List<dynamic>?)?.cast<String>(),
      );
      progress.complete('Found ${dartFiles.length} Dart files');

      // Analyze files and collect issues
      var totalIssues = 0;
      final filesWithIssues = <String, List<String>>{};

      Progress? analysisProgress;
      for (var i = 0; i < dartFiles.length; i++) {
        final file = dartFiles[i];
        final relativePath = path.relative(file, from: Directory.current.path);
        final fileNum = i + 1;
        final percentage =
            ((fileNum / dartFiles.length) * 100).toStringAsFixed(1);

        // Update progress with current file info
        analysisProgress?.cancel();
        final truncatedPath = relativePath.length > 50
            ? '...${relativePath.substring(relativePath.length - 47)}'
            : relativePath;
        analysisProgress = _logger.progress(
          'Analyzing files ($fileNum/${dartFiles.length} - $percentage%) '
          '$truncatedPath',
        );

        final errors = await analyzerService.analyzeFile(file);
        if (errors.isNotEmpty) {
          filesWithIssues[file] = errors.map((e) => e.message).toList();
          totalIssues += errors.length;
        }
      }

      analysisProgress?.complete(
        'Found $totalIssues issues in ${filesWithIssues.length} files',
      );

      if (totalIssues == 0) {
        _logger.success('No issues found! Your code is clean.');
        return ExitCode.success.code;
      }

      // Generate and apply fixes
      final isDryRun = argResults?['dry-run'] as bool? ?? false;
      var fixedCount = 0;
      var currentFileNum = 0;
      final totalFiles = filesWithIssues.length;

      for (final entry in filesWithIssues.entries) {
        final filePath = entry.key;
        final issues = entry.value;
        final relativePath =
            path.relative(filePath, from: Directory.current.path);
        currentFileNum++;

        _logger.info(
          '\n📄 Processing file $currentFileNum/$totalFiles: $relativePath '
          '(${issues.length} ${issues.length == 1 ? 'issue' : 'issues'})',
        );

        var fileContent = await analyzerService.getFileContent(filePath);
        var issueNum = 0;

        for (final issue in issues) {
          issueNum++;
          final issueProgress =
              ((issueNum / issues.length) * 100).toStringAsFixed(0);

          _logger.detail('  Issue $issueNum/${issues.length}: $issue');

          final fixProgress = _logger.progress(
            '  Generating fix ($issueProgress% of file)...',
          );
          try {
            final fixedCode = await geminiService.generateFix(
              code: fileContent,
              issue: issue,
              filePath: relativePath,
            );

            if (fixedCode != null && fixedCode.isNotEmpty) {
              fixProgress.complete('  ✓ Fix generated');

              if (isDryRun) {
                _logger.info('  [DRY RUN] Would apply fix');
              } else {
                // Backup original file if configured (only on first fix)
                if (issueNum == 1) {
                  final fixesConfig = config['fixes'] as Map<String, dynamic>?;
                  if (fixesConfig?['backup'] == true) {
                    await File(filePath).copy('$filePath.backup');
                    _logger.detail('  Created backup: $filePath.backup');
                  }
                }

                // Apply fix and update file content for next iteration
                await File(filePath).writeAsString(fixedCode);
                fileContent = fixedCode;
                _logger.success('  ✓ Fix applied');
                fixedCount++;
              }
            } else {
              fixProgress.fail('  ✗ Could not generate fix');
            }
          } catch (e) {
            fixProgress.fail('  ✗ Error: $e');
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
