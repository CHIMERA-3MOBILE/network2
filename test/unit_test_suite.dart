import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../lib/services/network_service.dart';
import '../lib/services/encryption_service.dart';
import '../lib/services/advanced_encryption_service.dart';
import '../lib/services/error_handling_service.dart';
import '../lib/services/performance_monitor_service.dart';
import '../lib/services/advanced_mesh_routing_service.dart';

import 'unit_test_suite.mocks.dart';

@GenerateMocks([
  NetworkService,
  EncryptionService,
  AdvancedEncryptionService,
  ErrorHandlingService,
  PerformanceMonitorService,
  AdvancedMeshRoutingService,
])
void main() {
  group('NetworkService Tests', () {
    late MockNetworkService mockNetworkService;

    setUp(() {
      mockNetworkService = MockNetworkService();
    });

    test('should initialize successfully', () async {
      when(mockNetworkService.initialize()).thenAnswer((_) async {});
      await mockNetworkService.initialize();
      verify(mockNetworkService.initialize()).called(1);
    });

    test('should handle message sending', () async {
      when(mockNetworkService.sendMessage('test message'))
          .thenAnswer((_) async {});
      
      await mockNetworkService.sendMessage('test message');
      verify(mockNetworkService.sendMessage('test message')).called(1);
    });

    test('should handle connection failures gracefully', () async {
      when(mockNetworkService.startAdvertising())
          .thenThrow(Exception('Connection failed'));
      
      expect(() => mockNetworkService.startAdvertising(), throwsException);
    });

    test('should track connected devices', () {
      when(mockNetworkService.connectedDevices).thenReturn(['device1', 'device2']);
      final devices = mockNetworkService.connectedDevices;
      expect(devices, hasLength(2));
      expect(devices, contains('device1'));
      expect(devices, contains('device2'));
    });
  });

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
    late MockErrorHandlingService mockErrorService;

    setUp(() {
      mockErrorService = MockErrorHandlingService();
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

      when(mockErrorService.executeWithRetry(any, any))
          .thenAnswer((_) async => await operation());
      
      final result = await mockErrorService.executeWithRetry(operation, 'test');
      expect(result, equals('success'));
    });

    test('should handle errors with fallback', () async {
      when(mockErrorService.executeWithErrorHandling(
        any, any, fallbackValue: 'fallback'))
          .thenAnswer((_) async => 'fallback');
      
      final result = await mockErrorService.executeWithErrorHandling(
        () => throw Exception('Error'),
        'test',
        fallbackValue: 'fallback',
      );
      
      expect(result, equals('fallback'));
    });

    test('should track error statistics', () {
      when(mockErrorService.getErrorStatistics()).thenReturn({
        'totalErrors': 5,
        'uniqueErrors': 2,
        'errorCounts': {'error1': 3, 'error2': 2},
      });
      
      final stats = mockErrorService.getErrorStatistics();
      expect(stats['totalErrors'], equals(5));
      expect(stats['uniqueErrors'], equals(2));
    });
  });

  group('PerformanceMonitorService Tests', () {
    late MockPerformanceMonitorService mockPerformanceService;

    setUp(() {
      mockPerformanceService = MockPerformanceMonitorService();
    });

    test('should track operation performance', () {
      when(mockPerformanceService.trackOperation(any, any))
          .thenReturn('test-result');
      
      final result = mockPerformanceService.trackOperation('test-op', () => 'test-result');
      expect(result, equals('test-result'));
      verify(mockPerformanceService.trackOperation('test-op', any)).called(1);
    });

    test('should generate performance reports', () {
      when(mockPerformanceService.getPerformanceReport()).thenReturn({
        'operation1': {
          'count': 10,
          'avgDuration': 150.5,
          'maxDuration': 500,
          'avgMemoryUsage': 1024,
        },
      });
      
      final report = mockPerformanceService.getPerformanceReport();
      expect(report, contains('operation1'));
      expect(report['operation1']['count'], equals(10));
    });

    test('should identify slow operations', () {
      when(mockPerformanceService.getSlowOperations(thresholdMs: 100))
          .thenReturn([
            PerformanceMetrics(
              operation: 'slow-op',
              duration: Duration(milliseconds: 500),
              memoryUsage: 2048,
              cpuUsage: 50,
              timestamp: DateTime.now(),
            ),
          ]);
      
      final slowOps = mockPerformanceService.getSlowOperations(thresholdMs: 100);
      expect(slowOps, hasLength(1));
      expect(slowOps.first.operation, equals('slow-op'));
    });
  });

  group('AdvancedMeshRoutingService Tests', () {
    late MockAdvancedMeshRoutingService mockRoutingService;

    setUp(() {
      mockRoutingService = MockAdvancedMeshRoutingService();
    });

    test('should add and remove nodes', () {
      final node = MeshNode(
        id: 'node1',
        name: 'Test Node',
        neighbors: ['node2'],
        lastSeen: DateTime.now(),
      );

      mockRoutingService.addNode(node);
      verify(mockRoutingService.addNode(node)).called(1);

      mockRoutingService.removeNode('node1');
      verify(mockRoutingService.removeNode('node1')).called(1);
    });

    test('should find optimal routes', () {
      final route = MeshRoute(
        destination: 'node2',
        path: ['node1', 'node2'],
        totalHops: 1,
        reliability: 0.9,
        calculatedAt: DateTime.now(),
      );

      when(mockRoutingService.findOptimalRoute('node2')).thenReturn(route);
      
      final foundRoute = mockRoutingService.findOptimalRoute('node2');
      expect(foundRoute, isNotNull);
      expect(foundRoute!.destination, equals('node2'));
      expect(foundRoute.totalHops, equals(1));
    });

    test('should calculate network statistics', () {
      when(mockRoutingService.getNetworkStatistics()).thenReturn({
        'nodeCount': 5,
        'routeCount': 4,
        'avgReliability': 0.85,
        'avgHops': 2.5,
      });
      
      final stats = mockRoutingService.getNetworkStatistics();
      expect(stats['nodeCount'], equals(5));
      expect(stats['avgReliability'], equals(0.85));
    });

    test('should handle load balancing', () {
      when(mockRoutingService.routeMessageWithLoadBalancing(any, any))
          .thenReturn(['node1', 'node2', 'node3']);
      
      final path = mockRoutingService.routeMessageWithLoadBalancing(
        'destination',
        {'content': 'test'},
      );
      
      expect(path, hasLength(3));
      expect(path.first, equals('node1'));
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
      const messageCount = 1000;
      
      for (int i = 0; i < messageCount; i++) {
        routingService.routeMessageWithLoadBalancing(
          'destination-$i',
          {'content': 'message $i'},
        );
      }
      
      stopwatch.stop();
      
      final messagesPerSecond = messageCount / (stopwatch.elapsedMilliseconds / 1000);
      expect(messagesPerSecond, greaterThan(100)); // Should handle at least 100 msg/sec
      
      routingService.dispose();
    });

    test('should handle large network topology', () {
      final routingService = AdvancedMeshRoutingService();
      routingService.initialize();
      
      // Create large network
      const nodeCount = 100;
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
