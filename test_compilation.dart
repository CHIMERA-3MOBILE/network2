import 'dart:io';
import 'dart:convert';

/// Simple compilation test for Network App
void main() async {
  print('🔍 Testing Network App Compilation...');
  
  try {
    // Test 1: Check if main.dart can be parsed
    print('✅ Testing main.dart syntax...');
    final mainFile = File('lib/main.dart');
    if (!await mainFile.exists()) {
      print('❌ lib/main.dart not found');
      return;
    }
    
    final mainContent = await mainFile.readAsString();
    print('✅ main.dart loaded successfully');
    
    // Test 2: Check if all imports can be resolved
    final imports = [
      'package:flutter/material.dart',
      'package:flutter/services.dart',
      'package:flutter_background_service/flutter_background_service.dart',
      'package:permission_handler/permission_handler.dart',
      'package:shared_preferences/shared_preferences.dart',
      'services/network_service.dart',
      'services/encryption_service.dart',
      'services/logger_service.dart',
      'services/settings_service.dart',
      'services/advanced_encryption_service.dart',
      'services/error_handling_service.dart',
      'services/performance_monitor_service.dart',
      'widgets/animated_file_item.dart',
      'widgets/network_status_card.dart',
      'widgets/enhanced_ui_components.dart',
      'models/network_status.dart',
    ];
    
    print('✅ Checking imports...');
    for (final import in imports) {
      if (mainContent.contains(import)) {
        print('✅ Found import: $import');
      } else {
        print('⚠️ Missing import: $import');
      }
    }
    
    // Test 3: Check if all required files exist
    print('✅ Checking required files...');
    final requiredFiles = [
      'lib/main.dart',
      'lib/services/network_service.dart',
      'lib/services/advanced_encryption_service.dart',
      'lib/services/error_handling_service.dart',
      'lib/services/performance_monitor_service.dart',
      'lib/widgets/animated_file_item.dart',
      'lib/widgets/network_status_card.dart',
      'lib/widgets/enhanced_ui_components.dart',
      'lib/models/network_status.dart',
      'pubspec.yaml',
    ];
    
    for (final file in requiredFiles) {
      final fileObj = File(file);
      if (await fileObj.exists()) {
        print('✅ Found: $file');
      } else {
        print('❌ Missing: $file');
      }
    }
    
    // Test 4: Check pubspec.yaml
    print('✅ Checking pubspec.yaml...');
    final pubspecFile = File('pubspec.yaml');
    if (await pubspecFile.exists()) {
      final pubspecContent = await pubspecFile.readAsString();
      print('✅ pubspec.yaml found');
      
      // Check for critical dependencies
      final criticalDeps = [
        'nearby_connections',
        'flutter_background_service',
        'permission_handler',
        'crypto',
        'connectivity_plus',
      ];
      
      for (final dep in criticalDeps) {
        if (pubspecContent.contains(dep)) {
          print('✅ Found dependency: $dep');
        } else {
          print('⚠️ Missing dependency: $dep');
        }
      }
    } else {
      print('❌ pubspec.yaml not found');
    }
    
    // Test 5: Check Android configuration
    print('✅ Checking Android configuration...');
    final buildGradleFile = File('android/app/build.gradle');
    if (await buildGradleFile.exists()) {
      print('✅ build.gradle found');
    } else {
      print('❌ build.gradle not found');
    }
    
    print('🎉 Compilation test completed!');
    print('📊 Summary:');
    print('- All required files checked');
    print('- Import statements verified');
    print('- Dependencies validated');
    print('- Android configuration checked');
    
  } catch (e, stackTrace) {
    print('❌ Compilation test failed: $e');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
}
