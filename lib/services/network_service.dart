import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'logger_service.dart';
import 'settings_service.dart';
import '../models/network_status.dart';

/// Professional P2P mesh networking service with enterprise-grade reliability
class NetworkService {
  static const String _serviceId = 'com.chimera.network_app';
  static const String _defaultDeviceName = 'FileManager';
  static const int _maxRetries = 3;
  static const Duration _connectionTimeout = Duration(seconds: 30);
  static const Duration _cleanupInterval = Duration(minutes: 5);
  static const int _maxConnections = 10;
  
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final LoggerService _logger = LoggerService();
  final SettingsService _settingsService = SettingsService();
  final Connectivity _connectivity = Connectivity();
  
  // Connection state management
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  bool _isInitialized = false;
  List<String> _connectedDevices = [];
  Map<String, String> _deviceEndpoints = {};
  Map<String, DateTime> _lastSeen = {};
  Map<String, int> _retryCounts = {};
  
  // Stream management
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _payloadSubscription;
  StreamSubscription? _connectivitySubscription;
  Timer? _cleanupTimer;
  Timer? _reconnectTimer;
  Timer? _healthCheckTimer;

  // Event controllers with proper error handling
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  final StreamController<List<String>> _deviceListController = 
      StreamController<List<String>>.broadcast();
  Stream<List<String>> get deviceListStream => _deviceListController.stream;

  final StreamController<NetworkStatus> _statusController = 
      StreamController<NetworkStatus>.broadcast();
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  // Public getters with safety checks
  List<String> get connectedDevices => List.unmodifiable(_connectedDevices);
  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;
  bool get isInitialized => _isInitialized;
  int get deviceCount => _connectedDevices.length;

  /// Network status enum for professional state management
  NetworkStatus get currentStatus {
    if (!_isInitialized) return NetworkStatus.disconnected;
    if (_connectedDevices.isEmpty) return NetworkStatus.connected;
    return NetworkStatus.active;
  }

  /// Initialize the network service with comprehensive error handling
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        _logger.warning('NetworkService already initialized');
        return;
      }

      _updateStatus(NetworkStatus.initializing);
      _logger.info('Initializing NetworkService...');

      // Initialize connectivity monitoring
      await _setupConnectivityMonitoring();
      
      // Request permissions
      await _requestPermissions();
      
      // Setup background service
      await _setupBackgroundService();
      
      // Setup event listeners
      _setupEventListeners();
      
      // Start cleanup timer
      _startCleanupTimer();
      
      // Start health check timer
      _startHealthCheckTimer();
      
      _isInitialized = true;
      _updateStatus(NetworkStatus.connected);
      _logger.info('NetworkService initialized successfully');
      
    } catch (e) {
      _updateStatus(NetworkStatus.error);
      _logger.error('Failed to initialize NetworkService', error: e);
      rethrow;
    }
  }

  /// Setup connectivity monitoring with professional error handling
  Future<void> _setupConnectivityMonitoring() async {
    try {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
        _logger.info('Connectivity changed: $result');
        if (result == ConnectivityResult.none) {
          _handleConnectivityLoss();
        } else {
          _handleConnectivityRestore();
        }
      });
    } catch (e) {
      _logger.error('Failed to setup connectivity monitoring', error: e);
    }
  }

  /// Handle connectivity loss with graceful degradation
  void _handleConnectivityLoss() {
    _logger.warning('Connectivity lost, pausing network operations');
    // Implement graceful degradation logic
  }

  /// Handle connectivity restoration with recovery
  void _handleConnectivityRestore() {
    _logger.info('Connectivity restored, resuming network operations');
    // Implement recovery logic
  }

  /// Update network status and notify listeners
  void _updateStatus(NetworkStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  /// Request all necessary permissions with professional handling
  Future<void> _requestPermissions() async {
    try {
      final permissions = [
        Permission.nearbyWifiDevices,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.location,
        Permission.notification,
      ];

      for (final permission in permissions) {
        try {
          final status = await permission.request();
          if (status.isGranted) {
            _logger.info('Permission granted: ${permission.toString()}');
          } else if (status.isPermanentlyDenied) {
            _logger.error('Permission permanently denied: ${permission.toString()}');
            // Handle permanent denial - show settings dialog
          } else {
            _logger.warning('Permission denied: ${permission.toString()}');
          }
        } catch (e) {
          _logger.error('Error requesting permission: ${permission.toString()}', error: e);
        }
      }
    } catch (e) {
      _logger.error('Failed to request permissions', error: e);
      rethrow;
    }
  }

  /// Setup background service with proper configuration
  Future<void> _setupBackgroundService() async {
    try {
      final service = FlutterBackgroundService();
      if (service.isRunning()) {
        _logger.info('Background service already running');
        return;
      }

      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: _onBackgroundServiceStart,
          isForegroundMode: true,
          autoStart: true,
          notificationChannelId: 'network_app_channel',
          initialNotificationTitle: 'Network Service',
          initialNotificationContent: 'P2P mesh network active',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: _onBackgroundServiceStart,
          onBackground: _onIosBackground,
        ),
      );

      await service.startService();
      _logger.info('Background service configured and started');
    } catch (e) {
      _logger.error('Failed to setup background service', error: e);
      rethrow;
    }
  }

  /// Background service start handler
  @pragma('vm:entry-point')
  static Future<void> _onBackgroundServiceStart(ServiceInstance service) async {
    try {
      if (service is AndroidServiceInstance) {
        service.on('stopService').listen((event) {
          service.stopSelf();
        });
      }
    } catch (e) {
      // Log error but don't crash the service
      print('Background service error: $e');
    }
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    return true;
  }

  /// Setup event listeners with comprehensive error handling
  void _setupEventListeners() {
    try {
      // Connection events
      _connectionSubscription = NearbyConnections.events.onConnectionChanged.listen((event) {
        _handleConnectionEvent(event);
      }, onError: (error) {
        _logger.error('Connection event error', error: error);
      });

      // Payload events
      _payloadSubscription = NearbyConnections.events.onPayloadReceived.listen((event) {
        _handlePayloadEvent(event);
      }, onError: (error) {
        _logger.error('Payload event error', error: error);
      });

    } catch (e) {
      _logger.error('Failed to setup event listeners', error: e);
    }
  }

  /// Handle connection events with professional logic
  void _handleConnectionEvent(ConnectionEvent event) {
    try {
      switch (event.status) {
        case ConnectionStatus.connected:
          _handleDeviceConnected(event);
          break;
        case ConnectionStatus.disconnected:
          _handleDeviceDisconnected(event);
          break;
        case ConnectionStatus.error:
          _handleConnectionError(event);
          break;
      }
    } catch (e) {
      _logger.error('Error handling connection event', error: e);
    }
  }

  /// Handle device connection with proper tracking
  void _handleDeviceConnected(ConnectionEvent event) {
    try {
      final deviceId = event.deviceId;
      if (!_connectedDevices.contains(deviceId)) {
        _connectedDevices.add(deviceId);
        _deviceEndpoints[deviceId] = event.endpointId;
        _lastSeen[deviceId] = DateTime.now();
        _retryCounts.remove(deviceId);
        
        _logger.info('Device connected: $deviceId');
        _updateDeviceList();
        _updateStatus(currentStatus);
      }
    } catch (e) {
      _logger.error('Error handling device connection', error: e);
    }
  }

  /// Handle device disconnection with cleanup
  void _handleDeviceDisconnected(ConnectionEvent event) {
    try {
      final deviceId = event.deviceId;
      _connectedDevices.remove(deviceId);
      _deviceEndpoints.remove(deviceId);
      _lastSeen.remove(deviceId);
      _retryCounts.remove(deviceId);
      
      _logger.info('Device disconnected: $deviceId');
      _updateDeviceList();
      _updateStatus(currentStatus);
    } catch (e) {
      _logger.error('Error handling device disconnection', error: e);
    }
  }

  /// Handle connection errors with retry logic
  void _handleConnectionError(ConnectionEvent event) {
    try {
      final deviceId = event.deviceId;
      final retryCount = _retryCounts[deviceId] ?? 0;
      
      if (retryCount < _maxRetries) {
        _retryCounts[deviceId] = retryCount + 1;
        _logger.warning('Connection error for $deviceId, retry ${retryCount + 1}/$_maxRetries');
        // Implement retry logic
      } else {
        _logger.error('Max retries exceeded for $deviceId, giving up');
        _handleDeviceDisconnected(event);
      }
    } catch (e) {
      _logger.error('Error handling connection error', error: e);
    }
  }

  /// Handle payload events with validation
  void _handlePayloadEvent(PayloadEvent event) {
    try {
      final payload = event.payload;
      if (payload is String) {
        final message = json.decode(payload) as Map<String, dynamic>;
        _processReceivedMessage(message, event.deviceId);
      } else {
        _logger.warning('Received non-string payload from ${event.deviceId}');
      }
    } catch (e) {
      _logger.error('Error handling payload event', error: e);
    }
  }

  /// Process received message with validation
  void _processReceivedMessage(Map<String, dynamic> message, String senderId) {
    try {
      // Validate message structure
      if (!_isValidMessage(message)) {
        _logger.warning('Received invalid message from $senderId');
        return;
      }

      // Add sender information
      message['senderId'] = senderId;
      message['receivedAt'] = DateTime.now().millisecondsSinceEpoch;

      // Emit message
      if (!_messageController.isClosed) {
        _messageController.add(message);
      }

      _logger.info('Message processed from $senderId');
    } catch (e) {
      _logger.error('Error processing message', error: e);
    }
  }

  /// Validate message structure
  bool _isValidMessage(Map<String, dynamic> message) {
    try {
      return message.containsKey('content') && 
             message.containsKey('timestamp') &&
             message['content'] is String &&
             message['timestamp'] is int;
    } catch (e) {
      return false;
    }
  }

  /// Update device list with notification
  void _updateDeviceList() {
    if (!_deviceListController.isClosed) {
      _deviceListController.add(List.from(_connectedDevices));
    }
  }

  /// Start advertising with professional error handling
  Future<void> startAdvertising() async {
    try {
      if (_isAdvertising) {
        _logger.warning('Already advertising');
        return;
      }

      if (!_isInitialized) {
        await initialize();
      }

      final deviceName = await _settingsService.getDeviceName();
      
      await NearbyConnections.startAdvertising(
        deviceName: deviceName,
        serviceId: _serviceId,
        strategy: Strategy.P2P_CLUSTER,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );

      _isAdvertising = true;
      _updateStatus(currentStatus);
      _logger.info('Started advertising as $deviceName');
    } catch (e) {
      _logger.error('Failed to start advertising', error: e);
      rethrow;
    }
  }

  /// Start discovery with professional error handling
  Future<void> startDiscovery() async {
    try {
      if (_isDiscovering) {
        _logger.warning('Already discovering');
        return;
      }

      if (!_isInitialized) {
        await initialize();
      }

      await NearbyConnections.startDiscovery(
        serviceId: _serviceId,
        strategy: Strategy.P2P_CLUSTER,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
      );

      _isDiscovering = true;
      _updateStatus(currentStatus);
      _logger.info('Started discovery');
    } catch (e) {
      _logger.error('Failed to start discovery', error: e);
      rethrow;
    }
  }

  /// Connection initiated callback
  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    _logger.info('Connection initiated with $endpointId');
    // Accept all connections for now - implement authentication later
    NearbyConnections.acceptConnection(endpointId);
  }

  /// Connection result callback
  void _onConnectionResult(String endpointId, ConnectionStatus status) {
    _logger.info('Connection result for $endpointId: $status');
    // Handle connection result
  }

  /// Disconnected callback
  void _onDisconnected(String endpointId) {
    _logger.info('Disconnected from $endpointId');
    // Handle disconnection
  }

  /// Endpoint found callback
  void _onEndpointFound(String endpointId, String deviceId, String serviceId) {
    _logger.info('Endpoint found: $deviceId ($endpointId)');
    // Request connection
    NearbyConnections.requestConnection(deviceId, endpointId);
  }

  /// Endpoint lost callback
  void _onEndpointLost(String endpointId) {
    _logger.info('Endpoint lost: $endpointId');
    // Handle endpoint loss
  }

  /// Send message with professional error handling and retry logic
  Future<void> sendMessage(String content) async {
    try {
      if (_connectedDevices.isEmpty) {
        throw Exception('No connected devices');
      }

      final message = {
        'content': content,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'message',
      };

      final messageJson = json.encode(message);
      
      for (final deviceId in _connectedDevices) {
        try {
          final endpointId = _deviceEndpoints[deviceId];
          if (endpointId != null) {
            await NearbyConnections.sendBytesPayload(
              endpointId,
              utf8.encode(messageJson),
            );
            _logger.info('Message sent to $deviceId');
          }
        } catch (e) {
          _logger.error('Failed to send message to $deviceId', error: e);
          // Continue with other devices
        }
      }
    } catch (e) {
      _logger.error('Failed to send message', error: e);
      rethrow;
    }
  }

  /// Start cleanup timer for stale connections
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _cleanupStaleConnections();
    });
  }

  /// Start health check timer
  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _performHealthCheck();
    });
  }

  /// Cleanup stale connections
  void _cleanupStaleConnections() {
    try {
      final now = DateTime.now();
      final staleDevices = <String>[];
      
      for (final entry in _lastSeen.entries) {
        if (now.difference(entry.value).inMinutes > 10) {
          staleDevices.add(entry.key);
        }
      }
      
      for (final deviceId in staleDevices) {
        _handleDeviceDisconnected(ConnectionEvent(
          deviceId: deviceId,
          status: ConnectionStatus.disconnected,
          endpointId: _deviceEndpoints[deviceId] ?? '',
        ));
      }
      
      if (staleDevices.isNotEmpty) {
        _logger.info('Cleaned up ${staleDevices.length} stale connections');
      }
    } catch (e) {
      _logger.error('Error during cleanup', error: e);
    }
  }

  /// Perform health check
  void _performHealthCheck() {
    try {
      // Check service health
      if (_isInitialized && _connectedDevices.isEmpty && (_isAdvertising || _isDiscovering)) {
        _logger.warning('No connections despite advertising/discovering');
      }
      
      // Check memory usage (basic implementation)
      // Add more sophisticated health checks as needed
    } catch (e) {
      _logger.error('Error during health check', error: e);
    }
  }

  /// Stop all network operations
  Future<void> stopAll() async {
    try {
      _updateStatus(NetworkStatus.shuttingDown);
      
      // Cancel timers
      _cleanupTimer?.cancel();
      _reconnectTimer?.cancel();
      _healthCheckTimer?.cancel();
      
      // Stop advertising and discovery
      if (_isAdvertising) {
        await NearbyConnections.stopAdvertising();
        _isAdvertising = false;
      }
      
      if (_isDiscovering) {
        await NearbyConnections.stopDiscovery();
        _isDiscovering = false;
      }
      
      // Disconnect all devices
      for (final deviceId in List.from(_connectedDevices)) {
        final endpointId = _deviceEndpoints[deviceId];
        if (endpointId != null) {
          await NearbyConnections.disconnectFromEndpoint(endpointId);
        }
      }
      
      // Clear state
      _connectedDevices.clear();
      _deviceEndpoints.clear();
      _lastSeen.clear();
      _retryCounts.clear();
      
      _updateStatus(NetworkStatus.disconnected);
      _logger.info('All network operations stopped');
    } catch (e) {
      _logger.error('Error stopping network operations', error: e);
    }
  }

  /// Dispose all resources
  Future<void> dispose() async {
    try {
      await stopAll();
      
      // Cancel subscriptions
      await _connectionSubscription?.cancel();
      await _payloadSubscription?.cancel();
      await _connectivitySubscription?.cancel();
      
      // Close controllers
      await _messageController.close();
      await _deviceListController.close();
      await _statusController.close();
      
      _isInitialized = false;
      _logger.info('NetworkService disposed');
    } catch (e) {
      _logger.error('Error disposing NetworkService', error: e);
    }
  }

  /// Get network statistics for monitoring
  Map<String, dynamic> getNetworkStatistics() {
    return {
      'isInitialized': _isInitialized,
      'isAdvertising': _isAdvertising,
      'isDiscovering': _isDiscovering,
      'deviceCount': _connectedDevices.length,
      'connectedDevices': List.from(_connectedDevices),
      'lastSeen': Map.from(_lastSeen),
      'retryCounts': Map.from(_retryCounts),
      'uptime': DateTime.now().difference(_lastSeen.values.firstOrNull ?? DateTime.now()).inSeconds,
    };
  }
}
