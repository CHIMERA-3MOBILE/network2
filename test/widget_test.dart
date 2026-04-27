import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_app/main.dart';
import 'package:network_app/widgets/network_status_card.dart';
import 'package:network_app/widgets/animated_file_item.dart';
import 'package:network_app/services/settings_service.dart';

void main() {
  group('NetworkApp Widget Tests', () {
    testWidgets('App launches successfully', (WidgetTester tester) async {
      await tester.pumpWidget(const NetworkApp());
      await tester.pumpAndSettle();
      
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(FileManagerScreen), findsOneWidget);
    });

    testWidgets('FileManagerScreen shows correct title', (WidgetTester tester) async {
      await tester.pumpWidget(const NetworkApp());
      await tester.pumpAndSettle();
      
      expect(find.text('Local Storage'), findsOneWidget);
      expect(find.text('Manage your files and folders'), findsOneWidget);
    });

    testWidgets('NetworkStatusCard renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkStatusCard(
              isActive: false,
              connectedDevices: 0,
              onToggle: () {},
              onSettings: () {},
            ),
          ),
        ),
      );
      
      expect(find.text('Network Status'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('0 connected devices'), findsOneWidget);
    });

    testWidgets('NetworkStatusCard shows active state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkStatusCard(
              isActive: true,
              connectedDevices: 3,
              onToggle: () {},
              onSettings: () {},
            ),
          ),
        ),
      );
      
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('3 connected devices'), findsOneWidget);
    });

    testWidgets('AnimatedFileItem renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedFileItem(
              name: 'Documents',
              type: 'documents',
              onTap: () {},
            ),
          ),
        ),
      );
      
      expect(find.text('Documents'), findsOneWidget);
    });

    testWidgets('Settings button triggers callback', (WidgetTester tester) async {
      bool settingsTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkStatusCard(
              isActive: false,
              connectedDevices: 0,
              onToggle: () {},
              onSettings: () {
                settingsTapped = true;
              },
            ),
          ),
        ),
      );
      
      await tester.tap(find.text('Settings'));
      await tester.pump();
      
      expect(settingsTapped, true);
    });

    testWidgets('Network toggle works correctly', (WidgetTester tester) async {
      bool toggleTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkStatusCard(
              isActive: false,
              connectedDevices: 0,
              onToggle: () {
                toggleTapped = true;
              },
              onSettings: () {},
            ),
          ),
        ),
      );
      
      await tester.tap(find.byType(Switch));
      await tester.pump();
      
      expect(toggleTapped, true);
    });

    testWidgets('Folder list is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(const NetworkApp());
      await tester.pumpAndSettle();
      
      expect(find.text('Folders'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Downloads'), findsOneWidget);
      expect(find.text('Pictures'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
    });

    testWidgets('About dialog can be opened', (WidgetTester tester) async {
      await tester.pumpWidget(const NetworkApp());
      await tester.pumpAndSettle();
      
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      
      expect(find.byType(AboutDialog), findsOneWidget);
    });
  });

  group('SettingsService Tests', () {
    test('SettingsService singleton works', () {
      final service1 = SettingsService();
      final service2 = SettingsService();
      expect(identical(service1, service2), true);
    });
  });
}
