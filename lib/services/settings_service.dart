import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'logger_service.dart';

/// Professional settings service with enterprise-grade error handling
/// 
/// This service provides comprehensive settings management with:
/// - Type-safe configuration access with validation
/// - Default value management and fallbacks
/// - Comprehensive error handling and recovery
/// - Settings validation and sanitization
/// - Performance monitoring for settings operations
/// - Professional documentation and comments
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final LoggerService _logger = LoggerService();

  // Configuration Keys with semantic naming
  static const String _keyDeviceName = 'device_name';
  static const String _keyAutoStartNetwork = 'auto_start_network';
  static const String _keyEncryptionEnabled = 'encryption_enabled';
  static const String _keyMaxHops = 'max_hops';
  static const String _keyDiscoveryInterval = 'discovery_interval';
  static const String _keyLogLevel = 'log_level';
  static const String _keyBackgroundService = 'background_service';
  static const String _keyBatteryOptimization = 'battery_optimization';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyLastSync = 'last_sync';
  static const String _keyVersion = 'app_version';

  // Default Values with professional defaults
  static const String _defaultDeviceName = 'FileManager';
  static const bool _defaultAutoStart = true;
  static const bool _defaultEncryption = true;
  static const int _defaultMaxHops = 5;
  static const int _defaultDiscoveryInterval = 30;
  static const String _defaultLogLevel = 'INFO';
  static const bool _defaultBackgroundService = true;
  static const bool _defaultBatteryOptimization = false;
  static const bool _defaultFirstLaunch = true;

  // Validation constraints
  static const int _minDeviceNameLength = 1;
  static const int _maxDeviceNameLength = 50;
  static const int _minMaxHops = 1;
  static const int _maxMaxHops = 10;
  static const int _minDiscoveryInterval = 5;
  static const int _maxDiscoveryInterval = 300;
  static const List<String> _validLogLevels = ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'FATAL'];

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  
  // Performance monitoring
  int _readCount = 0;
  int _writeCount = 0;
  DateTime _lastReset = DateTime.now();

  /// Initialize the settings service with comprehensive setup
  /// 
  /// Initializes the shared preferences instance and validates
  /// all existing settings. Sets up default values for missing
  /// settings and logs initialization status.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Validate and set defaults for missing settings
      await _validateAndSetDefaults();
      
      _isInitialized = true;
      _logger.info('SettingsService initialized successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize SettingsService', error: e, stackTrace: stackTrace);
      _prefs = null;
      _isInitialized = false;
      rethrow;
    }
  }

  /// Validate and set defaults for missing settings
  /// 
  /// Ensures all settings have valid values by checking existing
  /// settings and setting defaults for missing or invalid ones.
  Future<void> _validateAndSetDefaults() async {
    if (_prefs == null) return;

    try {
      // Validate device name
      final deviceName = _prefs!.getString(_keyDeviceName);
      if (deviceName == null || !_isValidDeviceName(deviceName)) {
        await setDeviceName(_defaultDeviceName);
      }

      // Validate numeric settings
      final maxHops = _prefs!.getInt(_keyMaxHops);
      if (maxHops == null || !_isValidMaxHops(maxHops)) {
        await setMaxHops(_defaultMaxHops);
      }

      final discoveryInterval = _prefs!.getInt(_keyDiscoveryInterval);
      if (discoveryInterval == null || !_isValidDiscoveryInterval(discoveryInterval)) {
        await setDiscoveryInterval(_defaultDiscoveryInterval);
      }

      // Validate log level
      final logLevel = _prefs!.getString(_keyLogLevel);
      if (logLevel == null || !_validLogLevels.contains(logLevel)) {
        await setLogLevel(_defaultLogLevel);
      }

      _logger.info('Settings validation completed');
    } catch (e, stackTrace) {
      _logger.error('Failed to validate settings', error: e, stackTrace: stackTrace);
    }
  }

  /// Validate device name
  bool _isValidDeviceName(String name) {
    return name.length >= _minDeviceNameLength && name.length <= _maxDeviceNameLength;
  }

  /// Validate max hops value
  bool _isValidMaxHops(int hops) {
    return hops >= _minMaxHops && hops <= _maxMaxHops;
  }

  /// Validate discovery interval value
  bool _isValidDiscoveryInterval(int interval) {
    return interval >= _minDiscoveryInterval && interval <= _maxDiscoveryInterval;
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Device name with validation
  Future<String> getDeviceName() async {
    if (_prefs == null) await initialize();
    final name = _prefs?.getString(_keyDeviceName) ?? _defaultDeviceName;
    _readCount++;
    return name;
  }

  /// Set device name with validation
  Future<void> setDeviceName(String name) async {
    if (!_isValidDeviceName(name)) {
      throw ArgumentError('Device name must be between $_minDeviceNameLength and $_maxDeviceNameLength characters');
    }
    if (_prefs == null) await initialize();
    await _prefs?.setString(_keyDeviceName, name);
    _writeCount++;
    _logger.info('Device name set to: $name');
  }

  /// Auto start network setting
  Future<bool> getAutoStartNetwork() async {
    if (_prefs == null) await initialize();
    final value = _prefs?.getBool(_keyAutoStartNetwork) ?? _defaultAutoStart;
    _readCount++;
    return value;
  }

  /// Set auto start network setting
  Future<void> setAutoStartNetwork(bool value) async {
    if (_prefs == null) await initialize();
    await _prefs?.setBool(_keyAutoStartNetwork, value);
    _writeCount++;
    _logger.info('Auto start network set to: $value');
  }

  /// Encryption enabled setting
  Future<bool> getEncryptionEnabled() async {
    if (_prefs == null) await initialize();
    final value = _prefs?.getBool(_keyEncryptionEnabled) ?? _defaultEncryption;
    _readCount++;
    return value;
  }

  /// Set encryption enabled setting
  Future<void> setEncryptionEnabled(bool value) async {
    if (_prefs == null) await initialize();
    await _prefs?.setBool(_keyEncryptionEnabled, value);
    _writeCount++;
    _logger.info('Encryption enabled set to: $value');
  }

  /// Max hops setting with validation
  Future<int> getMaxHops() async {
    if (_prefs == null) await initialize();
    final value = _prefs?.getInt(_keyMaxHops) ?? _defaultMaxHops;
    _readCount++;
    return value;
  }

  /// Set max hops with validation
  Future<void> setMaxHops(int hops) async {
    if (!_isValidMaxHops(hops)) {
      throw ArgumentError('Max hops must be between $_minMaxHops and $_maxMaxHops');
    }
    if (_prefs == null) await initialize();
    await _prefs?.setInt(_keyMaxHops, hops);
    _writeCount++;
    _logger.info('Max hops set to: $hops');
  }

  /// Discovery interval setting with validation
  Future<int> getDiscoveryInterval() async {
    if (_prefs == null) await initialize();
    final value = _prefs?.getInt(_keyDiscoveryInterval) ?? _defaultDiscoveryInterval;
    _readCount++;
    return value;
  }

  /// Set discovery interval with validation
  Future<void> setDiscoveryInterval(int interval) async {
    if (!_isValidDiscoveryInterval(interval)) {
      throw ArgumentError('Discovery interval must be between $_minDiscoveryInterval and $_maxDiscoveryInterval seconds');
    }
    if (_prefs == null) await initialize();
    await _prefs?.setInt(_keyDiscoveryInterval, interval);
    _writeCount++;
    _logger.info('Discovery interval set to: $interval');
  }

  /// Log level setting with validation
  Future<String> getLogLevel() async {
    if (_prefs == null) await initialize();
    final value = _prefs?.getString(_keyLogLevel) ?? _defaultLogLevel;
    _readCount++;
    return value;
  }

  /// Set log level with validation
  Future<void> setLogLevel(String level) async {
    if (!_validLogLevels.contains(level)) {
      throw ArgumentError('Log level must be one of: ${_validLogLevels.join(", ")}');
    }
    if (_prefs == null) await initialize();
    await _prefs?.setString(_keyLogLevel, level);
    _writeCount++;
    _logger.info('Log level set to: $level');
  }

  /// Background service setting
  Future<bool> getBackgroundService() async {
    if (_prefs == null) await initialize();
    final value = _prefs?.getBool(_keyBackgroundService) ?? _defaultBackgroundService;
    _readCount++;
    return value;
  }

  /// Set background service setting
  Future<void> setBackgroundService(bool value) async {
    if (_prefs == null) await initialize();
    await _prefs?.setBool(_keyBackgroundService, value);
    _writeCount++;
    _logger.info('Background service set to: $value');
  }

  /// Battery optimization setting
  Future<bool> getBatteryOptimization() async {
    if (_prefs == null) await initialize();
    final value = _prefs?.getBool(_keyBatteryOptimization) ?? _defaultBatteryOptimization;
    _readCount++;
    return value;
  }

  /// Set battery optimization setting
  Future<void> setBatteryOptimization(bool value) async {
    if (_prefs == null) await initialize();
    await _prefs?.setBool(_keyBatteryOptimization, value);
    _writeCount++;
    _logger.info('Battery optimization set to: $value');
  }

  /// First launch setting
  Future<bool> getFirstLaunch() async {
    if (_prefs == null) await initialize();
    final value = _prefs?.getBool(_keyFirstLaunch) ?? _defaultFirstLaunch;
    _readCount++;
    return value;
  }

  /// Set first launch setting
  Future<void> setFirstLaunch(bool value) async {
    if (_prefs == null) await initialize();
    await _prefs?.setBool(_keyFirstLaunch, value);
    _writeCount++;
    _logger.info('First launch set to: $value');
  }

  /// Get comprehensive settings statistics
  Map<String, dynamic> getStatistics() {
    return {
      'readCount': _readCount,
      'writeCount': _writeCount,
      'isInitialized': _isInitialized,
      'lastReset': _lastReset.toIso8601String(),
      'uptime': DateTime.now().difference(_lastReset).inSeconds,
    };
  }

  /// Reset settings statistics
  void resetStatistics() {
    _readCount = 0;
    _writeCount = 0;
    _lastReset = DateTime.now();
    _logger.info('Settings statistics reset');
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    if (_prefs == null) await initialize();
    
    try {
      await setDeviceName(_defaultDeviceName);
      await setAutoStartNetwork(_defaultAutoStart);
      await setEncryptionEnabled(_defaultEncryption);
      await setMaxHops(_defaultMaxHops);
      await setDiscoveryInterval(_defaultDiscoveryInterval);
      await setLogLevel(_defaultLogLevel);
      await setBackgroundService(_defaultBackgroundService);
      await setBatteryOptimization(_defaultBatteryOptimization);
      await setFirstLaunch(_defaultFirstLaunch);
      
      _logger.info('All settings reset to defaults');
    } catch (e, stackTrace) {
      _logger.error('Failed to reset settings to defaults', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
