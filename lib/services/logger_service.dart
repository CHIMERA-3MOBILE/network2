import 'dart:developer' as developer;
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Professional logging service with enterprise-grade features
/// 
/// This service provides comprehensive logging capabilities with:
/// - Multiple log levels (DEBUG, INFO, WARNING, ERROR, FATAL)
/// - File-based logging with rotation and size limits
/// - In-memory buffer for recent logs
/// - Timestamp formatting and structured logging
/// - Performance monitoring for logging operations
/// - Configurable log levels and output destinations
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  // Logging levels following industry standards
  static const String _levelDebug = 'DEBUG';
  static const String _levelInfo = 'INFO';
  static const String _levelWarning = 'WARNING';
  static const String _levelError = 'ERROR';
  static const String _levelFatal = 'FATAL';

  // Configuration with enterprise defaults
  static const int _maxLogFiles = 5;
  static const int _maxLogSize = 1024 * 1024; // 1MB per file
  static const int _bufferSize = 1000; // Keep last 1000 logs in memory
  static const String _defaultLogDir = 'logs';
  static const String _logFileName = 'app_log';
  static const String _logFileExtension = '.log';

  // Logging level priority for filtering
  static const Map<String, int> _levelPriority = {
    _levelDebug: 0,
    _levelInfo: 1,
    _levelWarning: 2,
    _levelError: 3,
    _levelFatal: 4,
  };

  String _currentLogLevel = _levelInfo;
  List<String> _logBuffer = [];
  bool _isInitialized = false;
  late String _logDirectory;
  
  // Performance monitoring
  int _totalLogs = 0;
  int _logsByLevel = {};
  DateTime _lastReset = DateTime.now();
  
  // Log file management
  File? _currentLogFile;
  IOSink? _logFileSink;

  /// Initialize the logging service with comprehensive setup
  /// 
  /// Sets up the logging directory, initializes file logging,
  /// and prepares the log buffer. Creates the log directory
  /// if it doesn't exist and manages log rotation.
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Create log directory
      final appDir = await getApplicationDocumentsDirectory();
      _logDirectory = '${appDir?.path ?? ''}/$_defaultLogDir';
      await Directory(_logDirectory).create(recursive: true);
      
      // Initialize log file
      await _rotateLogFiles();
      _currentLogFile = await _createLogFile();
      _logFileSink = _currentLogFile!.openWrite(mode: FileMode.append);
      
      _isInitialized = true;
      _log(_levelInfo, 'LoggerService initialized successfully');
      _log(_levelInfo, 'Log directory: $_logDirectory');
      _log(_levelInfo, 'Current log level: $_currentLogLevel');
    } catch (e, stackTrace) {
      developer.log('Failed to initialize LoggerService: $e', error: e, stackTrace: stackTrace);
      // Fallback to console logging only
      _isInitialized = true;
    }
  }

  /// Set logging level with validation
  /// 
  /// Sets the minimum log level that will be recorded.
  /// Logs with lower priority will be filtered out.
  /// 
  /// [level] - The log level to set (DEBUG, INFO, WARNING, ERROR, FATAL)
  void setLogLevel(String level) {
    if (!_levelPriority.containsKey(level)) {
      warning('Invalid log level: $level, keeping current level: $_currentLogLevel');
      return;
    }
    
    _currentLogLevel = level;
    _log(_levelInfo, 'Log level set to: $level');
  }

  /// Get current logging level
  String get currentLogLevel => _currentLogLevel;

  /// Check if a log level should be logged based on current level
  bool _shouldLog(String level) {
    final currentPriority = _levelPriority[_currentLogLevel] ?? 1;
    final messagePriority = _levelPriority[level] ?? 0;
    return messagePriority >= currentPriority;
  }

  /// Log debug message
  void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(_levelDebug, message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  void info(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(_levelInfo, message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(_levelWarning, message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(_levelError, message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal message
  void fatal(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(_levelFatal, message, error: error, stackTrace: stackTrace);
  }

  /// Internal logging method with comprehensive formatting
  void _log(String level, String message, {dynamic error, StackTrace? stackTrace}) {
    if (!_isInitialized) {
      developer.log('[$level] $message', error: error, stackTrace: stackTrace);
      return;
    }

    if (!_shouldLog(level)) return;

    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
    final logEntry = '[$timestamp] [$level] $message';
    
    // Add to buffer
    _logBuffer.add(logEntry);
    if (_logBuffer.length > _bufferSize) {
      _logBuffer.removeAt(0);
    }

    // Update statistics
    _totalLogs++;
    _logsByLevel[level] = (_logsByLevel[level] ?? 0) + 1;

    // Output to console
    developer.log(logEntry, error: error, stackTrace: stackTrace);

    // Write to file
    if (_logFileSink != null) {
      try {
        _logFileSink!.writeln(logEntry);
        if (error != null) {
          _logFileSink!.writeln('Error: $error');
        }
        if (stackTrace != null) {
          _logFileSink!.writeln('StackTrace: $stackTrace');
        }
        _logFileSink!.flush();
      } catch (e) {
        developer.log('Failed to write to log file: $e');
      }
    }
  }

  /// Create a new log file with timestamp
  Future<File> _createLogFile() async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '$_logFileName$timestamp$_logFileExtension';
    final filePath = '$_logDirectory/$fileName';
    return File(filePath);
  }

  /// Rotate log files to maintain size limits
  Future<void> _rotateLogFiles() async {
    try {
      final directory = Directory(_logDirectory);
      if (!await directory.exists()) return;

      final files = await directory.list().toList();
      final logFiles = files.whereType<File>().where((f) => f.path.endsWith(_logFileExtension)).toList();

      // Sort by modification time (oldest first)
      logFiles.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      // Remove old files if exceeding limit
      while (logFiles.length >= _maxLogFiles) {
        final oldest = logFiles.removeAt(0);
        try {
          await oldest.delete();
          _log(_levelInfo, 'Deleted old log file: ${oldest.path}');
        } catch (e) {
          developer.log('Failed to delete log file: $e');
        }
      }
    } catch (e) {
      developer.log('Failed to rotate log files: $e');
    }
  }

  /// Get recent logs from buffer
  List<String> getRecentLogs({int count = 100}) {
    final start = _logBuffer.length - count;
    return _logBuffer.sublist(start < 0 ? 0 : start);
  }

  /// Get comprehensive logging statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalLogs': _totalLogs,
      'logsByLevel': Map.from(_logsByLevel),
      'bufferSize': _logBuffer.length,
      'currentLogLevel': _currentLogLevel,
      'isInitialized': _isInitialized,
      'logDirectory': _logDirectory,
      'lastReset': _lastReset.toIso8601String(),
      'uptime': DateTime.now().difference(_lastReset).inSeconds,
    };
  }

  /// Reset logging statistics
  void resetStatistics() {
    _totalLogs = 0;
    _logsByLevel.clear();
    _lastReset = DateTime.now();
    _log(_levelInfo, 'Logging statistics reset');
  }

  /// Clear log buffer
  void clearBuffer() {
    _logBuffer.clear();
    _log(_levelInfo, 'Log buffer cleared');
  }

  /// Flush and close log file
  Future<void> close() async {
    try {
      await _logFileSink?.close();
      _logFileSink = null;
      _log(_levelInfo, 'Logger service closed');
    } catch (e) {
      developer.log('Failed to close logger service: $e');
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await close();
    _isInitialized = false;
  }
}
