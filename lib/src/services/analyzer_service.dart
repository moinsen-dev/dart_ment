import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:path/path.dart' as path;

/// Service for analyzing Dart code
class AnalyzerService {
  AnalyzerService({required this.projectPath});

  final String projectPath;
  late AnalysisContextCollection _collection;

  /// Initialize the analyzer
  Future<void> initialize() async {
    _collection = AnalysisContextCollection(includedPaths: [projectPath]);
  }

  /// Get all Dart files in the project
  Future<List<String>> getDartFiles({
    List<String>? includePaths,
    List<String>? excludePaths,
  }) async {
    final dartFiles = <String>[];
    List<String> includes;

    // If no specific includes are provided, use defaults or scan entire directory
    if (includePaths == null || includePaths.isEmpty) {
      // Check if standard directories exist
      final libDir = Directory(path.join(projectPath, 'lib'));
      final binDir = Directory(path.join(projectPath, 'bin'));
      final testDir = Directory(path.join(projectPath, 'test'));

      // Check if we're already in a subdirectory (lib, bin, test, etc)
      final projectBasename = path.basename(projectPath);
      final isInSubdir = [
        'lib',
        'bin',
        'test',
        'src',
      ].contains(projectBasename);

      if (isInSubdir) {
        // If we're already in a subdirectory, scan from here
        includes = ['**'];
      } else if (libDir.existsSync() ||
          binDir.existsSync() ||
          testDir.existsSync()) {
        // Use standard includes if any standard directory exists
        includes = ['lib/**', 'bin/**', 'test/**'];
      } else {
        // Otherwise scan the entire directory
        includes = ['**'];
      }
    } else {
      includes = includePaths;
    }

    final excludes = excludePaths ?? ['**/*.g.dart', '**/*.freezed.dart'];

    for (final include in includes) {
      // Handle special case for current directory and recursive patterns
      final Directory directory;
      final bool recursive;

      if (include == '.' || include == '**') {
        directory = Directory(projectPath);
        recursive = include == '**';
      } else if (include.contains('**')) {
        // Handle patterns like 'lib/**'
        final basePath = include.split('**').first.replaceAll('/', '');
        if (basePath.isEmpty) {
          directory = Directory(projectPath);
        } else {
          directory = Directory(path.join(projectPath, basePath));
        }
        recursive = true;
      } else {
        // Handle simple patterns
        directory = Directory(path.join(projectPath, include.split('/').first));
        recursive = include.contains('/');
      }

      if (!directory.existsSync()) continue;

      await for (final entity in directory.list(recursive: recursive)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final relativePath = path.relative(entity.path, from: projectPath);

          // Check if file should be excluded
          var shouldExclude = false;
          for (final exclude in excludes) {
            if (_matchesPattern(relativePath, exclude)) {
              shouldExclude = true;
              break;
            }
          }

          if (!shouldExclude) {
            dartFiles.add(entity.path);
          }
        }
      }
    }

    return dartFiles;
  }

  /// Analyze a single file and return errors
  Future<List<AnalysisError>> analyzeFile(String filePath) async {
    final context = _getContextFor(filePath);
    if (context == null) return [];

    final result = await context.currentSession.getErrors(filePath);
    if (result is ErrorsResult) {
      return result.errors;
    }
    return [];
  }

  /// Get file content
  Future<String> getFileContent(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('File not found: $filePath');
    }
    return file.readAsString();
  }

  /// Get analysis context for a file
  AnalysisContext? _getContextFor(String filePath) {
    for (final context in _collection.contexts) {
      if (context.contextRoot.isAnalyzed(filePath)) {
        return context;
      }
    }
    return null;
  }

  /// Check if a path matches a glob pattern
  bool _matchesPattern(String filePath, String pattern) {
    // Simple pattern matching (can be enhanced with proper glob library)
    if (pattern.contains('**')) {
      final parts = pattern.split('**');
      if (parts.length == 2) {
        final prefix = parts[0];
        final suffix = parts[1].startsWith('/')
            ? parts[1].substring(1)
            : parts[1];
        return filePath.startsWith(prefix) && filePath.endsWith(suffix);
      }
    }
    return filePath.endsWith(pattern);
  }
}
