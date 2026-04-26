import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// Professional settings service with enterprise-grade error handling
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Configuration Keys
  static const String _keyDeviceName = 'device_name';
  static const String _keyAutoStartNetwork = 'auto_start_network';
  static const String _keyEncryptionEnabled = 'encryption_enabled';
  static const String _keyMaxHops = 'max_hops';
  static const String _keyDiscoveryInterval = 'discovery_interval';
  static const String _keyLogLevel = 'log_level';
  static const String _keyBackgroundService = 'background_service';
  static const String _keyBatteryOptimization = 'battery_optimization';
  static const String _keyFirstLaunch = 'first_launch';

  // Default Values
  static const String _defaultDeviceName = 'FileManager';
  static const bool _defaultAutoStart = true;
  static const bool _defaultEncryption = true;
  static const int _defaultMaxHops = 5;
  static const int _defaultDiscoveryInterval = 30;
  static const String _defaultLogLevel = 'INFO';
  static const bool _defaultBackgroundService = true;
  static const bool _defaultBatteryOptimization = false;

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// Initialize the settings service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      developer.log('SettingsService initialized successfully');
    } catch (e) {
      developer.log('Failed to initialize SettingsService: $e');
      _prefs = null;
      _isInitialized = false;
      rethrow;
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get SharedPreferences instance
  Future<SharedPreferences> get prefs async {
    if (!_isInitialized) {
      await initialize();
    }
    if (_prefs == null) {
      throw Exception('SharedPreferences not initialized');
    }
    return _prefs!;
  }

  // Device Settings
  Future<String> getDeviceName() async {
    try {
      final prefs = await this.prefs;
      return prefs.getString(_keyDeviceName) ?? _defaultDeviceName;
    } catch (e) {
      developer.log('Failed to get device name: $e');
      return _defaultDeviceName;
    }
  }

  Future<void> setDeviceName(String name) async {
    try {
      if (name.isEmpty) {
        throw ArgumentError('Device name cannot be empty');
      }
      if (name.length > 50) {
        throw ArgumentError('Device name cannot exceed 50 characters');
      }
      final prefs = await this.prefs;
      await prefs.setString(_keyDeviceName, name);
      developer.log('Device name set successfully');
    } catch (e) {
      developer.log('Failed to set device name: $e');
      rethrow;
    }
  }

  // Network Settings
  Future<bool> getAutoStartNetwork() async {
    try {
      final prefs = await this.prefs;
      return prefs.getBool(_keyAutoStartNetwork) ?? _defaultAutoStart;
    } catch (e) {
      developer.log('Failed to get auto start network: $e');
      return _defaultAutoStart;
    }
  }

  Future<void> setAutoStartNetwork(bool enabled) async {
    try {
      final prefs = await this.prefs;
      await prefs.setBool(_keyAutoStartNetwork, enabled);
      developer.log('Auto start network set to: $enabled');
    } catch (e) {
      developer.log('Failed to set auto start network: $e');
      rethrow;
    }
  }

  Future<bool> getEncryptionEnabled() async {
    try {
      final prefs = await this.prefs;
      return prefs.getBool(_keyEncryptionEnabled) ?? _defaultEncryption;
    } catch (e) {
      developer.log('Failed to get encryption enabled: $e');
      return _defaultEncryption;
    }
  }

  Future<void> setEncryptionEnabled(bool enabled) async {
    try {
      final prefs = await this.prefs;
      await prefs.setBool(_keyEncryptionEnabled, enabled);
      developer.log('Encryption enabled set to: $enabled');
    } catch (e) {
      developer.log('Failed to set encryption enabled: $e');
      rethrow;
    }
  }

  Future<int> getMaxHops() async {
    try {
      final prefs = await this.prefs;
      final value = prefs.getInt(_keyMaxHops);
      if (value == null || value < 1 || value > 10) {
        return _defaultMaxHops;
      }
      return value;
    } catch (e) {
      developer.log('Failed to get max hops: $e');
      return _defaultMaxHops;
    }
  }

  Future<void> setMaxHops(int hops) async {
    try {
      if (hops < 1 || hops > 10) {
        throw ArgumentError('Max hops must be between 1 and 10');
      }
      final prefs = await this.prefs;
      await prefs.setInt(_keyMaxHops, hops);
      developer.log('Max hops set to: $hops');
    } catch (e) {
      developer.log('Failed to set max hops: $e');
      rethrow;
    }
  }

  Future<int> getDiscoveryInterval() async {
    try {
      final prefs = await this.prefs;
      final value = prefs.getInt(_keyDiscoveryInterval);
      if (value == null || value < 10 || value > 300) {
        return _defaultDiscoveryInterval;
      }
      return value;
    } catch (e) {
      developer.log('Failed to get discovery interval: $e');
      return _defaultDiscoveryInterval;
    }
  }

  Future<void> setDiscoveryInterval(int interval) async {
    try {
      if (interval < 10 || interval > 300) {
        throw ArgumentError('Discovery interval must be between 10 and 300 seconds');
      }
      final prefs = await this.prefs;
      await prefs.setInt(_keyDiscoveryInterval, interval);
      developer.log('Discovery interval set to: $interval');
    } catch (e) {
      developer.log('Failed to set discovery interval: $e');
      rethrow;
    }
  }

  // System Settings
  Future<String> getLogLevel() async {
    try {
      final prefs = await this.prefs;
      return prefs.getString(_keyLogLevel) ?? _defaultLogLevel;
    } catch (e) {
      developer.log('Failed to get log level: $e');
      return _defaultLogLevel;
    }
  }

  Future<void> setLogLevel(String level) async {
    try {
      final validLevels = ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'FATAL'];
      if (!validLevels.contains(level)) {
        throw ArgumentError('Invalid log level: $level');
      }
      final prefs = await this.prefs;
      await prefs.setString(_keyLogLevel, level);
      developer.log('Log level set to: $level');
    } catch (e) {
      developer.log('Failed to set log level: $e');
      rethrow;
    }
  }

  Future<bool> getBackgroundService() async {
    try {
      final prefs = await this.prefs;
      return prefs.getBool(_keyBackgroundService) ?? _defaultBackgroundService;
    } catch (e) {
      developer.log('Failed to get background service: $e');
      return _defaultBackgroundService;
    }
  }

  Future<void> setBackgroundService(bool enabled) async {
    try {
      final prefs = await this.prefs;
      await prefs.setBool(_keyBackgroundService, enabled);
      developer.log('Background service set to: $enabled');
    } catch (e) {
      developer.log('Failed to set background service: $e');
      rethrow;
    }
  }

  Future<bool> getBatteryOptimization() async {
    try {
      final prefs = await this.prefs;
      return prefs.getBool(_keyBatteryOptimization) ?? _defaultBatteryOptimization;
    } catch (e) {
      developer.log('Failed to get battery optimization: $e');
      return _defaultBatteryOptimization;
    }
  }

  Future<void> setBatteryOptimization(bool enabled) async {
    try {
      final prefs = await this.prefs;
      await prefs.setBool(_keyBatteryOptimization, enabled);
      developer.log('Battery optimization set to: $enabled');
    } catch (e) {
      developer.log('Failed to set battery optimization: $e');
      rethrow;
    }
  }

  // Application Settings
  Future<bool> isFirstLaunch() async {
    try {
      final prefs = await this.prefs;
      final isFirstLaunch = prefs.getBool(_keyFirstLaunch) ?? true;
      return isFirstLaunch;
    } catch (e) {
      developer.log('Failed to check first launch: $e');
      return true;
    }
  }

  Future<void> setFirstLaunchComplete() async {
    try {
      final prefs = await this.prefs;
      await prefs.setBool(_keyFirstLaunch, false);
      developer.log('First launch marked as complete');
    } catch (e) {
      developer.log('Failed to set first launch complete: $e');
      rethrow;
    }
  }

  // Utility Methods
  Future<void> resetToDefaults() async {
    try {
      final prefs = await this.prefs;
      await prefs.clear();
      developer.log('Settings reset to defaults');
    } catch (e) {
      developer.log('Failed to reset settings: $e');
      rethrow;
    }
  }

  Future<bool> containsKey(String key) async {
    try {
      final prefs = await this.prefs;
      return prefs.containsKey(key);
    } catch (e) {
      developer.log('Failed to check key existence: $e');
      return false;
    }
  }

  Future<void> removeKey(String key) async {
    try {
      final prefs = await this.prefs;
      await prefs.remove(key);
      developer.log('Key removed: $key');
    } catch (e) {
      developer.log('Failed to remove key: $e');
      rethrow;
    }
  }

  Future<Set<String>> getAllKeys() async {
    try {
      final prefs = await this.prefs;
      return prefs.getKeys();
    } catch (e) {
      developer.log('Failed to get all keys: $e');
      return <String>{};
    }
  }

  /// Dispose resources
  void dispose() {
    _prefs = null;
    _isInitialized = false;
    developer.log('SettingsService disposed');
  }

  /// Get settings statistics
  Map<String, dynamic> getStatistics() {
    return {
      'isInitialized': _isInitialized,
      'hasPreferences': _prefs != null,
      'totalKeys': _prefs?.getKeys().length ?? 0,
    };
  }
}
