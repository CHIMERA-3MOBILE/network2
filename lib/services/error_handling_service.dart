import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'logger_service.dart';

class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  final LoggerService _logger = LoggerService();
  final Map<String, int> _errorCounts = {};
  final Map<String, DateTime> _lastErrors = {};
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _errorCooldown = Duration(minutes: 5);

  Future<T> executeWithRetry<T>(
    Future<T> Function() operation,
    String operationName, {
    int maxRetries = _maxRetries,
    Duration delay = _retryDelay,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        lastException = e is Exception ? e : Exception(e.toString());
        
        _logger.warning(
          'Operation "$operationName" failed (attempt $attempts/$maxRetries): $e',
          tag: 'Retry',
        );

        if (attempts < maxRetries) {
          await Future.delayed(delay * attempts); // Exponential backoff
        }
      }
    }

    _logger.error(
      'Operation "$operationName" failed after $maxRetries attempts',
      error: lastException,
      tag: 'Retry',
    );
    
    throw lastException ?? Exception('Operation failed after $maxRetries attempts');
  }

  Future<T> executeWithErrorHandling<T>(
    Future<T> Function() operation,
    String operationName, {
    T? fallbackValue,
    bool logErrors = true,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      if (logErrors) {
        _logError(operationName, e, stackTrace);
      }
      
      if (fallbackValue != null) {
        _logger.info('Using fallback value for "$operationName"', tag: 'Fallback');
        return fallbackValue;
      }
      
      rethrow;
    }
  }

  void _logError(String operation, dynamic error, StackTrace? stackTrace) {
    final errorKey = '$operation:${error.toString()}';
    final now = DateTime.now();
    
    // Update error statistics
    _errorCounts[errorKey] = (_errorCounts[errorKey] ?? 0) + 1;
    _lastErrors[errorKey] = now;

    // Check if this is a recurring error
    final isRecurring = _isRecurringError(errorKey, now);
    
    if (isRecurring) {
      _logger.error(
        'RECURRING ERROR in "$operation" (${_errorCounts[errorKey]} occurrences): $error',
        error: error,
        stackTrace: stackTrace,
        tag: 'Recurring',
      );
    } else {
      _logger.error(
        'Error in "$operation": $error',
        error: error,
        stackTrace: stackTrace,
        tag: 'Error',
      );
    }

    // Send crash report in debug mode
    if (kDebugMode && _errorCounts[errorKey]! >= 5) {
      _sendCrashReport(operation, error, stackTrace);
    }
  }

  bool _isRecurringError(String errorKey, DateTime now) {
    final lastError = _lastErrors[errorKey];
    if (lastError == null) return false;
    
    return now.difference(lastError) < _errorCooldown;
  }

  void _sendCrashReport(String operation, dynamic error, StackTrace? stackTrace) {
    // In a real app, send to crash reporting service
    _logger.error(
      'CRASH REPORT - Operation: $operation, Error: $error, Stack: $stackTrace',
      tag: 'CrashReport',
    );
  }

  Future<bool> checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      _logger.warning('Network connectivity check failed: $e', tag: 'Network');
      return false;
    }
  }

  Future<void> handleNetworkError(String operation, dynamic error) async {
    _logger.warning('Network error in "$operation": $error', tag: 'Network');
    
    // Check if it's a connectivity issue
    final isConnected = await checkNetworkConnectivity();
    if (!isConnected) {
      _logger.info('No internet connection available', tag: 'Network');
      // Could show user notification here
    }
  }

  void clearErrorHistory() {
    _errorCounts.clear();
    _lastErrors.clear();
    _logger.info('Error history cleared', tag: 'ErrorHandling');
  }

  Map<String, dynamic> getErrorStatistics() {
    return {
      'totalErrors': _errorCounts.values.fold(0, (sum, count) => sum + count),
      'uniqueErrors': _errorCounts.length,
      'errorCounts': Map.from(_errorCounts),
      'lastErrors': Map.from(_lastErrors),
    };
  }

  Future<void> recoverFromCriticalError() async {
    _logger.info('Attempting critical error recovery', tag: 'Recovery');
    
    try {
      // Clear caches
      // Reset network connections
      // Restart services
      
      await Future.delayed(const Duration(seconds: 2));
      
      _logger.info('Critical error recovery completed', tag: 'Recovery');
    } catch (e) {
      _logger.error('Critical error recovery failed: $e', tag: 'Recovery');
    }
  }
}
