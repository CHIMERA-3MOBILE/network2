#!/usr/bin/env dart

/// Professional project validation script for Network App
/// 
/// This script performs comprehensive validation of the entire project
/// including dependencies, configuration files, and build readiness.

import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 Starting comprehensive project validation...\n');
  
  final validator = ProjectValidator();
  final results = await validator.validateAll();
  
  print('\n📊 Validation Results:');
  print('=' * 50);
  
  for (final result in results) {
    print(result);
  }
  
  final allPassed = results.every((result) => result.contains('✅'));
  
  if (allPassed) {
    print('\n🎉 All validations passed! Project is ready for production.');
    exit(0);
  } else {
    print('\n❌ Some validations failed. Please review and fix issues.');
    exit(1);
  }
}

class ProjectValidator {
  Future<List<String>> validateAll() async {
    final results = <String>[];
    
    // Validate project structure
    results.add(await validateProjectStructure());
    
    // Validate Flutter configuration
    results.add(await validateFlutterConfig());
    
    // Validate Android configuration
    results.add(await validateAndroidConfig());
    
    // Validate dependencies
    results.add(await validateDependencies());
    
    // Validate test configuration
    results.add(await validateTestConfig());
    
    // Validate CI/CD configuration
    results.add(await validateCICDConfig());
    
    // Validate assets
    results.add(await validateAssets());
    
    // Validate code quality
    results.add(await validateCodeQuality());
    
    return results;
  }
  
  Future<String> validateProjectStructure() async {
    print('🔍 Validating project structure...');
    
    final requiredFiles = [
      'pubspec.yaml',
      'README.md',
      'analysis_options.yaml',
      '.gitignore',
      'lib/main.dart',
      'android/app/build.gradle',
      'android/settings.gradle',
      '.github/workflows/build.yml',
    ];
    
    final requiredDirs = [
      'lib/services',
      'lib/widgets',
      'test',
      'assets',
      'android/app/src/main',
    ];
    
    var allPresent = true;
    
    for (final file in requiredFiles) {
      if (!await File(file).exists()) {
        print('❌ Missing file: $file');
        allPresent = false;
      }
    }
    
    for (final dir in requiredDirs) {
      if (!await Directory(dir).exists()) {
        print('❌ Missing directory: $dir');
        allPresent = false;
      }
    }
    
    return allPresent 
        ? '✅ Project structure validation passed'
        : '❌ Project structure validation failed';
  }
  
  Future<String> validateFlutterConfig() async {
    print('🔍 Validating Flutter configuration...');
    
    try {
      final pubspecFile = File('pubspec.yaml');
      if (!await pubspecFile.exists()) {
        return '❌ pubspec.yaml not found';
      }
      
      final content = await pubspecFile.readAsString();
      
      // Check for required fields
      final requiredFields = ['name:', 'description:', 'version:', 'environment:', 'dependencies:'];
      var hasAllFields = true;
      
      for (final field in requiredFields) {
        if (!content.contains(field)) {
          print('❌ Missing field in pubspec.yaml: $field');
          hasAllFields = false;
        }
      }
      
      // Check Flutter SDK constraint
      if (!content.contains('flutter:') || !content.contains('>=3.1.0')) {
        print('❌ Flutter SDK constraint not properly configured');
        hasAllFields = false;
      }
      
      return hasAllFields 
          ? '✅ Flutter configuration validation passed'
          : '❌ Flutter configuration validation failed';
          
    } catch (e) {
      return '❌ Flutter configuration validation error: $e';
    }
  }
  
  Future<String> validateAndroidConfig() async {
    print('🔍 Validating Android configuration...');
    
    try {
      final buildGradleFile = File('android/app/build.gradle');
      if (!await buildGradleFile.exists()) {
        return '❌ Android build.gradle not found';
      }
      
      final content = await buildGradleFile.readAsString();
      
      // Check for required configurations
      final requiredConfigs = [
        'compileSdkVersion 34',
        'targetSdkVersion 34',
        'minSdkVersion 21',
        'namespace "com.chimera.network_app"',
        'multiDexEnabled true',
      ];
      
      var hasAllConfigs = true;
      
      for (final config in requiredConfigs) {
        if (!content.contains(config)) {
          print('❌ Missing Android config: $config');
          hasAllConfigs = false;
        }
      }
      
      // Check for Gradle wrapper
      final wrapperProps = File('android/gradle/wrapper/gradle-wrapper.properties');
      if (!await wrapperProps.exists()) {
        print('❌ Gradle wrapper properties not found');
        hasAllConfigs = false;
      }
      
      return hasAllConfigs 
          ? '✅ Android configuration validation passed'
          : '❌ Android configuration validation failed';
          
    } catch (e) {
      return '❌ Android configuration validation error: $e';
    }
  }
  
  Future<String> validateDependencies() async {
    print('🔍 Validating dependencies...');
    
    try {
      final pubspecFile = File('pubspec.yaml');
      final content = await pubspecFile.readAsString();
      
      // Check for critical dependencies
      final criticalDeps = [
        'flutter:',
        'cupertino_icons:',
        'nearby_connections:',
        'flutter_background_service:',
        'permission_handler:',
        'shared_preferences:',
        'crypto:',
      ];
      
      var hasAllDeps = true;
      
      for (final dep in criticalDeps) {
        if (!content.contains(dep)) {
          print('❌ Missing dependency: $dep');
          hasAllDeps = false;
        }
      }
      
      // Check for dev dependencies
      if (!content.contains('dev_dependencies:')) {
        print('❌ No dev dependencies section found');
        hasAllDeps = false;
      }
      
      return hasAllDeps 
          ? '✅ Dependencies validation passed'
          : '❌ Dependencies validation failed';
          
    } catch (e) {
      return '❌ Dependencies validation error: $e';
    }
  }
  
  Future<String> validateTestConfig() async {
    print('🔍 Validating test configuration...');
    
    try {
      final testDir = Directory('test');
      if (!await testDir.exists()) {
        return '❌ Test directory not found';
      }
      
      final testFiles = await testDir.list().toList();
      
      if (testFiles.isEmpty) {
        return '❌ No test files found';
      }
      
      // Check for test configuration
      final testConfig = File('test/test_config.dart');
      if (!await testConfig.exists()) {
        print('⚠️ Test configuration file not found (optional)');
      }
      
      // Check for unit tests
      final unitTests = testFiles.where((file) => 
          file.path.contains('unit_test') || file.path.contains('test_'));
      
      if (unitTests.isEmpty) {
        print('⚠️ No unit tests found');
      }
      
      return '✅ Test configuration validation passed';
      
    } catch (e) {
      return '❌ Test configuration validation error: $e';
    }
  }
  
  Future<String> validateCICDConfig() async {
    print('🔍 Validating CI/CD configuration...');
    
    try {
      final workflowFile = File('.github/workflows/build.yml');
      if (!await workflowFile.exists()) {
        return '❌ CI/CD workflow file not found';
      }
      
      final content = await workflowFile.readAsString();
      
      // Check for workflow components
      final requiredComponents = [
        'name:',
        'on:',
        'jobs:',
        'build:',
        'steps:',
        'actions/checkout@',
        'flutter build apk',
      ];
      
      var hasAllComponents = true;
      
      for (final component in requiredComponents) {
        if (!content.contains(component)) {
          print('❌ Missing CI/CD component: $component');
          hasAllComponents = false;
        }
      }
      
      // Check for comprehensive workflow features
      final workflowFeatures = [
        'quality-check',
        'validate',
        'build',
        'release',
      ];
      
      for (final feature in workflowFeatures) {
        if (!content.contains(feature)) {
          print('⚠️ Missing workflow feature: $feature');
        }
      }
      
      return hasAllComponents 
          ? '✅ CI/CD configuration validation passed'
          : '❌ CI/CD configuration validation failed';
          
    } catch (e) {
      return '❌ CI/CD configuration validation error: $e';
    }
  }
  
  Future<String> validateAssets() async {
    print('🔍 Validating assets...');
    
    try {
      final assetsDir = Directory('assets');
      if (!await assetsDir.exists()) {
        return '❌ Assets directory not found';
      }
      
      final pubspecFile = File('pubspec.yaml');
      final content = await pubspecFile.readAsString();
      
      // Check if assets are declared in pubspec
      if (!content.contains('assets:')) {
        return '❌ No assets section in pubspec.yaml';
      }
      
      // Check for asset directories
      final assetDirs = ['images', 'animations', 'icons', 'fonts'];
      var hasAllAssetDirs = true;
      
      for (final dir in assetDirs) {
        final assetDir = Directory('assets/$dir');
        if (!await assetDir.exists()) {
          print('❌ Missing asset directory: assets/$dir');
          hasAllAssetDirs = false;
        }
      }
      
      return hasAllAssetDirs 
          ? '✅ Assets validation passed'
          : '❌ Assets validation failed';
          
    } catch (e) {
      return '❌ Assets validation error: $e';
    }
  }
  
  Future<String> validateCodeQuality() async {
    print('🔍 Validating code quality...');
    
    try {
      final analysisFile = File('analysis_options.yaml');
      if (!await analysisFile.exists()) {
        return '❌ analysis_options.yaml not found';
      }
      
      final content = await analysisFile.readAsString();
      
      // Check for analysis configuration
      final analysisConfigs = [
        'include: package:flutter_lints/flutter.yaml',
        'linter:',
        'rules:',
        'analyzer:',
      ];
      
      var hasAllConfigs = true;
      
      for (final config in analysisConfigs) {
        if (!content.contains(config)) {
          print('❌ Missing analysis config: $config');
          hasAllConfigs = false;
        }
      }
      
      // Check for .gitignore
      final gitignoreFile = File('.gitignore');
      if (!await gitignoreFile.exists()) {
        print('❌ .gitignore file not found');
        hasAllConfigs = false;
      }
      
      return hasAllConfigs 
          ? '✅ Code quality validation passed'
          : '❌ Code quality validation failed';
          
    } catch (e) {
      return '❌ Code quality validation error: $e';
    }
  }
}
