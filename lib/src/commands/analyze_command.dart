import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_ment/src/services/analyzer_service.dart';
import 'package:dart_ment/src/services/gemini_service.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

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
      ..addFlag(
        'suggestions',
        abbr: 's',
        help: 'Generate AI-powered improvement suggestions',
        defaultsTo: true,
      );
  }

  final Logger _logger;

  @override
  String get description => 'Analyze code quality and suggest improvements.';

  @override
  String get name => 'analyze';

  @override
  Future<int> run() async {
    _logger.info('Starting code analysis...');

    try {
      // Load configuration
      final config = await _loadConfiguration();
      final shouldGenerateSuggestions =
          argResults?['suggestions'] as bool? ?? true;

      GeminiService? geminiService;
      if (shouldGenerateSuggestions) {
        final llmConfig = config['llm'] as Map<String, dynamic>?;
        final geminiConfig = llmConfig?['gemini'] as Map<String, dynamic>?;
        final apiKey = argResults?['api-key'] as String? ??
            geminiConfig?['api_key'] as String? ??
            Platform.environment['GEMINI_API_KEY'];

        if (apiKey != null && apiKey.isNotEmpty) {
          geminiService = GeminiService(apiKey: apiKey)..initialize();
        } else {
          _logger.warn(
            'API key not found. Skipping AI-powered suggestions. '
            'Provide API key via --api-key flag or GEMINI_API_KEY env var.',
          );
        }
      }

      // Initialize analyzer
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

      // Analyze files
      var totalIssues = 0;
      var totalSuggestions = 0;
      final results = <_AnalysisResult>[];

      final analysisProgress = _logger.progress('Analyzing files');
      for (final file in dartFiles) {
        final errors = await analyzerService.analyzeFile(file);
        final relativePath = path.relative(file);

        final suggestions = <String>[];
        if (geminiService != null &&
            (errors.isEmpty || shouldGenerateSuggestions)) {
          try {
            final fileContent = await analyzerService.getFileContent(file);
            final aiSuggestions = await geminiService.analyzeCode(
              code: fileContent,
              filePath: relativePath,
            );
            suggestions.addAll(aiSuggestions);
          } catch (e) {
            _logger.detail(
              'Could not generate suggestions for $relativePath: $e',
            );
          }
        }

        if (errors.isNotEmpty || suggestions.isNotEmpty) {
          results.add(
            _AnalysisResult(
              filePath: relativePath,
              errors: errors.map((e) => e.message).toList(),
              suggestions: suggestions,
            ),
          );
          totalIssues += errors.length;
          totalSuggestions += suggestions.length;
        }
      }
      analysisProgress.complete(
        'Analysis complete: $totalIssues issues, $totalSuggestions suggestions',
      );

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
          _logger.info(
            '\nRun "ment fix" to automatically fix these issues.',
          );
        }
      }

      return ExitCode.success.code;
    } catch (e) {
      _logger.err('Error during analysis: $e');
      return ExitCode.software.code;
    }
  }

  Future<Map<String, dynamic>> _loadConfiguration() async {
    try {
      final configPath = argResults?['config'] as String? ??
          path.join(Directory.current.path, '.dart_ment.yaml');

      final configFile = File(configPath);
      if (configFile.existsSync()) {
        final content = await configFile.readAsString();
        final yaml = loadYaml(content);
        return yaml is Map<String, dynamic> ? yaml : {};
      }
    } catch (e) {
      _logger.detail('Could not load custom config: $e');
    }

    // Return empty config if no custom config found
    return {};
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
