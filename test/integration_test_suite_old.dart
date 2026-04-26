import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../lib/main.dart' as app;
import '../lib/services/network_service.dart';
import '../lib/services/advanced_encryption_service.dart';
import '../lib/services/advanced_mesh_routing_service.dart';
import '../lib/services/error_handling_service.dart';
import '../lib/services/performance_monitor_service.dart';

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
    test('should handle basic service initialization', () async {
      final encryptionService = AdvancedEncryptionService();
      final routingService = AdvancedMeshRoutingService();
      final errorService = ErrorHandlingService();
      final performanceService = PerformanceMonitorService();

      // Initialize services
      routingService.initialize();
      performanceService.startMonitoring();

      // Test basic encryption
      final encrypted = encryptionService.encryptMessageAES('test message', 'password');
      expect(encrypted['encrypted'], isTrue);

      // Test decryption
      final decrypted = encryptionService.decryptMessageAES(encrypted, 'password');
      expect(decrypted, equals('test message'));

      // Test error handling
      var attemptCount = 0;
      Future<String> operation() async {
        attemptCount++;
        if (attemptCount < 2) {
          throw Exception('Test failure');
        }
        return 'success';
      }

      final result = await errorService.executeWithRetry(operation, 'test');
      expect(result, equals('success'));

      // Test performance tracking
      final perfResult = performanceService.trackOperation('test-op', () => 'result');
      expect(perfResult, equals('result'));

      // Clean up
      routingService.dispose();
      performanceService.stopMonitoring();
    });

    test('should handle mesh routing operations', () async {
      final routingService = AdvancedMeshRoutingService();
      routingService.initialize();

      // Add test nodes
      final node1 = MeshNode(
        id: 'node1',
        name: 'Test Node 1',
        neighbors: ['node2'],
        lastSeen: DateTime.now(),
      );
      final node2 = MeshNode(
        id: 'node2',
        name: 'Test Node 2',
        neighbors: ['node1'],
        lastSeen: DateTime.now(),
      );

      routingService.addNode(node1);
      routingService.addNode(node2);

      // Test statistics
      final stats = routingService.getNetworkStatistics();
      expect(stats['nodeCount'], equals(2));

      // Test message routing
      final path = routingService.routeMessageWithLoadBalancing(
        'node2',
        {'content': 'test message'},
      );
      expect(path, isA<List<String>>());

      // Clean up
      routingService.dispose();
    });
  });

  group('Security Integration Tests', () {
    test('should handle encryption operations', () {
      final encryptionService = AdvancedEncryptionService();

      // Test basic encryption/decryption
      final message = 'Secure message';
      final password = 'test-password';

      final encrypted = encryptionService.encryptMessageAES(message, password);
      expect(encrypted['encrypted'], isTrue);

      final decrypted = encryptionService.decryptMessageAES(encrypted, password);
      expect(decrypted, equals(message));

      // Test device fingerprinting
      final fingerprint = encryptionService.generateDeviceFingerprint();
      expect(fingerprint, isNotEmpty);
      expect(fingerprint.length, equals(16));
    });

    test('should verify message integrity', () {
      final encryptionService = AdvancedEncryptionService();

      final message = {
        'content': 'Test message',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final hash = encryptionService.calculateMessageHash(message);
      expect(hash, isNotEmpty);

      final isValid = encryptionService.verifyMessageIntegrity(message, hash);
      expect(isValid, isTrue);
    });
  });

  group('Performance Integration Tests', () {
    test('should handle performance monitoring', () async {
      final performanceService = PerformanceMonitorService();
      performanceService.startMonitoring();

      // Track some operations
      for (int i = 0; i < 10; i++) {
        performanceService.trackOperation('test-op-$i', () => 'result-$i');
      }

      // Check performance report
      final report = performanceService.getPerformanceReport();
      expect(report, isA<Map<String, dynamic>>());

      // Clean up
      performanceService.stopMonitoring();
    });

    test('should handle error recovery', () async {
      final errorService = ErrorHandlingService();

      var attemptCount = 0;
      Future<String> failingOperation() async {
        attemptCount++;
        if (attemptCount < 3) {
          throw Exception('Simulated failure');
        }
        return 'success';
      }

      final result = await errorService.executeWithRetry(
        failingOperation,
        'test-operation',
        maxRetries: 3,
      );

      expect(result, equals('success'));
      expect(attemptCount, equals(3));
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
