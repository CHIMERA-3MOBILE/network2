import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

/// Professional performance monitoring service with comprehensive metrics
class PerformanceMonitorService {
  static final PerformanceMonitorService _instance = PerformanceMonitorService._internal();
  factory PerformanceMonitorService() => _instance;
  PerformanceMonitorService._internal();

  // Performance tracking
  final Map<String, List<PerformanceMetric>> _metrics = {};
  final Map<String, OperationStats> _operationStats = {};
  final StreamController<PerformanceAlert> _alertController = 
      StreamController<PerformanceAlert>.broadcast();
  
  // Monitoring state
  bool _isMonitoring = false;
  Timer? _monitoringTimer;
  Timer? _cleanupTimer;
  
  // Thresholds
  static const Duration _slowOperationThreshold = Duration(milliseconds: 1000);
  static const Duration _monitoringInterval = Duration(seconds: 5);
  static const Duration _cleanupInterval = Duration(minutes: 10);
  static const int _maxMetricsPerOperation = 1000;
  static const int _maxMemoryUsageMB = 100;

  // Memory tracking
  int _initialMemory = 0;
  int _peakMemory = 0;
  int _currentMemory = 0;

  Stream<PerformanceAlert> get alertStream => _alertController.stream;

  /// Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _initialMemory = _getCurrentMemoryUsage();
    _currentMemory = _initialMemory;
    _peakMemory = _initialMemory;
    
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _performHealthCheck();
    });
    
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _cleanupOldMetrics();
    });
    
    print('Performance monitoring started');
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _cleanupTimer?.cancel();
    
    print('Performance monitoring stopped');
  }

  /// Track operation performance with comprehensive metrics
  T trackOperation<T>(String operationName, T Function() operation) {
    final stopwatch = Stopwatch()..start();
    final startMemory = _getCurrentMemoryUsage();
    
    try {
      final result = operation();
      stopwatch.stop();
      
      final endMemory = _getCurrentMemoryUsage();
      final memoryDelta = endMemory - startMemory;
      
      _recordMetric(operationName, PerformanceMetric(
        operationName: operationName,
        duration: stopwatch.elapsed,
        memoryUsage: endMemory,
        memoryDelta: memoryDelta,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return result;
    } catch (error) {
      stopwatch.stop();
      
      _recordMetric(operationName, PerformanceMetric(
        operationName: operationName,
        duration: stopwatch.elapsed,
        memoryUsage: _getCurrentMemoryUsage(),
        memoryDelta: _getCurrentMemoryUsage() - startMemory,
        success: false,
        timestamp: DateTime.now(),
        error: error.toString(),
      ));
      
      rethrow;
    }
  }

  /// Track async operation performance
  Future<T> trackAsyncOperation<T>(String operationName, Future<T> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    final startMemory = _getCurrentMemoryUsage();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      final endMemory = _getCurrentMemoryUsage();
      final memoryDelta = endMemory - startMemory;
      
      _recordMetric(operationName, PerformanceMetric(
        operationName: operationName,
        duration: stopwatch.elapsed,
        memoryUsage: endMemory,
        memoryDelta: memoryDelta,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return result;
    } catch (error) {
      stopwatch.stop();
      
      _recordMetric(operationName, PerformanceMetric(
        operationName: operationName,
        duration: stopwatch.elapsed,
        memoryUsage: _getCurrentMemoryUsage(),
        memoryDelta: _getCurrentMemoryUsage() - startMemory,
        success: false,
        timestamp: DateTime.now(),
        error: error.toString(),
      ));
      
      rethrow;
    }
  }

  /// Record performance metric
  void _recordMetric(String operationName, PerformanceMetric metric) {
    _metrics.putIfAbsent(operationName, () => []).add(metric);
    
    // Update operation stats
    final stats = _operationStats.putIfAbsent(operationName, () => OperationStats());
    stats.update(metric);
    
    // Check thresholds
    _checkThresholds(operationName, metric);
    
    // Update memory tracking
    _updateMemoryTracking(metric.memoryUsage);
    
    // Limit metrics count
    final metrics = _metrics[operationName]!;
    if (metrics.length > _maxMetricsPerOperation) {
      metrics.removeAt(0);
    }
  }

  /// Check performance thresholds and emit alerts
  void _checkThresholds(String operationName, PerformanceMetric metric) {
    // Check for slow operations
    if (metric.duration > _slowOperationThreshold) {
      _alertController.add(PerformanceAlert(
        type: AlertType.slowOperation,
        operationName: operationName,
        message: 'Operation took ${metric.duration.inMilliseconds}ms',
        severity: metric.duration > Duration(seconds: 5) ? AlertSeverity.high : AlertSeverity.medium,
        metric: metric,
      ));
    }
    
    // Check for memory leaks
    if (metric.memoryDelta > 50 * 1024 * 1024) { // 50MB increase
      _alertController.add(PerformanceAlert(
        type: AlertType.memoryLeak,
        operationName: operationName,
        message: 'Memory increased by ${(metric.memoryDelta / (1024 * 1024)).toStringAsFixed(1)}MB',
        severity: AlertSeverity.high,
        metric: metric,
      ));
    }
    
    // Check for operation failures
    if (!metric.success) {
      final stats = _operationStats[operationName];
      if (stats != null && stats.failureRate > 0.1) { // >10% failure rate
        _alertController.add(PerformanceAlert(
          type: AlertType.highFailureRate,
          operationName: operationName,
          message: 'Failure rate: ${(stats.failureRate * 100).toStringAsFixed(1)}%',
          severity: AlertSeverity.high,
          metric: metric,
        ));
      }
    }
  }

  /// Update memory tracking
  void _updateMemoryTracking(int memoryUsage) {
    _currentMemory = memoryUsage;
    if (memoryUsage > _peakMemory) {
      _peakMemory = memoryUsage;
    }
    
    // Check for high memory usage
    if (memoryUsage > _maxMemoryUsageMB * 1024 * 1024) {
      _alertController.add(PerformanceAlert(
        type: AlertType.highMemoryUsage,
        operationName: 'system',
        message: 'Memory usage: ${(memoryUsage / (1024 * 1024)).toStringAsFixed(1)}MB',
        severity: AlertSeverity.critical,
        metric: PerformanceMetric(
          operationName: 'system',
          duration: Duration.zero,
          memoryUsage: memoryUsage,
          memoryDelta: 0,
          success: true,
          timestamp: DateTime.now(),
        ),
      ));
    }
  }

  /// Get current memory usage
  int _getCurrentMemoryUsage() {
    try {
      final info = ProcessInfo.currentRss;
      return info;
    } catch (e) {
      return 0;
    }
  }

  /// Perform comprehensive health check
  void _performHealthCheck() {
    final currentMemory = _getCurrentMemoryUsage();
    final memoryGrowth = currentMemory - _initialMemory;
    
    // Check for memory growth
    if (memoryGrowth > 100 * 1024 * 1024) { // 100MB growth
      _alertController.add(PerformanceAlert(
        type: AlertType.memoryGrowth,
        operationName: 'system',
        message: 'Memory grew by ${(memoryGrowth / (1024 * 1024)).toStringAsFixed(1)}MB since start',
        severity: AlertSeverity.medium,
        metric: PerformanceMetric(
          operationName: 'system',
          duration: Duration.zero,
          memoryUsage: currentMemory,
          memoryDelta: memoryGrowth,
          success: true,
          timestamp: DateTime.now(),
        ),
      ));
    }
    
    // Check operation health
    for (final entry in _operationStats.entries) {
      final operationName = entry.key;
      final stats = entry.value;
      
      if (stats.averageDuration > _slowOperationThreshold) {
        _alertController.add(PerformanceAlert(
          type: AlertType.slowAverageOperation,
          operationName: operationName,
          message: 'Average duration: ${stats.averageDuration.inMilliseconds}ms',
          severity: AlertSeverity.medium,
        ));
      }
    }
  }

  /// Clean old metrics to prevent memory leaks
  void _cleanupOldMetrics() {
    final cutoffTime = DateTime.now().subtract(Duration(hours: 1));
    
    for (final entry in _metrics.entries) {
      final operationName = entry.key;
      final metrics = entry.value;
      
      metrics.removeWhere((metric) => metric.timestamp.isBefore(cutoffTime));
    }
  }

  /// Get comprehensive performance report
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};
    
    for (final entry in _metrics.entries) {
      final operationName = entry.key;
      final metrics = entry.value;
      final stats = _operationStats[operationName];
      
      if (metrics.isNotEmpty) {
        report[operationName] = {
          'count': metrics.length,
          'avgDuration': stats?.averageDuration.inMilliseconds ?? 0,
          'maxDuration': stats?.maxDuration.inMilliseconds ?? 0,
          'minDuration': stats?.minDuration.inMilliseconds ?? 0,
          'avgMemoryUsage': stats?.averageMemoryUsage ~/ (1024 * 1024) ?? 0, // MB
          'maxMemoryUsage': stats?.maxMemoryUsage ~/ (1024 * 1024) ?? 0, // MB
          'successRate': stats?.successRate ?? 0.0,
          'failureRate': stats?.failureRate ?? 0.0,
          'totalOperations': stats?.totalOperations ?? 0,
          'lastExecution': metrics.last.timestamp.toIso8601String(),
        };
      }
    }
    
    return report;
  }

  /// Get slow operations
  List<PerformanceMetric> getSlowOperations({Duration? threshold}) {
    final slowThreshold = threshold ?? _slowOperationThreshold;
    final slowOps = <PerformanceMetric>[];
    
    for (final metrics in _metrics.values) {
      slowOps.addAll(metrics.where((metric) => metric.duration > slowThreshold));
    }
    
    slowOps.sort((a, b) => b.duration.compareTo(a.duration));
    return slowOps;
  }

  /// Get optimization suggestions
  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];
    
    // Analyze slow operations
    final slowOps = getSlowOperations();
    if (slowOps.isNotEmpty) {
      final slowestOp = slowOps.first;
      suggestions.add('Optimize ${slowestOp.operationName} - took ${slowestOp.duration.inMilliseconds}ms');
    }
    
    // Analyze memory usage
    if (_peakMemory > _initialMemory + 50 * 1024 * 1024) {
      suggestions.add('Memory usage increased by ${((_peakMemory - _initialMemory) / (1024 * 1024)).toStringAsFixed(1)}MB - check for leaks');
    }
    
    // Analyze failure rates
    for (final entry in _operationStats.entries) {
      final operationName = entry.key;
      final stats = entry.value;
      
      if (stats.failureRate > 0.05) { // >5% failure rate
        suggestions.add('High failure rate for $operationName: ${(stats.failureRate * 100).toStringAsFixed(1)}%');
      }
    }
    
    if (suggestions.isEmpty) {
      suggestions.add('Performance is optimal');
    }
    
    return suggestions;
  }

  /// Get memory statistics
  Map<String, dynamic> getMemoryStatistics() {
    return {
      'initialMemoryMB': _initialMemory ~/ (1024 * 1024),
      'currentMemoryMB': _currentMemory ~/ (1024 * 1024),
      'peakMemoryMB': _peakMemory ~/ (1024 * 1024),
      'memoryGrowthMB': (_currentMemory - _initialMemory) ~/ (1024 * 1024),
      'isMonitoring': _isMonitoring,
    };
  }

  /// Get system health score (0-100)
  double getHealthScore() {
    double score = 100.0;
    
    // Deduct points for slow operations
    final slowOps = getSlowOperations();
    score -= math.min(slowOps.length * 5.0, 30.0);
    
    // Deduct points for high memory usage
    final memoryGrowthMB = (_currentMemory - _initialMemory) / (1024 * 1024);
    if (memoryGrowthMB > 50) {
      score -= math.min(memoryGrowthMB, 20.0);
    }
    
    // Deduct points for high failure rates
    for (final stats in _operationStats.values) {
      if (stats.failureRate > 0.1) {
        score -= stats.failureRate * 50;
      }
    }
    
    return math.max(0.0, score);
  }

  /// Reset all metrics
  void resetMetrics() {
    _metrics.clear();
    _operationStats.clear();
    _initialMemory = _getCurrentMemoryUsage();
    _peakMemory = _initialMemory;
    _currentMemory = _initialMemory;
    
    print('Performance metrics reset');
  }

  /// Export metrics for analysis
  Map<String, dynamic> exportMetrics() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'isMonitoring': _isMonitoring,
      'memoryStats': getMemoryStatistics(),
      'healthScore': getHealthScore(),
      'performanceReport': getPerformanceReport(),
      'optimizationSuggestions': getOptimizationSuggestions(),
      'slowOperations': getSlowOperations().map((m) => m.toJson()).toList(),
      'operationStats': _operationStats.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _alertController.close();
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String operationName;
  final Duration duration;
  final int memoryUsage;
  final int memoryDelta;
  final bool success;
  final DateTime timestamp;
  final String? error;

  PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.memoryUsage,
    required this.memoryDelta,
    required this.success,
    required this.timestamp,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'operationName': operationName,
      'duration': duration.inMilliseconds,
      'memoryUsage': memoryUsage,
      'memoryDelta': memoryDelta,
      'success': success,
      'timestamp': timestamp.toIso8601String(),
      'error': error,
    };
  }
}

/// Operation statistics
class OperationStats {
  int totalOperations = 0;
  int successfulOperations = 0;
  int failedOperations = 0;
  Duration totalDuration = Duration.zero;
  int totalMemoryUsage = 0;
  Duration maxDuration = Duration.zero;
  Duration minDuration = Duration.infinite;
  int maxMemoryUsage = 0;
  int minMemoryUsage = 0x7fffffff;

  void update(PerformanceMetric metric) {
    totalOperations++;
    totalDuration += metric.duration;
    totalMemoryUsage += metric.memoryUsage;
    
    if (metric.success) {
      successfulOperations++;
    } else {
      failedOperations++;
    }
    
    if (metric.duration > maxDuration) {
      maxDuration = metric.duration;
    }
    if (metric.duration < minDuration) {
      minDuration = metric.duration;
    }
    
    if (metric.memoryUsage > maxMemoryUsage) {
      maxMemoryUsage = metric.memoryUsage;
    }
    if (metric.memoryUsage < minMemoryUsage) {
      minMemoryUsage = metric.memoryUsage;
    }
  }

  Duration get averageDuration => totalOperations > 0 
      ? Duration(milliseconds: totalDuration.inMilliseconds ~/ totalOperations)
      : Duration.zero;
  
  int get averageMemoryUsage => totalOperations > 0 
      ? totalMemoryUsage ~/ totalOperations
      : 0;
  
  double get successRate => totalOperations > 0 
      ? successfulOperations / totalOperations
      : 0.0;
  
  double get failureRate => totalOperations > 0 
      ? failedOperations / totalOperations
      : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'totalOperations': totalOperations,
      'successfulOperations': successfulOperations,
      'failedOperations': failedOperations,
      'averageDuration': averageDuration.inMilliseconds,
      'maxDuration': maxDuration.inMilliseconds,
      'minDuration': minDuration == Duration.infinite ? 0 : minDuration.inMilliseconds,
      'averageMemoryUsage': averageMemoryUsage,
      'maxMemoryUsage': maxMemoryUsage,
      'minMemoryUsage': minMemoryUsage == 0x7fffffff ? 0 : minMemoryUsage,
      'successRate': successRate,
      'failureRate': failureRate,
    };
  }
}

/// Performance alert
class PerformanceAlert {
  final AlertType type;
  final AlertSeverity severity;
  final String operationName;
  final String message;
  final DateTime timestamp;
  final PerformanceMetric? metric;

  PerformanceAlert({
    required this.type,
    required this.severity,
    required this.operationName,
    required this.message,
    PerformanceMetric? metric,
  }) : timestamp = DateTime.now(),
       metric = metric;

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'severity': severity.toString(),
      'operationName': operationName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'metric': metric?.toJson(),
    };
  }
}

/// Alert types
enum AlertType {
  slowOperation,
  slowAverageOperation,
  memoryLeak,
  highMemoryUsage,
  memoryGrowth,
  highFailureRate,
}

/// Alert severity
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}
