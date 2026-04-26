/// Test configuration for the Network App test suite
/// 
/// This file contains shared test configuration and utilities
/// to ensure consistent testing across all test files.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

/// Test configuration constants
class TestConfig {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(minutes: 2);
  
  static const String testDeviceName = 'TestDevice';
  static const String testPassword = 'test-password-123';
  static const String testMessage = 'Test message content';
}

/// Test utilities
class TestUtils {
  /// Creates a test widget wrapper for testing Flutter widgets
  static Widget createTestWidget({required Widget child}) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }
  
  /// Creates a test app context
  static Widget createTestApp({required Widget home}) {
    return MaterialApp(
      title: 'Test App',
      home: home,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
    );
  }
  
  /// Waits for a specified duration
  static Future<void> wait([Duration? duration]) {
    return Future.delayed(duration ?? TestConfig.shortTimeout);
  }
  
  /// Creates test data for encryption tests
  static Map<String, dynamic> createTestData() {
    return {
      'content': TestConfig.testMessage,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sender': TestConfig.testDeviceName,
      'type': 'test',
    };
  }
  
  /// Validates encrypted message structure
  static bool isValidEncryptedMessage(Map<String, dynamic> message) {
    return message.containsKey('encrypted') &&
           message.containsKey('algorithm') &&
           message.containsKey('data') &&
           message.containsKey('salt') &&
           message.containsKey('iv') &&
           message.containsKey('timestamp');
  }
}

/// Test fixtures for common test scenarios
class TestFixtures {
  /// Creates a mock mesh node for testing
  static Map<String, dynamic> createMockMeshNode({
    required String id,
    String name = 'TestNode',
    List<String>? neighbors,
  }) {
    return {
      'id': id,
      'name': name,
      'neighbors': neighbors ?? ['node1', 'node2'],
      'hopCount': 0,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
      'signalStrength': 0.8,
      'metadata': {'test': true},
    };
  }
  
  /// Creates test performance metrics
  static Map<String, dynamic> createPerformanceMetrics({
    required String operation,
    required int durationMs,
    required int memoryUsage,
  }) {
    return {
      'operation': operation,
      'duration': durationMs,
      'memoryUsage': memoryUsage,
      'cpuUsage': 50,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

/// Custom test exceptions for better error handling
class TestException implements Exception {
  final String message;
  final String? stackTrace;
  
  const TestException(this.message, [this.stackTrace]);
  
  @override
  String toString() => 'TestException: $message${stackTrace != null ? '\n$stackTrace' : ''}';
}

/// Test helper for async operations
class AsyncTestHelper {
  /// Executes an async operation with timeout
  static Future<T> withTimeout<T>(
    Future<T> Function() operation, {
    Duration? timeout,
  }) async {
    return await operation().timeout(
      timeout ?? TestConfig.defaultTimeout,
      onTimeout: () => throw TestException('Operation timed out'),
    );
  }
  
  /// Executes an async operation and expects an exception
  static Future<void> expectException<T extends Exception>(
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
      throw TestException('Expected exception of type $T but none was thrown');
    } catch (e) {
      if (e is! T) {
        rethrow;
      }
    }
  }
}

/// Test data generators
class TestDataGenerator {
  /// Generates a random string of specified length
  static String randomString([int length = 10]) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return String.fromCharCodes(Iterable.generate(
      length,
      (i) => chars.codeUnitAt((random + i) % chars.length),
    ));
  }
  
  /// Generates a list of test messages
  static List<Map<String, dynamic>> generateTestMessages(int count) {
    return List.generate(count, (index) => {
      'content': 'Test message $index',
      'timestamp': DateTime.now().millisecondsSinceEpoch + index,
      'sender': 'Sender${index % 5}',
      'type': 'test',
    });
  }
  
  /// Generates test network topology
  static List<Map<String, dynamic>> generateTestTopology(int nodeCount) {
    return List.generate(nodeCount, (index) => TestFixtures.createMockMeshNode(
      id: 'node$index',
      name: 'TestNode$index',
      neighbors: index > 0 ? ['node${index - 1}'] : [],
    ));
  }
}
