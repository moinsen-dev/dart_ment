import 'package:mason_logger/mason_logger.dart';

/// {@template dart_ment_logger}
/// Logger for dart_ment CLI
/// {@endtemplate}
class DartMentLogger {
  /// {@macro dart_ment_logger}
  DartMentLogger() : _logger = Logger();

  final Logger _logger;

  /// Log an info message
  void info(String message) => _logger.info(message);

  /// Log a success message
  void success(String message) => _logger.success(message);

  /// Log a warning message
  void warn(String message) => _logger.warn(message);

  /// Log an error message
  void err(String message) => _logger.err(message);

  /// Write a progress message
  Progress progress(String message) => _logger.progress(message);
}
