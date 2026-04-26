import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:network_app/main.dart' as app;
import 'package:network_app/services/network_service.dart';
import 'package:network_app/services/advanced_encryption_service.dart';
import 'package:network_app/services/advanced_mesh_routing_service.dart';
import 'package:network_app/services/error_handling_service.dart';
import 'package:network_app/services/performance_monitor_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Network App Integration Tests', () {
    testWidgets('should launch app and display file manager', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      app.main();
      await tester.pumpAndSettle();

      // Verify the app launches successfully
      expect(find.text('Local Storage'), findsOneWidget);
      expect(find.text('Manage your files and folders'), findsOneWidget);
      expect(find.text('Folders'), findsOneWidget);
    });

    testWidgets('should handle network status toggle', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find network status toggle
      final networkToggle = find.byType(Switch);
      expect(networkToggle, findsOneWidget);

      // Toggle network on
      await tester.tap(networkToggle);
      await tester.pumpAndSettle();

      // Verify network status changes
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('should access hidden network settings', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Perform long press to reveal hidden settings
      final finder = find.byType(Scaffold);
      await tester.longPress(finder);
      await tester.pumpAndSettle();

      // Verify settings dialog appears
      expect(find.text('Network Settings'), findsOneWidget);
      expect(find.text('Device Name'), findsOneWidget);
    });

    testWidgets('should handle file item interactions', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find file items
      final documentsItem = find.text('Documents');
      expect(documentsItem, findsOneWidget);

      // Tap on Documents folder
      await tester.tap(documentsItem);
      await tester.pumpAndSettle();

      // Verify snackbar appears
      expect(find.text('Opening Documents...'), findsOneWidget);
    });

    testWidgets('should handle device name changes', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Access network settings
      final scaffold = find.byType(Scaffold);
      await tester.longPress(scaffold);
      await tester.pumpAndSettle();

      // Find device name field
      final deviceNameField = find.byType(TextField);
      expect(deviceNameField, findsOneWidget);

      // Change device name
      await tester.enterText(deviceNameField, 'TestDevice');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify name change
      expect(find.text('TestDevice'), findsOneWidget);
    });
  });

  group('Service Integration Tests', () {
    late NetworkService networkService;
    late AdvancedEncryptionService encryptionService;
    late AdvancedMeshRoutingService routingService;
    late ErrorHandlingService errorService;
    late PerformanceMonitorService performanceService;

    setUp(() async {
      networkService = NetworkService();
      encryptionService = AdvancedEncryptionService();
      routingService = AdvancedMeshRoutingService();
      errorService = ErrorHandlingService();
      performanceService = PerformanceMonitorService();

      await networkService.initialize();
      routingService.initialize();
      performanceService.startMonitoring();
    });

    tearDown(() async {
      routingService.dispose();
      performanceService.stopMonitoring();
      await networkService.stopAll();
    });

    test('should handle complete message flow', () async {
      // Create test message
      final message = {
        'content': 'Integration test message',
        'type': 'test',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Encrypt message
      final encrypted = encryptionService.encryptMessageAES(
        message.toString(),
        'test-password',
      );

      expect(encrypted['encrypted'], isTrue);

      // Track performance
      final result = await performanceService.trackAsyncOperation(
        'message-encryption',
        () async => encrypted,
      );

      expect(result['encrypted'], isTrue);

      // Route message through mesh network
      final path = routingService.routeMessageWithLoadBalancing(
        'test-destination',
        result,
      );

      expect(path, isA<List<String>>());

      // Verify performance metrics
      final report = performanceService.getPerformanceReport();
      expect(report, contains('message-encryption'));
    });

    test('should handle network failures gracefully', () async {
      // Simulate network failure
      var failureCount = 0;
      Future<void> failingOperation() async {
        failureCount++;
        if (failureCount < 3) {
          throw Exception('Simulated network failure');
        }
      }

      // Execute with retry logic
      await errorService.executeWithRetry(
        failingOperation,
        'network-operation',
        maxRetries: 3,
      );

      expect(failureCount, equals(3));

      // Check error statistics
      final stats = errorService.getErrorStatistics();
      expect(stats['totalErrors'], greaterThan(0));
    });

    test('should handle large network topology', () async {
      // Create large mesh network
      const nodeCount = 50;
      for (int i = 0; i < nodeCount; i++) {
        final node = MeshNode(
          id: 'node-$i',
          name: 'Test Node $i',
          neighbors: i > 0 ? ['node-${i - 1}'] : [],
          lastSeen: DateTime.now(),
        );
        routingService.addNode(node);
      }

      // Verify network statistics
      final stats = routingService.getNetworkStatistics();
      expect(stats['nodeCount'], equals(nodeCount));

      // Test message routing across large network
      final path = routingService.routeMessageWithLoadBalancing(
        'node-49',
        {'content': 'test message'},
      );

      expect(path, isNotEmpty);

      // Verify performance
      final slowOps = performanceService.getSlowOperations();
      expect(slowOps, isEmpty);
    });

    test('should handle concurrent operations', () async {
      // Test concurrent message sending
      const messageCount = 100;
      final futures = <Future>[];

      for (int i = 0; i < messageCount; i++) {
        futures.add(performanceService.trackAsyncOperation(
          'concurrent-message-$i',
          () async {
            final encrypted = encryptionService.encryptMessageAES(
              'Message $i',
              'password',
            );
            routingService.routeMessage('destination-$i', encrypted);
          },
        ));
      }

      // Wait for all operations to complete
      await Future.wait(futures);

      // Verify all messages were processed
      final stats = routingService.getNetworkStatistics();
      expect(stats['totalMessages'], greaterThanOrEqualTo(messageCount));

      // Check performance metrics
      final report = performanceService.getPerformanceReport();
      expect(report, isNotEmpty);
    });
  });

  group('Security Integration Tests', () {
    late AdvancedEncryptionService encryptionService;

    setUp(() {
      encryptionService = AdvancedEncryptionService();
    });

    test('should prevent message tampering', () {
      final originalMessage = 'Secure message content';
      final password = 'strong-password';

      // Encrypt message
      final encrypted = encryptionService.encryptMessageAES(originalMessage, password);

      // Attempt to tamper with encrypted data
      final tampered = Map<String, dynamic>.from(encrypted);
      tampered['data'] = 'tampered-data';

      // Verify decryption fails
      expect(
        () => encryptionService.decryptMessageAES(tampered, password),
        throwsException,
      );
    });

    test('should generate unique fingerprints', () {
      final fingerprints = <String>{};

      // Generate multiple fingerprints
      for (int i = 0; i < 100; i++) {
        final fingerprint = encryptionService.generateDeviceFingerprint();
        fingerprints.add(fingerprint);
      }

      // Verify all fingerprints are unique
      expect(fingerprints.length, equals(100));
    });

    test('should handle message integrity verification', () {
      final message = {
        'content': 'Test message',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sender': 'test-sender',
      };

      // Calculate hash
      final hash = encryptionService.calculateMessageHash(message);

      // Verify integrity
      expect(
        encryptionService.verifyMessageIntegrity(message, hash),
        isTrue,
      );

      // Modify message and verify integrity fails
      final modifiedMessage = Map<String, dynamic>.from(message);
      modifiedMessage['content'] = 'Modified content';

      expect(
        encryptionService.verifyMessageIntegrity(modifiedMessage, hash),
        isFalse,
      );
    });
  });

  group('Performance Integration Tests', () {
    late PerformanceMonitorService performanceService;

    setUp(() {
      performanceService = PerformanceMonitorService();
      performanceService.startMonitoring();
    });

    tearDown(() {
      performanceService.stopMonitoring();
    });

    test('should handle high throughput operations', () async {
      const operationCount = 1000;
      final futures = <Future>[];

      final stopwatch = Stopwatch()..start();

      // Execute many operations concurrently
      for (int i = 0; i < operationCount; i++) {
        futures.add(performanceService.trackAsyncOperation(
          'high-throughput-test',
          () async {
            // Simulate some work
            await Future.delayed(Duration(milliseconds: 1));
            return 'result-$i';
          },
        ));
      }

      await Future.wait(futures);
      stopwatch.stop();

      // Verify performance
      final operationsPerSecond = operationCount / (stopwatch.elapsedMilliseconds / 1000);
      expect(operationsPerSecond, greaterThan(500)); // Should handle 500+ ops/sec

      // Check metrics
      final report = performanceService.getPerformanceReport();
      expect(report, contains('high-throughput-test'));
    });

    test('should identify performance bottlenecks', () async {
      // Simulate slow operation
      await performanceService.trackAsyncOperation(
        'slow-operation',
        () async {
          await Future.delayed(Duration(milliseconds: 1500)); // Slow operation
        },
      );

      // Check if slow operation is detected
      final slowOps = performanceService.getSlowOperations(thresholdMs: 1000);
      expect(slowOps, isNotEmpty);
      expect(slowOps.first.operation, equals('slow-operation'));

      // Get optimization suggestions
      final suggestions = performanceService.getOptimizationSuggestions();
      expect(suggestions, isNotEmpty);
      expect(
        suggestions.any((s) => s.contains('slow-operation')),
        isTrue,
      );
    });

    test('should handle memory efficiently', () async {
      // Track memory usage during operations
      final initialMemory = performanceService._getCurrentMemoryUsage();

      // Execute memory-intensive operations
      for (int i = 0; i < 100; i++) {
        await performanceService.trackAsyncOperation(
          'memory-test-$i',
          () async {
            // Simulate memory usage
            final data = List.generate(1000, (index) => 'data-$index');
            return data.length;
          },
        );
      }

      final finalMemory = performanceService._getCurrentMemoryUsage();
      final memoryIncrease = finalMemory - initialMemory;

      // Memory increase should be reasonable (less than 50MB)
      expect(memoryIncrease, lessThan(50 * 1024 * 1024));
    });
  });

  group('End-to-End Scenario Tests', () {
    testWidgets('should handle complete user workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Launch app and verify UI
      expect(find.text('Local Storage'), findsOneWidget);

      // 2. Enable network
      final networkToggle = find.byType(Switch);
      await tester.tap(networkToggle);
      await tester.pumpAndSettle();

      // 3. Access hidden settings
      await tester.longPress(find.byType(Scaffold));
      await tester.pumpAndSettle();

      // 4. Change device name
      final deviceNameField = find.byType(TextField);
      await tester.enterText(deviceNameField, 'MyDevice');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // 5. Send test message
      final sendButton = find.text('Send Test');
      if (sendButton.evaluate().isNotEmpty) {
        await tester.tap(sendButton);
        await tester.pumpAndSettle();

        // Verify message sent feedback
        expect(find.text('Test message sent'), findsOneWidget);
      }

      // 6. Navigate back to main screen
      final closeButton = find.text('Close');
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // 7. Verify app is still responsive
      expect(find.text('Local Storage'), findsOneWidget);
    });

    testWidgets('should handle error scenarios gracefully', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Simulate various error conditions
      // 1. Network toggle failure
      final networkToggle = find.byType(Switch);
      await tester.tap(networkToggle);
      await tester.pumpAndSettle();

      // App should remain responsive
      expect(find.byType(Scaffold), findsOneWidget);

      // 2. Invalid device name
      await tester.longPress(find.byType(Scaffold));
      await tester.pumpAndSettle();

      final deviceNameField = find.byType(TextField);
      await tester.enterText(deviceNameField, '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should handle empty name gracefully
      expect(find.text('Network Settings'), findsOneWidget);
    });
  });
}
