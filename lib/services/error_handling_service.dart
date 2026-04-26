import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Professional error handling service with comprehensive retry logic
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  // Error tracking
  final Map<String, List<ErrorRecord>> _errorHistory = {};
  final Map<String, int> _errorCounts = {};
  final Map<String, DateTime> _lastErrorTime = {};
  
  // Retry configuration
  static const int _defaultMaxRetries = 3;
  static const Duration _defaultBaseDelay = Duration(seconds: 1);
  static const double _backoffMultiplier = 2.0;
  static const Duration _maxDelay = Duration(seconds: 30);

  // Error thresholds
  static const int _maxErrorsPerType = 10;
  static const Duration _errorWindow = Duration(minutes: 5);

  /// Execute operation with exponential backoff retry logic
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation,
    String operationName, {
    int maxRetries = _defaultMaxRetries,
    Duration? baseDelay,
    double? backoffMultiplier,
    Duration? maxDelay,
    bool Function(dynamic error)? retryCondition,
  }) async {
    int attempt = 0;
    Duration delay = baseDelay ?? _defaultBaseDelay;
    final multiplier = backoffMultiplier ?? _backoffMultiplier;
    final maxDel = maxDelay ?? _maxDelay;

    while (attempt <= maxRetries) {
      try {
        final result = await operation();
        if (attempt > 0) {
          _logSuccess(operationName, attempt);
        }
        return result;
      } catch (error) {
        attempt++;
        
        // Check if we should retry
        if (attempt > maxRetries || (retryCondition != null && !retryCondition(error))) {
          await _logError(operationName, error, attempt);
          rethrow;
        }

        // Log retry attempt
        await _logRetry(operationName, error, attempt, delay);
        
        // Wait before retry
        await Future.delayed(delay);
        
        // Calculate next delay with exponential backoff
        delay = Duration(
          milliseconds: (delay.inMilliseconds * multiplier).round(),
        );
        if (delay > maxDel) {
          delay = maxDel;
        }
      }
    }

    throw OperationException('Operation failed after $maxRetries retries');
  }

  /// Execute operation with comprehensive error handling and fallback
  Future<T> executeWithErrorHandling<T>(
    Future<T> Function() operation,
    String operationName, {
    T? fallbackValue,
    bool Function(dynamic error)? shouldRetry,
    Future<void> Function(dynamic error)? onError,
    Duration? timeout,
  }) async {
    try {
      if (timeout != null) {
        return await operation().timeout(timeout);
      } else {
        return await operation();
      }
    } catch (error) {
      // Log the error
      await _logError(operationName, error, 1);
      
      // Call custom error handler if provided
      if (onError != null) {
        await onError(error);
      }
      
      // Check if we should retry
      if (shouldRetry != null && shouldRetry(error)) {
        return await executeWithRetry(operation, operationName);
      }
      
      // Return fallback value if available
      if (fallbackValue != null) {
        return fallbackValue;
      }
      
      // Rethrow if no fallback
      rethrow;
    }
  }

  /// Handle network-specific errors with professional logic
  Future<T> handleNetworkError<T>(
    Future<T> Function() operation,
    String operationName, {
    T? fallbackValue,
    Duration? timeout = const Duration(seconds: 30),
  }) async {
    try {
      // Check connectivity first
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        throw NetworkException('No internet connection available');
      }

      return await executeWithErrorHandling(
        operation,
        operationName,
        timeout: timeout,
        fallbackValue: fallbackValue,
        shouldRetry: (error) => _shouldRetryNetworkError(error),
        onError: (error) => _handleNetworkErrorSpecific(error),
      );
    } catch (error) {
      await _logError(operationName, error, 1);
      if (fallbackValue != null) {
        return fallbackValue;
      }
      rethrow;
    }
  }

  /// Determine if network error should be retried
  bool _shouldRetryNetworkError(dynamic error) {
    if (error is SocketException) {
      return true; // Network issues are usually temporary
    }
    if (error is TimeoutException) {
      return true; // Timeouts can be retried
    }
    if (error is NetworkException) {
      return !error.message.contains('authentication'); // Don't retry auth errors
    }
    return false;
  }

  /// Handle specific network error types
  Future<void> _handleNetworkErrorSpecific(dynamic error) async {
    if (error is SocketException) {
      // Could implement specific socket error handling
      print('Socket error: ${error.message}');
    } else if (error is TimeoutException) {
      // Could implement timeout-specific handling
      print('Timeout error: ${error.message}');
    } else if (error is NetworkException) {
      // Could implement network-specific handling
      print('Network error: ${error.message}');
    }
  }

  /// Log error with comprehensive information
  Future<void> _logError(String operationName, dynamic error, int attempt) async {
    final timestamp = DateTime.now();
    final errorRecord = ErrorRecord(
      operationName: operationName,
      error: error,
      timestamp: timestamp,
      attempt: attempt,
    );

    // Add to error history
    _errorHistory.putIfAbsent(operationName, () => []).add(errorRecord);
    _errorCounts[operationName] = (_errorCounts[operationName] ?? 0) + 1;
    _lastErrorTime[operationName] = timestamp;

    // Clean old errors
    _cleanOldErrors(operationName);

    // Check error thresholds
    _checkErrorThresholds(operationName);

    // Log to console (in production, use proper logging)
    print('ERROR [$operationName] Attempt $attempt: ${error.toString()}');
  }

  /// Log retry attempt
  Future<void> _logRetry(String operationName, dynamic error, int attempt, Duration delay) async {
    print('RETRY [$operationName] Attempt $attempt in ${delay.inSeconds}s: ${error.toString()}');
  }

  /// Log successful operation after retries
  Future<void> _logSuccess(String operationName, int attempts) async {
    print('SUCCESS [$operationName] Completed after $attempts attempts');
  }

  /// Clean old error records
  void _cleanOldErrors(String operationName) {
    final errors = _errorHistory[operationName];
    if (errors == null) return;

    final now = DateTime.now();
    errors.removeWhere((record) => now.difference(record.timestamp) > _errorWindow);
  }

  /// Check error thresholds and take action
  void _checkErrorThresholds(String operationName) {
    final errorCount = _errorCounts[operationName] ?? 0;
    final errors = _errorHistory[operationName] ?? [];

    if (errorCount >= _maxErrorsPerType) {
      // Could implement circuit breaker pattern
      print('WARNING [$operationName] Error threshold reached: $errorCount errors');
    }

    // Check for rapid-fire errors
    if (errors.length >= 5) {
      final timeSpan = errors.last.timestamp.difference(errors.first.timestamp);
      if (timeSpan.inSeconds < 60) {
        print('CRITICAL [$operationName] Rapid errors detected: ${errors.length} errors in ${timeSpan.inSeconds}s');
      }
    }
  }

  /// Get comprehensive error statistics
  Map<String, dynamic> getErrorStatistics() {
    final totalErrors = _errorCounts.values.fold(0, (sum, count) => sum + count);
    final uniqueErrorTypes = _errorCounts.length;
    
    final errorDetails = <String, dynamic>{};
    for (final entry in _errorCounts.entries) {
      errorDetails[entry.key] = {
        'count': entry.value,
        'lastError': _lastErrorTime[entry.key]?.toIso8601String(),
        'recentErrors': _errorHistory[entry.key]?.length ?? 0,
      };
    }

    return {
      'totalErrors': totalErrors,
      'uniqueErrorTypes': uniqueErrorTypes,
      'errorCounts': Map.from(_errorCounts),
      'errorDetails': errorDetails,
      'lastUpdateTime': DateTime.now().toIso8601String(),
    };
  }

  /// Clear error history for specific operation
  void clearErrorHistory(String operationName) {
    _errorHistory.remove(operationName);
    _errorCounts.remove(operationName);
    _lastErrorTime.remove(operationName);
  }

  /// Clear all error history
  void clearAllErrorHistory() {
    _errorHistory.clear();
    _errorCounts.clear();
    _lastErrorTime.clear();
  }

  /// Get error rate for specific operation
  double getErrorRate(String operationName) {
    final errors = _errorHistory[operationName] ?? [];
    if (errors.isEmpty) return 0.0;

    final timeSpan = DateTime.now().difference(errors.first.timestamp);
    if (timeSpan.inSeconds == 0) return 0.0;

    return errors.length / timeSpan.inSeconds;
  }

  /// Check if operation is in error state
  bool isInErrorState(String operationName) {
    final errorCount = _errorCounts[operationName] ?? 0;
    final lastError = _lastErrorTime[operationName];
    
    if (errorCount >= _maxErrorsPerType) return true;
    
    if (lastError != null) {
      final timeSinceLastError = DateTime.now().difference(lastError);
      if (timeSinceLastError.inMinutes < 1 && errorCount >= 3) return true;
    }
    
    return false;
  }

  /// Get recommended action for error
  String getRecommendedAction(String operationName) {
    final errorCount = _errorCounts[operationName] ?? 0;
    final lastError = _lastErrorTime[operationName];
    
    if (errorCount == 0) {
      return 'No errors detected';
    } else if (errorCount < 3) {
      return 'Monitor for pattern';
    } else if (errorCount < _maxErrorsPerType) {
      return 'Consider retry with backoff';
    } else {
      return 'Implement circuit breaker or manual intervention';
    }
  }

  /// Create error report for debugging
  Map<String, dynamic> createErrorReport() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'statistics': getErrorStatistics(),
      'recommendations': _generateRecommendations(),
      'healthStatus': _getHealthStatus(),
    };
  }

  /// Generate recommendations based on error patterns
  List<String> _generateRecommendations() {
    final recommendations = <String>[];
    
    for (final entry in _errorCounts.entries) {
      final operationName = entry.key;
      final errorCount = entry.value;
      
      if (errorCount >= _maxErrorsPerType) {
        recommendations.add('High error rate for $operationName - Consider circuit breaker');
      }
      
      if (isInErrorState(operationName)) {
        recommendations.add('$operationName is in error state - Investigate immediately');
      }
      
      final errorRate = getErrorRate(operationName);
      if (errorRate > 0.1) { // More than 1 error per 10 seconds
        recommendations.add('High error rate for $operationName - Check system health');
      }
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('All systems operating normally');
    }
    
    return recommendations;
  }

  /// Get overall health status
  String _getHealthStatus() {
    final totalErrors = _errorCounts.values.fold(0, (sum, count) => sum + count);
    
    if (totalErrors == 0) {
      return 'Healthy';
    } else if (totalErrors < 10) {
      return 'Minor Issues';
    } else if (totalErrors < 50) {
      return 'Degraded';
    } else {
      return 'Critical';
    }
  }
}

/// Error record for tracking
class ErrorRecord {
  final String operationName;
  final dynamic error;
  final DateTime timestamp;
  final int attempt;

  ErrorRecord({
    required this.operationName,
    required this.error,
    required this.timestamp,
    required this.attempt,
  });

  Map<String, dynamic> toJson() {
    return {
      'operationName': operationName,
      'error': error.toString(),
      'timestamp': timestamp.toIso8601String(),
      'attempt': attempt,
    };
  }
}

/// Custom exceptions for better error handling
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;
  
  NetworkException(this.message, {this.statusCode, this.originalError});
  
  @override
  String toString() => 'NetworkException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class OperationException implements Exception {
  final String message;
  final String? operationName;
  final dynamic originalError;
  
  OperationException(this.message, {this.operationName, this.originalError});
  
  @override
  String toString() => 'OperationException: $message${operationName != null ? ' (Operation: $operationName)' : ''}';
}
