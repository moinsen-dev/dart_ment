import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_ment/src/config/config_manager.dart';
import 'package:dart_ment/src/models/ai_models.dart';
import 'package:dart_ment/src/services/analyzer_service.dart';
import 'package:dart_ment/src/services/gemini_service.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

/// {@template analyze_command}
/// `ment analyze` command that analyzes code quality and suggests improvements.
/// {@endtemplate}
class AnalyzeCommand extends Command<int> {
  /// {@macro analyze_command}
  AnalyzeCommand({
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
        help: 'AI model to use for analysis',
        defaultsTo: 'gemini-1.5-flash',
        allowed: AIModel.availableModels
            .where((m) => m.isSupported)
            .map((m) => m.id)
            .toList(),
      )
      ..addFlag(
        'suggestions',
        abbr: 's',
        help: 'Generate AI-powered improvement suggestions',
        defaultsTo: true,
      )
      ..addFlag(
        'all-files',
        help:
            'Generate AI suggestions for all files, not just those with issues',
        negatable: false,
      )
      ..addFlag(
        'apply-fixes',
        help: 'Automatically apply fixes for found issues after analysis',
        negatable: false,
      );
  }

  final Logger _logger;

  @override
  String get description => 'Analyze code quality and suggest improvements.\n'
      'Usage: ment analyze [path]';

  @override
  String get name => 'analyze';

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
    _logger.info('Starting code analysis in $displayPath...');

    try {
      // Initialize config manager
      final configManager = ConfigManager();
      await configManager.initialize();

      // Load configurations
      final config = await configManager.loadConfig();
      final apiKeys = await configManager.loadApiKeys();

      final shouldGenerateSuggestions =
          argResults?['suggestions'] as bool? ?? true;
      final analyzeAllFiles = argResults?['all-files'] as bool? ?? false;

      GeminiService? geminiService;
      if (shouldGenerateSuggestions) {
        // Get model selection
        final modelId = argResults?['model'] as String? ??
            config['model'] as String? ??
            AIModel.gemini15Flash.id;
        final model = AIModel.fromId(modelId);

        // Get API key
        final apiKey = argResults?['api-key'] as String? ??
            apiKeys['gemini_api_key'] ??
            Platform.environment['GEMINI_API_KEY'];

        if (apiKey != null && apiKey.isNotEmpty) {
          geminiService = GeminiService(apiKey: apiKey, model: model)
            ..initialize();
          _logger
            ..detail('Using model: ${model?.name ?? modelId}')
            ..detail('API key loaded successfully');
        } else {
          _logger.warn(
            'API key not found. Skipping AI-powered suggestions.\n'
            'Set your API key using one of these methods:\n'
            '  1. ment config set gemini_api_key <your-key>\n'
            '  2. --api-key flag\n'
            '  3. GEMINI_API_KEY environment variable',
          );
        }
      }

      // Initialize analyzer with the target directory
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

      // Phase 1: Run Dart analyzer on all files
      var totalIssues = 0;
      final filesWithIssues = <String, List<String>>{};
      final fileErrors = <String, List<dynamic>>{};

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
          fileErrors[file] = errors;
          totalIssues += errors.length;
        }
      }

      analysisProgress?.complete(
        'Found $totalIssues issues in ${filesWithIssues.length} files',
      );

      // Phase 2: Get AI suggestions (if enabled)
      var totalSuggestions = 0;
      final results = <_AnalysisResult>[];

      if (geminiService != null && shouldGenerateSuggestions) {
        // Determine which files to analyze with AI
        final filesToAnalyze =
            analyzeAllFiles ? dartFiles : filesWithIssues.keys.toList();

        if (filesToAnalyze.isNotEmpty) {
          _logger.info('');
          Progress? suggestionProgress;
          var fileNum = 0;

          for (final file in filesToAnalyze) {
            final relativePath =
                path.relative(file, from: Directory.current.path);
            final issues = filesWithIssues[file] ?? [];
            fileNum++;
            final percentage =
                ((fileNum / filesToAnalyze.length) * 100).toStringAsFixed(1);

            suggestionProgress?.cancel();
            final truncatedPath = relativePath.length > 40
                ? '...${relativePath.substring(relativePath.length - 37)}'
                : relativePath;
            suggestionProgress = _logger.progress(
              'Getting AI suggestions ($fileNum/${filesToAnalyze.length} - '
              '$percentage%) $truncatedPath',
            );

            final suggestions = <String>[];
            try {
              final fileContent = await analyzerService.getFileContent(file);
              final aiSuggestions = await geminiService.analyzeCode(
                code: fileContent,
                filePath: relativePath,
              );
              suggestions.addAll(aiSuggestions);
              totalSuggestions += suggestions.length;
            } catch (e) {
              _logger.detail(
                'Could not generate suggestions for $relativePath: $e',
              );
            }

            // Only add to results if there are issues or suggestions
            if (issues.isNotEmpty || suggestions.isNotEmpty) {
              results.add(
                _AnalysisResult(
                  filePath: relativePath,
                  errors: issues,
                  suggestions: suggestions,
                ),
              );
            }
          }

          suggestionProgress?.complete(
            'Generated $totalSuggestions suggestions',
          );
        } else if (filesWithIssues.isNotEmpty && !analyzeAllFiles) {
          // We have files with issues but AI is disabled for clean files
          _logger.info(
            '\nSkipping AI suggestions for ${dartFiles.length - filesWithIssues.length} '
            'files without issues (use --all-files to analyze all)',
          );
        }
      } else {
        // No AI suggestions - just add error results
        for (final entry in filesWithIssues.entries) {
          final file = entry.key;
          final issues = entry.value;
          final relativePath =
              path.relative(file, from: Directory.current.path);

          results.add(
            _AnalysisResult(
              filePath: relativePath,
              errors: issues,
              suggestions: [],
            ),
          );
        }
      }

      // Present results
      if (results.isEmpty) {
        _logger.success('\nExcellent! No issues or suggestions found.');
      } else {
        _logger.info('\n📊 Analysis Results:\n');

        for (final result in results) {
          _logger.info('📄 ${result.filePath}');

          if (result.errors.isNotEmpty) {
            _logger.warn('  Issues (${result.errors.length}):');
            for (final error in result.errors) {
              _logger.err('    ❌ $error');
            }
          }

          if (result.suggestions.isNotEmpty) {
            _logger.info('  Suggestions (${result.suggestions.length}):');
            for (final suggestion in result.suggestions) {
              _logger.detail('    💡 $suggestion');
            }
          }

          _logger.write('');
        }

        _logger
          ..info('Summary:')
          ..info('  Files analyzed: ${dartFiles.length}')
          ..info('  Files with findings: ${results.length}')
          ..err('  Total issues: $totalIssues')
          ..detail('  Total suggestions: $totalSuggestions');

        if (totalIssues > 0) {
          final shouldApplyFixes = argResults?['apply-fixes'] as bool? ?? false;
          
          if (shouldApplyFixes) {
            if (geminiService == null) {
              _logger.err(
                '\nCannot apply fixes: AI service not initialized. '
                'Please provide an API key.',
              );
            } else {
              _logger.info('\n🛠️  Applying fixes...');
              await _applyFixes(
                filesWithIssues: filesWithIssues,
                fileErrors: fileErrors,
                geminiService: geminiService,
                analyzerService: analyzerService,
                resolvedPath: resolvedPath,
              );
            }
          } else {
            _logger.info(
              '\nRun "ment fix" to automatically fix these issues.',
            );
          }
        }
      }

      return ExitCode.success.code;
    } catch (e) {
      _logger.err('Error during analysis: $e');
      return ExitCode.software.code;
    }
  }
  /// Apply fixes to files with issues
  Future<void> _applyFixes({
    required Map<String, List<String>> filesWithIssues,
    required Map<String, List<dynamic>> fileErrors,
    required GeminiService geminiService,
    required AnalyzerService analyzerService,
    required String resolvedPath,
  }) async {
    const maxIterations = 3;
    var totalFixedCount = 0;
    var currentFileNum = 0;
    final totalFiles = filesWithIssues.length;
    
    // Create DartFormatter instance
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    for (final entry in filesWithIssues.entries) {
      final filePath = entry.key;
      final relativePath =
          path.relative(filePath, from: Directory.current.path);
      currentFileNum++;

      _logger.info(
        '\n📄 Fixing file $currentFileNum/$totalFiles: $relativePath',
      );

      // Iterate up to maxIterations to fix all issues
      var fileContent = await analyzerService.getFileContent(filePath);
      var iteration = 0;
      var hasRemainingIssues = true;

      while (hasRemainingIssues && iteration < maxIterations) {
        iteration++;
        
        // Re-analyze the file to get current issues
        final currentErrors = await analyzerService.analyzeFile(filePath);
        if (currentErrors.isEmpty) {
          hasRemainingIssues = false;
          if (iteration > 1) {
            _logger.success('  ✓ All issues fixed after $iteration iterations');
          } else {
            _logger.success('  ✓ All issues fixed');
          }
          break;
        }

        final issues = currentErrors.map((e) => e.message).toList();
        if (iteration > 1) {
          _logger.info(
            '  Iteration $iteration/$maxIterations: '
            '${issues.length} ${issues.length == 1 ? 'issue' : 'issues'} remaining',
          );
        }

        var fixedInIteration = 0;

        for (final issue in issues) {
          final fixProgress = _logger.progress(
            '  Generating fix...',
          );
          try {
            final fixedCode = await geminiService.generateFix(
              code: fileContent,
              issue: issue,
              filePath: relativePath,
            );

            if (fixedCode != null && fixedCode.isNotEmpty) {
              fixProgress.complete('  ✓ Fix generated');
              // Apply fix and update file content for next iteration
              fileContent = fixedCode;
              fixedInIteration++;
              totalFixedCount++;
            } else {
              fixProgress.fail('  ✗ Could not generate fix');
            }
          } catch (e) {
            fixProgress.fail('  ✗ Error: $e');
          }
        }

        // Write the updated content after all fixes in this iteration
        if (fixedInIteration > 0) {
          try {
            // Format the code before writing
            final formattedCode = formatter.format(fileContent);
            await File(filePath).writeAsString(formattedCode);
            fileContent = formattedCode;
          } catch (e) {
            // If formatting fails, save without formatting
            await File(filePath).writeAsString(fileContent);
            _logger.detail('  ⚠️  Could not format code: $e');
          }
        }

        // If no fixes were applied in this iteration, stop trying
        if (fixedInIteration == 0) {
          _logger.warn(
            '  ⚠️  Could not fix remaining issues',
          );
          hasRemainingIssues = false;
        }
      }

      // Final check if we hit max iterations
      if (hasRemainingIssues && iteration >= maxIterations) {
        final remainingErrors = await analyzerService.analyzeFile(filePath);
        if (remainingErrors.isNotEmpty) {
          _logger.warn(
            '  ⚠️  Reached maximum iterations. '
            '${remainingErrors.length} issues remaining.',
          );
        }
      }
    }

    _logger.success(
      '\n✅ Fixed $totalFixedCount issues. '
      'Run "dart analyze" to verify the fixes.',
    );
  }
}

class _AnalysisResult {
  _AnalysisResult({
    required this.filePath,
    required this.errors,
    required this.suggestions,
  });

  final String filePath;
  final List<String> errors;
  final List<String> suggestions;
}
