import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../lib/services/encryption_service.dart';
import '../lib/services/advanced_encryption_service.dart';
import '../lib/services/error_handling_service.dart';
import '../lib/services/performance_monitor_service.dart';
import '../lib/services/advanced_mesh_routing_service.dart';

void main() {
  group('EncryptionService Tests', () {
    late EncryptionService encryptionService;

    setUp(() {
      encryptionService = EncryptionService();
    });

    test('should generate session key', () {
      final key = encryptionService.generateSessionKey();
      expect(key, isNotEmpty);
      expect(key.length, 32);
    });

    test('should encrypt and decrypt messages', () {
      final originalMessage = 'Hello, World!';
      final key = encryptionService.generateSessionKey();
      
      final encrypted = encryptionService.encryptMessage(originalMessage, key);
      expect(encrypted['encrypted'], isTrue);
      expect(encrypted['data'], isNotEmpty);
      
      final decrypted = encryptionService.decryptMessage(encrypted);
      expect(decrypted, equals(originalMessage));
    });

    test('should handle device ID hashing', () {
      final deviceId = 'test-device-123';
      final hashed = encryptionService.hashDeviceId(deviceId);
      expect(hashed, isNotEmpty);
      expect(hashed, isNot(equals(deviceId)));
    });
  });

  group('AdvancedEncryptionService Tests', () {
    late AdvancedEncryptionService advancedEncryption;

    setUp(() {
      advancedEncryption = AdvancedEncryptionService();
    });

    test('should generate secure key', () {
      final key = advancedEncryption._generateSecureKey();
      expect(key, isNotEmpty);
      expect(base64.decode(key), hasLength(32)); // 256 bits
    });

    test('should encrypt with AES-256', () {
      final message = 'Secret message';
      final password = 'secure-password';
      
      final encrypted = advancedEncryption.encryptMessageAES(message, password);
      expect(encrypted['encrypted'], isTrue);
      expect(encrypted['algorithm'], equals('AES-256-GCM'));
      expect(encrypted['salt'], isNotEmpty);
      expect(encrypted['iv'], isNotEmpty);
    });

    test('should decrypt AES encrypted messages', () {
      final message = 'Secret message';
      final password = 'secure-password';
      
      final encrypted = advancedEncryption.encryptMessageAES(message, password);
      final decrypted = advancedEncryption.decryptMessageAES(encrypted, password);
      
      expect(decrypted, equals(message));
    });

    test('should verify message integrity', () {
      final message = {'content': 'test', 'timestamp': 1234567890};
      final hash = advancedEncryption.calculateMessageHash(message);
      
      expect(advancedEncryption.verifyMessageIntegrity(message, hash), isTrue);
      expect(advancedEncryption.verifyMessageIntegrity(message, 'invalid-hash'), isFalse);
    });

    test('should generate unique device fingerprints', () {
      final fingerprint1 = advancedEncryption.generateDeviceFingerprint();
      final fingerprint2 = advancedEncryption.generateDeviceFingerprint();
      
      expect(fingerprint1, isNotEmpty);
      expect(fingerprint2, isNotEmpty);
      expect(fingerprint1, isNot(equals(fingerprint2)));
    });
  });

  group('ErrorHandlingService Tests', () {
    late ErrorHandlingService errorService;

    setUp(() {
      errorService = ErrorHandlingService();
    });

    test('should retry failed operations', () async {
      var attemptCount = 0;
      Future<String> operation() async {
        attemptCount++;
        if (attemptCount < 3) {
          throw Exception('Temporary failure');
        }
        return 'success';
      }

      final result = await errorService.executeWithRetry(operation, 'test');
      expect(result, equals('success'));
      expect(attemptCount, equals(3));
    });

    test('should handle errors with fallback', () async {
      final result = await errorService.executeWithErrorHandling(
        () => throw Exception('Error'),
        'test',
        fallbackValue: 'fallback',
      );
      
      expect(result, equals('fallback'));
    });

    test('should track error statistics', () {
      // Simulate some errors
      errorService._logError('test-error', Exception('Test error'), null);
      errorService._logError('test-error', Exception('Test error'), null);
      
      final stats = errorService.getErrorStatistics();
      expect(stats['totalErrors'], greaterThan(0));
    });
  });

  group('PerformanceMonitorService Tests', () {
    late PerformanceMonitorService performanceService;

    setUp(() {
      performanceService = PerformanceMonitorService();
      performanceService.startMonitoring();
    });

    tearDown(() {
      performanceService.stopMonitoring();
    });

    test('should track operation performance', () {
      final result = performanceService.trackOperation('test-op', () => 'test-result');
      expect(result, equals('test-result'));
    });

    test('should generate performance reports', () {
      // Track some operations
      performanceService.trackOperation('test-op-1', () => 'result1');
      performanceService.trackOperation('test-op-2', () => 'result2');
      
      final report = performanceService.getPerformanceReport();
      expect(report, isA<Map<String, dynamic>>());
    });

    test('should identify slow operations', () {
      // Simulate a slow operation
      performanceService.trackOperation('slow-op', () {
        // Simulate slow work
        final data = List.generate(10000, (index) => index);
        return data.length;
      });
      
      final slowOps = performanceService.getSlowOperations(thresholdMs: 0);
      expect(slowOps, isA<List>());
    });
  });

  group('AdvancedMeshRoutingService Tests', () {
    late AdvancedMeshRoutingService routingService;

    setUp(() {
      routingService = AdvancedMeshRoutingService();
      routingService.initialize();
    });

    tearDown(() {
      routingService.dispose();
    });

    test('should add and remove nodes', () {
      final node = MeshNode(
        id: 'node1',
        name: 'Test Node',
        neighbors: ['node2'],
        lastSeen: DateTime.now(),
      );

      routingService.addNode(node);
      
      final stats = routingService.getNetworkStatistics();
      expect(stats['nodeCount'], equals(1));

      routingService.removeNode('node1');
      
      final statsAfter = routingService.getNetworkStatistics();
      expect(statsAfter['nodeCount'], equals(0));
    });

    test('should calculate network statistics', () {
      // Add some test nodes
      for (int i = 0; i < 5; i++) {
        final node = MeshNode(
          id: 'node-$i',
          name: 'Node $i',
          neighbors: [],
          lastSeen: DateTime.now(),
        );
        routingService.addNode(node);
      }
      
      final stats = routingService.getNetworkStatistics();
      expect(stats['nodeCount'], equals(5));
    });

    test('should handle load balancing', () {
      // Add test nodes
      final node1 = MeshNode(
        id: 'node1',
        name: 'Node 1',
        neighbors: ['node2'],
        lastSeen: DateTime.now(),
      );
      final node2 = MeshNode(
        id: 'node2',
        name: 'Node 2',
        neighbors: ['node1'],
        lastSeen: DateTime.now(),
      );
      
      routingService.addNode(node1);
      routingService.addNode(node2);
      
      final path = routingService.routeMessageWithLoadBalancing(
        'node2',
        {'content': 'test'},
      );
      
      expect(path, isA<List<String>>());
    });
  });

  group('Integration Tests', () {
    test('should handle complete message flow', () async {
      // Test complete flow from encryption to routing to delivery
      final encryptionService = AdvancedEncryptionService();
      final routingService = AdvancedMeshRoutingService();
      
      // Initialize services
      routingService.initialize();
      
      // Create test message
      final message = {'content': 'test message', 'type': 'chat'};
      final password = 'test-password';
      
      // Encrypt message
      final encrypted = encryptionService.encryptMessageAES(
        json.encode(message),
        password,
      );
      
      expect(encrypted['encrypted'], isTrue);
      
      // Route message
      final path = routingService.routeMessageWithLoadBalancing(
        'destination',
        encrypted,
      );
      
      // Verify routing
      expect(path, isA<List<String>>());
      
      // Clean up
      routingService.dispose();
    });

    test('should handle network failures gracefully', () async {
      final errorService = ErrorHandlingService();
      final performanceService = PerformanceMonitorService();
      
      // Start monitoring
      performanceService.startMonitoring();
      
      // Simulate network operation with failure
      var attemptCount = 0;
      Future<String> networkOperation() async {
        attemptCount++;
        if (attemptCount < 2) {
          throw Exception('Network timeout');
        }
        return 'success';
      }
      
      final result = await errorService.executeWithRetry(
        networkOperation,
        'network-operation',
        maxRetries: 3,
      );
      
      expect(result, equals('success'));
      expect(attemptCount, equals(2));
      
      // Stop monitoring
      performanceService.stopMonitoring();
    });
  });

  group('Performance Tests', () {
    test('should handle high message throughput', () async {
      final routingService = AdvancedMeshRoutingService();
      routingService.initialize();
      
      final stopwatch = Stopwatch()..start();
      const messageCount = 100; // Reduced for test performance
      
      for (int i = 0; i < messageCount; i++) {
        routingService.routeMessageWithLoadBalancing(
          'destination-$i',
          {'content': 'message $i'},
        );
      }
      
      stopwatch.stop();
      
      final messagesPerSecond = messageCount / (stopwatch.elapsedMilliseconds / 1000);
      expect(messagesPerSecond, greaterThan(10)); // Reduced threshold for testing
      
      routingService.dispose();
    });

    test('should handle large network topology', () {
      final routingService = AdvancedMeshRoutingService();
      routingService.initialize();
      
      // Create large network
      const nodeCount = 20; // Reduced for test performance
      for (int i = 0; i < nodeCount; i++) {
        final node = MeshNode(
          id: 'node-$i',
          name: 'Node $i',
          neighbors: i > 0 ? ['node-${i - 1}'] : [],
          lastSeen: DateTime.now(),
        );
        routingService.addNode(node);
      }
      
      final stats = routingService.getNetworkStatistics();
      expect(stats['nodeCount'], equals(nodeCount));
      
      routingService.dispose();
    });
  });

  group('Security Tests', () {
    test('should prevent message tampering', () {
      final encryptionService = AdvancedEncryptionService();
      final message = {'content': 'secure message'};
      
      final encrypted = encryptionService.encryptMessageAES(
        json.encode(message),
        'password',
      );
      
      // Tamper with encrypted data
      final tampered = Map<String, dynamic>.from(encrypted);
      tampered['data'] = base64.encode([1, 2, 3, 4]); // Invalid data
      
      expect(() => encryptionService.decryptMessageAES(tampered, 'password'),
          throwsException);
    });

    test('should use unique salts for encryption', () {
      final encryptionService = AdvancedEncryptionService();
      final message = 'test message';
      final password = 'password';
      
      final encrypted1 = encryptionService.encryptMessageAES(message, password);
      final encrypted2 = encryptionService.encryptMessageAES(message, password);
      
      expect(encrypted1['salt'], isNot(equals(encrypted2['salt'])));
      expect(encrypted1['iv'], isNot(equals(encrypted2['iv'])));
    });
  });
}
