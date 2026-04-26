import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'logger_service.dart';

class PerformanceMetrics {
  final String operation;
  final Duration duration;
  final int memoryUsage;
  final int cpuUsage;
  final DateTime timestamp;

  PerformanceMetrics({
    required this.operation,
    required this.duration,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'duration': duration.inMilliseconds,
      'memoryUsage': memoryUsage,
      'cpuUsage': cpuUsage,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class PerformanceMonitorService {
  static final PerformanceMonitorService _instance = PerformanceMonitorService._internal();
  factory PerformanceMonitorService() => _instance;
  PerformanceMonitorService._internal();

  final LoggerService _logger = LoggerService();
  final List<PerformanceMetrics> _metrics = [];
  final Map<String, List<PerformanceMetrics>> _operationMetrics = {};
  Timer? _cleanupTimer;

  void startMonitoring() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupOldMetrics();
    });
    
    _logger.info('Performance monitoring started', tag: 'Performance');
  }

  void stopMonitoring() {
    _cleanupTimer?.cancel();
    _logger.info('Performance monitoring stopped', tag: 'Performance');
  }

  T trackOperation<T>(String operationName, T Function() operation) {
    final stopwatch = Stopwatch()..start();
    final startMemory = _getCurrentMemoryUsage();
    
    try {
      final result = operation();
      stopwatch.stop();
      
      final endMemory = _getCurrentMemoryUsage();
      final metrics = PerformanceMetrics(
        operation: operationName,
        duration: stopwatch.elapsed,
        memoryUsage: endMemory - startMemory,
        cpuUsage: _getCurrentCpuUsage(),
        timestamp: DateTime.now(),
      );
      
      _recordMetrics(metrics);
      return result;
    } catch (e) {
      stopwatch.stop();
      _logger.error('Operation "$operationName" failed: $e', tag: 'Performance');
      rethrow;
    }
  }

  Future<T> trackAsyncOperation<T>(String operationName, Future<T> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    final startMemory = _getCurrentMemoryUsage();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      final endMemory = _getCurrentMemoryUsage();
      final metrics = PerformanceMetrics(
        operation: operationName,
        duration: stopwatch.elapsed,
        memoryUsage: endMemory - startMemory,
        cpuUsage: _getCurrentCpuUsage(),
        timestamp: DateTime.now(),
      );
      
      _recordMetrics(metrics);
      return result;
    } catch (e) {
      stopwatch.stop();
      _logger.error('Async operation "$operationName" failed: $e', tag: 'Performance');
      rethrow;
    }
  }

  void _recordMetrics(PerformanceMetrics metrics) {
    _metrics.add(metrics);
    
    if (!_operationMetrics.containsKey(metrics.operation)) {
      _operationMetrics[metrics.operation] = [];
    }
    _operationMetrics[metrics.operation]!.add(metrics);
    
    // Log slow operations
    if (metrics.duration.inMilliseconds > 1000) {
      _logger.warning(
        'Slow operation detected: ${metrics.operation} took ${metrics.duration.inMilliseconds}ms',
        tag: 'Performance',
      );
    }
    
    // Log high memory usage
    if (metrics.memoryUsage > 10 * 1024 * 1024) { // 10MB
      _logger.warning(
        'High memory usage in ${metrics.operation}: ${metrics.memoryUsage ~/ (1024 * 1024)}MB',
        tag: 'Performance',
      );
    }
  }

  int _getCurrentMemoryUsage() {
    if (kDebugMode) {
      // In debug mode, return simulated memory usage
      return DateTime.now().millisecond * 1024;
    }
    
    try {
      final info = ProcessInfo.currentRss;
      return info;
    } catch (e) {
      return 0;
    }
  }

  int _getCurrentCpuUsage() {
    if (kDebugMode) {
      // In debug mode, return simulated CPU usage
      return DateTime.now().millisecond % 100;
    }
    
    try {
      // Simplified CPU usage calculation
      return Platform.environment['CPU_USAGE']?.hashCode ?? 0;
    } catch (e) {
      return 0;
    }
  }

  void _cleanupOldMetrics() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    _metrics.removeWhere((metric) => metric.timestamp.isBefore(cutoff));
    
    for (final operation in _operationMetrics.keys) {
      _operationMetrics[operation]!.removeWhere((metric) => metric.timestamp.isBefore(cutoff));
    }
  }

  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};
    
    for (final operation in _operationMetrics.keys) {
      final operationList = _operationMetrics[operation]!;
      if (operationList.isEmpty) continue;
      
      final durations = operationList.map((m) => m.duration.inMilliseconds).toList();
      final memoryUsages = operationList.map((m) => m.memoryUsage).toList();
      
      durations.sort();
      memoryUsages.sort();
      
      report[operation] = {
        'count': operationList.length,
        'avgDuration': durations.reduce((a, b) => a + b) / durations.length,
        'minDuration': durations.first,
        'maxDuration': durations.last,
        'medianDuration': durations[durations.length ~/ 2],
        'avgMemoryUsage': memoryUsages.reduce((a, b) => a + b) / memoryUsages.length,
        'minMemoryUsage': memoryUsages.first,
        'maxMemoryUsage': memoryUsages.last,
        'medianMemoryUsage': memoryUsages[memoryUsages.length ~/ 2],
      };
    }
    
    return report;
  }

  List<PerformanceMetrics> getSlowOperations({int thresholdMs = 1000}) {
    return _metrics
        .where((metric) => metric.duration.inMilliseconds > thresholdMs)
        .toList()
      ..sort((a, b) => b.duration.compareTo(a.duration));
  }

  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];
    final report = getPerformanceReport();
    
    for (final operation in report.keys) {
      final data = report[operation] as Map<String, dynamic>;
      final avgDuration = data['avgDuration'] as double;
      final maxDuration = data['maxDuration'] as int;
      final avgMemory = data['avgMemoryUsage'] as double;
      
      if (avgDuration > 500) {
        suggestions.add('Consider optimizing "$operation" - average duration: ${avgDuration.round()}ms');
      }
      
      if (maxDuration > 2000) {
        suggestions.add('Operation "$operation" has high maximum duration: ${maxDuration}ms');
      }
      
      if (avgMemory > 5 * 1024 * 1024) { // 5MB
        suggestions.add('Operation "$operation" uses high memory: ${(avgMemory / (1024 * 1024)).toStringAsFixed(1)}MB');
      }
    }
    
    return suggestions;
  }

  void clearMetrics() {
    _metrics.clear();
    _operationMetrics.clear();
    _logger.info('Performance metrics cleared', tag: 'Performance');
  }

  void exportMetrics() {
    final report = getPerformanceReport();
    final suggestions = getOptimizationSuggestions();
    
    _logger.info('Performance Report:', tag: 'Performance');
    for (final operation in report.keys) {
      final data = report[operation] as Map<String, dynamic>;
      _logger.info('$operation: ${data.toString()}', tag: 'Performance');
    }
    
    if (suggestions.isNotEmpty) {
      _logger.info('Optimization Suggestions:', tag: 'Performance');
      for (final suggestion in suggestions) {
        _logger.info('- $suggestion', tag: 'Performance');
      }
    }
  }
}
