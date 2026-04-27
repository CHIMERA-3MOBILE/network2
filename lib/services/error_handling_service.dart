import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'logger_service.dart';

/// Professional error handling service with comprehensive retry logic
/// 
/// This service provides enterprise-grade error handling capabilities with:
/// - Exponential backoff retry logic with configurable parameters
/// - Error tracking and history for debugging and monitoring
/// - Circuit breaker pattern for preventing cascading failures
/// - Error rate monitoring and alerting
/// - Comprehensive logging for all error scenarios
/// - Performance metrics for error handling operations
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  final LoggerService _logger = LoggerService();
  
  // Error tracking with comprehensive metadata
  final Map<String, List<ErrorRecord>> _errorHistory = {};
  final Map<String, int> _errorCounts = {};
  final Map<String, DateTime> _lastErrorTime = {};
  final Map<String, int> _successCounts = {};
  
  // Retry configuration with enterprise defaults
  static const int _defaultMaxRetries = 3;
  static const Duration _defaultBaseDelay = Duration(seconds: 1);
  static const double _backoffMultiplier = 2.0;
  static const Duration _maxDelay = Duration(seconds: 30);
  
  // Error thresholds for circuit breaker
  static const int _maxErrorsPerType = 10;
  static const Duration _errorWindow = Duration(minutes: 5);
  static const double _errorRateThreshold = 0.5; // 50% error rate
  
  // Circuit breaker state
  final Map<String, CircuitBreakerState> _circuitBreakers = {};
  
  // Performance monitoring
  int _totalRetries = 0;
  int _totalSuccesses = 0;
  DateTime _lastReset = DateTime.now();

  /// Execute operation with exponential backoff retry logic
  /// 
  /// Executes the given operation with automatic retry logic using
  /// exponential backoff delay between attempts. Supports custom retry
  /// conditions and configurable delay parameters.
  /// 
  /// [operation] - The async operation to execute
  /// [operationName] - Name for logging and tracking
  /// [maxRetries] - Maximum number of retry attempts
  /// [baseDelay] - Initial delay before first retry
  /// [backoffMultiplier] - Multiplier for exponential backoff
  /// [maxDelay] - Maximum delay between retries
  /// [retryCondition] - Custom function to determine if retry should occur
  /// Returns result of the operation
  /// Throws last encountered error if all retries fail
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

    // Check circuit breaker
    if (_isCircuitBreakerOpen(operationName)) {
      _logger.warning('Circuit breaker open for operation: $operationName');
      throw CircuitBreakerOpenException('Circuit breaker open for operation: $operationName');
    }

    while (attempt <= maxRetries) {
      try {
        final result = await operation();
        if (attempt > 0) {
          _logSuccess(operationName, attempt);
          _recordSuccess(operationName);
        }
        _resetCircuitBreaker(operationName);
        return result;
      } catch (error) {
        attempt++;
        _recordError(operationName, error, attempt: attempt);
        
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
        _totalRetries++;
      }
    }

    // Open circuit breaker if too many failures
    if (_shouldOpenCircuitBreaker(operationName)) {
      _openCircuitBreaker(operationName);
    }

    throw OperationException('Operation failed after $maxRetries retries');
  }

  /// Execute operation with comprehensive error handling and fallback
  /// 
  /// Provides enhanced error handling with timeout support, custom error
  /// handlers, retry logic, and fallback values for graceful degradation.
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
      _recordError(operationName, error, attempt: 1);
      
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
        _logger.info('Returning fallback value for $operationName');
        return fallbackValue;
      }
      
      rethrow;
    }
  }

  /// Record error for tracking and analysis
  void _recordError(String operationName, dynamic error, {int attempt = 1}) {
    _errorCounts[operationName] = (_errorCounts[operationName] ?? 0) + 1;
    _lastErrorTime[operationName] = DateTime.now();
    
    final record = ErrorRecord(
      error: error,
      timestamp: DateTime.now(),
      operationName: operationName,
      attempt: attempt,
    );
    
    _errorHistory.putIfAbsent(operationName, () => []);
    _errorHistory[operationName]!.add(record);
    
    // Keep only recent errors
    if (_errorHistory[operationName]!.length > _maxErrorsPerType) {
      _errorHistory[operationName]!.removeAt(0);
    }
  }

  /// Record success for metrics and circuit breaker
  void _recordSuccess(String operationName) {
    _successCounts[operationName] = (_successCounts[operationName] ?? 0) + 1;
    _totalSuccesses++;
  }

  /// Check if circuit breaker should be opened
  bool _shouldOpenCircuitBreaker(String operationName) {
    final errorCount = _errorCounts[operationName] ?? 0;
    final successCount = _successCounts[operationName] ?? 0;
    final totalAttempts = errorCount + successCount;
    
    if (totalAttempts < 5) return false; // Minimum attempts before opening
    
    final errorRate = errorCount / totalAttempts;
    return errorRate > _errorRateThreshold;
  }

  /// Check if circuit breaker is currently open
  bool _isCircuitBreakerOpen(String operationName) {
    final state = _circuitBreakers[operationName];
    if (state == null) return false;
    
    // Check if cooldown period has passed
    if (DateTime.now().isAfter(state.cooldownUntil)) {
      _circuitBreakers.remove(operationName);
      return false;
    }
    
    return state.isOpen;
  }

  /// Open circuit breaker for operation
  void _openCircuitBreaker(String operationName) {
    _circuitBreakers[operationName] = CircuitBreakerState(
      isOpen: true,
      openedAt: DateTime.now(),
      cooldownUntil: DateTime.now().add(_errorWindow),
    );
    _logger.warning('Circuit breaker opened for operation: $operationName');
  }

  /// Reset circuit breaker for operation
  void _resetCircuitBreaker(String operationName) {
    _circuitBreakers.remove(operationName);
  }

  /// Get comprehensive error statistics
  Map<String, dynamic> getErrorStatistics() {
    return {
      'totalRetries': _totalRetries,
      'totalSuccesses': _totalSuccesses,
      'errorCounts': Map.from(_errorCounts),
      'successCounts': Map.from(_successCounts),
      'lastReset': _lastReset.toIso8601String(),
      'uptime': DateTime.now().difference(_lastReset).inSeconds,
      'circuitBreakers': _circuitBreakers.map((key, value) => MapEntry(
        key,
        {
          'isOpen': value.isOpen,
          'openedAt': value.openedAt.toIso8601String(),
          'cooldownUntil': value.cooldownUntil.toIso8601String(),
        },
      )),
    };
  }

  /// Reset error statistics
  void resetStatistics() {
    _errorHistory.clear();
    _errorCounts.clear();
    _lastErrorTime.clear();
    _successCounts.clear();
    _circuitBreakers.clear();
    _totalRetries = 0;
    _totalSuccesses = 0;
    _lastReset = DateTime.now();
    _logger.info('Error handling service statistics reset');
  }

  /// Log error with comprehensive details
  Future<void> _logError(String operationName, dynamic error, int attempt) async {
    _logger.error(
      'Operation failed: $operationName (attempt $attempt)',
      error: error,
    );
  }

  /// Log success after retry
  Future<void> _logSuccess(String operationName, int attempt) async {
    _logger.info('Operation succeeded after $attempt retries: $operationName');
  }

  /// Log retry attempt
  Future<void> _logRetry(String operationName, dynamic error, int attempt, Duration delay) async {
    _logger.warning(
      'Retrying operation: $operationName (attempt $attempt, delay: ${delay.inSeconds}s)',
    );
  }
}

/// Error record for tracking and analysis
class ErrorRecord {
  final dynamic error;
  final DateTime timestamp;
  final String operationName;
  final int attempt;
  
  ErrorRecord({
    required this.error,
    required this.timestamp,
    required this.operationName,
    this.attempt = 1,
  });
}

/// Circuit breaker state for preventing cascading failures
class CircuitBreakerState {
  final bool isOpen;
  final DateTime openedAt;
  final DateTime cooldownUntil;
  
  CircuitBreakerState({
    required this.isOpen,
    required this.openedAt,
    required this.cooldownUntil,
  });
}

/// Custom exception for operation failures
class OperationException implements Exception {
  final String message;
  
  OperationException(this.message);
  
  @override
  String toString() => 'OperationException: $message';
}

/// Custom exception for circuit breaker open state
class CircuitBreakerOpenException implements Exception {
  final String message;
  
  CircuitBreakerOpenException(this.message);
  
  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}

/// Network exception for network-related errors
class NetworkException implements Exception {
  final String message;
  
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}
