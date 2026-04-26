import 'dart:developer' as developer;
import 'dart:io';
import 'package:intl/intl.dart';

/// Professional logging service with enterprise-grade features
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  // Logging levels
  static const String _levelDebug = 'DEBUG';
  static const String _levelInfo = 'INFO';
  static const String _levelWarning = 'WARNING';
  static const String _levelError = 'ERROR';
  static const String _levelFatal = 'FATAL';

  // Configuration
  static const int _maxLogFiles = 5;
  static const int _maxLogSize = 1024 * 1024; // 1MB
  static const String _defaultLogDir = 'logs';

  String _currentLogLevel = _levelInfo;
  List<String> _logBuffer = [];
  bool _isInitialized = false;
  late String _logDirectory;

  /// Initialize the logging service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Create log directory
      final appDir = await getApplicationDocumentsDirectory();
      _logDirectory = '${appDir?.path ?? ''}/$_defaultLogDir';
      await Directory(_logDirectory).create(recursive: true);
      
      _isInitialized = true;
      _log(_levelInfo, 'LoggerService initialized');
    } catch (e) {
      developer.log('Failed to initialize LoggerService: $e');
    }
  }

  /// Set logging level
  void setLogLevel(String level) {
    _currentLogLevel = level;
    _log(_levelInfo, 'Log level set to: $level');
  }

  /// Log message with timestamp and optional metadata
  Future<void> log(String level, String message, {String? tag, dynamic error, StackTrace? stackTrace}) async {
    if (!_isInitialized) {
      developer.log('LoggerService not initialized');
      return;
    }

    try {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
      final tagStr = tag ?? 'NetworkApp';
      final logMessage = '[$timestamp] [$level] [$tagStr] $message';
      
      // Console logging
      if (level == _levelError || level == _levelFatal) {
        developer.log(logMessage, error: error, stackTrace: stackTrace);
      } else {
        developer.log(logMessage);
      }
      
      // File logging
      await _writeToLogFile(logMessage);
      
      // Maintain log buffer
      _logBuffer.add(logMessage);
      if (_logBuffer.length > 1000) {
        _logBuffer.removeAt(0);
      }
      
    } catch (e) {
      developer.log('Failed to log message: $e');
    }
  }

  /// Write log message to file
  Future<void> _writeToLogFile(String message) async {
    try {
      final logFile = File('$_logDirectory/app_${DateTime.now().day}.log');
      await logFile.writeAsString('$message\n', mode: FileMode.append);
      
      // Clean up old log files
      await _cleanupOldLogFiles();
    } catch (e) {
      developer.log('Failed to write to log file: $e');
    }
  }

  /// Clean up old log files
  Future<void> _cleanupOldLogFiles() async {
    try {
      final logDir = Directory(_logDirectory);
      if (await logDir.exists()) {
        final files = await logDir.list().toList();
        files.sort((a, b) => b.path.compareTo(a.path));
        
        // Keep only the most recent log files
        if (files.length > _maxLogFiles) {
          final filesToDelete = files.sublist(0, files.length - _maxLogFiles);
          for (final file in filesToDelete) {
            try {
              await file.delete();
            } catch (e) {
              developer.log('Failed to delete log file ${file.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      developer.log('Failed to cleanup log files: $e');
    }
  }

  /// Debug logging
  Future<void> debug(String message, {String? tag, dynamic error, StackTrace? stackTrace}) async {
    await log(_levelDebug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Info logging
  Future<void> info(String message, {String? tag, dynamic error, StackTrace? stackTrace}) async {
    await log(_levelInfo, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Warning logging
  Future<void> warning(String message, {String? tag, dynamic error, StackTrace? stackTrace}) async {
    await log(_levelWarning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Error logging
  Future<void> error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) async {
    await log(_levelError, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Fatal logging
  Future<void> fatal(String message, {String? tag, dynamic error, StackTrace? stackTrace}) async {
    await log(_levelFatal, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Get current log level
  String get currentLogLevel => _currentLogLevel;

  /// Get log buffer
  List<String> get logBuffer => List.unmodifiable(_logBuffer);

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get log directory
  String get logDirectory => _logDirectory;

  /// Dispose resources
  void dispose() {
    _logBuffer.clear();
    _isInitialized = false;
    developer.log('LoggerService disposed');
  }

  /// Get log statistics
  Map<String, dynamic> getStatistics() {
    return {
      'isInitialized': _isInitialized,
      'currentLogLevel': _currentLogLevel,
      'logDirectory': _logDirectory,
      'bufferSize': _logBuffer.length,
      'maxLogFiles': _maxLogFiles,
      'maxLogSize': _maxLogSize,
    };
  }

  /// Export logs for debugging
  Future<String> exportLogs() async {
    try {
      final logDir = Directory(_logDirectory);
      if (await logDir.exists()) {
        final files = await logDir.list().toList();
        files.sort((a, b) => b.path.compareTo(a.path));
        
        final buffer = StringBuffer();
        for (final file in files) {
          if (await file.exists()) {
            final content = await file.readAsString();
            buffer.writeln('=== ${file.path} ===');
            buffer.writeln(content);
            buffer.writeln('');
          }
        }
        
        return buffer.toString();
      }
    } catch (e) {
      return 'Failed to export logs: $e';
    }
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    try {
      final logDir = Directory(_logDirectory);
      if (await logDir.exists()) {
        final files = await logDir.list().toList();
        for (final file in files) {
          try {
            await file.delete();
          } catch (e) {
            developer.log('Failed to delete log file ${file.path}: $e');
          }
        }
      }
      
      _logBuffer.clear();
      await log(_levelInfo, 'All logs cleared');
    } catch (e) {
      developer.log('Failed to clear logs: $e');
    }
  }
}
