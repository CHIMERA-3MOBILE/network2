# 📚 API Reference - Network App

## Overview

This document provides comprehensive API documentation for the Network App's core services and components. All services follow enterprise-grade patterns with proper error handling, logging, and performance monitoring.

## Table of Contents

- [Core Services](#core-services)
- [UI Components](#ui-components)
- [Data Models](#data-models)
- [Utilities](#utilities)
- [Error Handling](#error-handling)

---

## Core Services

### NetworkService

The main P2P networking service handling mesh communication, device discovery, and message routing.

#### Class Definition

```dart
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();
}
```

#### Public Methods

##### `initialize()`
Initializes the network service with comprehensive setup.

```dart
Future<void> initialize() async
```

**Returns:** `Future<void>`

**Throws:** `Exception` if initialization fails

**Example:**
```dart
final networkService = NetworkService();
await networkService.initialize();
```

##### `startAdvertising()`
Starts advertising the device for P2P discovery.

```dart
Future<void> startAdvertising() async
```

**Returns:** `Future<void>`

**Throws:** `Exception` if advertising fails

**Example:**
```dart
await networkService.startAdvertising();
```

##### `startDiscovery()`
Starts discovering nearby devices.

```dart
Future<void> startDiscovery() async
```

**Returns:** `Future<void>`

**Throws:** `Exception` if discovery fails

**Example:**
```dart
await networkService.startDiscovery();
```

##### `sendMessage()`
Sends a message to all connected devices.

```dart
Future<void> sendMessage(String content) async
```

**Parameters:**
- `content` (String): Message content to send

**Returns:** `Future<void>`

**Throws:** `Exception` if no devices connected or send fails

**Example:**
```dart
await networkService.sendMessage("Hello World!");
```

##### `stopAll()`
Stops all network operations and cleans up resources.

```dart
Future<void> stopAll() async
```

**Returns:** `Future<void>`

**Example:**
```dart
await networkService.stopAll();
```

#### Properties

##### `connectedDevices`
Returns list of currently connected device IDs.

```dart
List<String> get connectedDevices
```

##### `isAdvertising`
Returns true if currently advertising.

```dart
bool get isAdvertising
```

##### `isDiscovering`
Returns true if currently discovering.

```dart
bool get isDiscovering
```

##### `deviceCount`
Returns number of connected devices.

```dart
int get deviceCount
```

#### Streams

##### `messageStream`
Stream of incoming messages.

```dart
Stream<Map<String, dynamic>> get messageStream
```

**Example:**
```dart
networkService.messageStream.listen((message) {
  print('Received: ${message['content']}');
});
```

##### `deviceListStream`
Stream of device list updates.

```dart
Stream<List<String>> get deviceListStream
```

##### `statusStream`
Stream of network status changes.

```dart
Stream<NetworkStatus> get statusStream
```

---

### AdvancedEncryptionService

Provides enterprise-grade AES-256-GCM encryption with PBKDF2 key derivation.

#### Class Definition

```dart
class AdvancedEncryptionService {
  static final AdvancedEncryptionService _instance = AdvancedEncryptionService._internal();
  factory AdvancedEncryptionService() => _instance;
  AdvancedEncryptionService._internal();
}
```

#### Public Methods

##### `encryptMessageAES()`
Encrypts a message using AES-256-GCM.

```dart
Map<String, dynamic> encryptMessageAES(String content, String password)
```

**Parameters:**
- `content` (String): Message content to encrypt
- `password` (String): Password for encryption

**Returns:** `Map<String, dynamic>` - Encrypted message data

**Throws:** `EncryptionException` if encryption fails

**Example:**
```dart
final encryptionService = AdvancedEncryptionService();
final encrypted = encryptionService.encryptMessageAES(
  "Secret message", 
  "secure-password"
);
```

##### `decryptMessageAES()`
Decrypts an AES-256-GCM encrypted message.

```dart
String decryptMessageAES(Map<String, dynamic> encryptedMessage, String password)
```

**Parameters:**
- `encryptedMessage` (Map): Encrypted message data
- `password` (String): Password for decryption

**Returns:** `String` - Decrypted message content

**Throws:** `EncryptionException` if decryption fails

**Example:**
```dart
final decrypted = encryptionService.decryptMessageAES(
  encrypted, 
  "secure-password"
);
```

##### `calculateMessageHash()`
Calculates SHA-256 hash of a message.

```dart
String calculateMessageHash(Map<String, dynamic> message)
```

**Parameters:**
- `message` (Map): Message data to hash

**Returns:** `String` - SHA-256 hash

**Example:**
```dart
final hash = encryptionService.calculateMessageHash({
  'content': 'test',
  'timestamp': 1234567890
});
```

##### `verifyMessageIntegrity()`
Verifies message integrity using hash.

```dart
bool verifyMessageIntegrity(Map<String, dynamic> message, String expectedHash)
```

**Parameters:**
- `message` (Map): Message data to verify
- `expectedHash` (String): Expected hash value

**Returns:** `bool` - True if integrity verified

**Example:**
```dart
final isValid = encryptionService.verifyMessageIntegrity(message, hash);
```

##### `generateDeviceFingerprint()`
Generates unique device fingerprint.

```dart
String generateDeviceFingerprint()
```

**Returns:** `String` - 16-character fingerprint

**Example:**
```dart
final fingerprint = encryptionService.generateDeviceFingerprint();
```

---

### ErrorHandlingService

Provides comprehensive error handling with retry logic and circuit breaker patterns.

#### Class Definition

```dart
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();
}
```

#### Public Methods

##### `executeWithRetry()`
Executes operation with exponential backoff retry.

```dart
Future<T> executeWithRetry<T>(
  Future<T> Function() operation,
  String operationName, {
  int maxRetries = 3,
  Duration? baseDelay,
  double? backoffMultiplier,
  Duration? maxDelay,
  bool Function(dynamic error)? retryCondition,
})
```

**Parameters:**
- `operation` (Function): Async operation to execute
- `operationName` (String): Name for logging
- `maxRetries` (int): Maximum retry attempts
- `baseDelay` (Duration): Initial delay between retries
- `backoffMultiplier` (double): Multiplier for exponential backoff
- `maxDelay` (Duration): Maximum delay between retries
- `retryCondition` (Function): Custom retry condition

**Returns:** `Future<T>` - Operation result

**Throws:** `OperationException` if all retries fail

**Example:**
```dart
final errorService = ErrorHandlingService();
final result = await errorService.executeWithRetry(
  () => networkOperation(),
  'network-operation',
  maxRetries: 3,
);
```

##### `executeWithErrorHandling()`
Executes operation with comprehensive error handling.

```dart
Future<T> executeWithErrorHandling<T>(
  Future<T> Function() operation,
  String operationName, {
  T? fallbackValue,
  bool Function(dynamic error)? shouldRetry,
  Future<void> Function(dynamic error)? onError,
  Duration? timeout,
})
```

**Parameters:**
- `operation` (Function): Async operation to execute
- `operationName` (String): Name for logging
- `fallbackValue` (T): Value to return on failure
- `shouldRetry` (Function): Condition for retry
- `onError` (Function): Custom error handler
- `timeout` (Duration): Operation timeout

**Returns:** `Future<T>` - Operation result or fallback

**Example:**
```dart
final result = await errorService.executeWithErrorHandling(
  () => riskyOperation(),
  'risky-operation',
  fallbackValue: 'default',
  timeout: Duration(seconds: 30),
);
```

##### `getErrorStatistics()`
Gets comprehensive error statistics.

```dart
Map<String, dynamic> getErrorStatistics()
```

**Returns:** `Map<String, dynamic>` - Error statistics

**Example:**
```dart
final stats = errorService.getErrorStatistics();
print('Total errors: ${stats['totalErrors']}');
```

---

### PerformanceMonitorService

Real-time performance monitoring with health scoring and optimization suggestions.

#### Class Definition

```dart
class PerformanceMonitorService {
  static final PerformanceMonitorService _instance = PerformanceMonitorService._internal();
  factory PerformanceMonitorService() => _instance;
  PerformanceMonitorService._internal();
}
```

#### Public Methods

##### `startMonitoring()`
Starts performance monitoring.

```dart
void startMonitoring()
```

**Example:**
```dart
final performanceService = PerformanceMonitorService();
performanceService.startMonitoring();
```

##### `stopMonitoring()`
Stops performance monitoring.

```dart
void stopMonitoring()
```

**Example:**
```dart
performanceService.stopMonitoring();
```

##### `trackOperation()`
Tracks synchronous operation performance.

```dart
T trackOperation<T>(String operationName, T Function() operation)
```

**Parameters:**
- `operationName` (String): Name for tracking
- `operation` (Function): Operation to track

**Returns:** `T` - Operation result

**Example:**
```dart
final result = performanceService.trackOperation(
  'data-processing',
  () => processData(),
);
```

##### `trackAsyncOperation()`
Tracks asynchronous operation performance.

```dart
Future<T> trackAsyncOperation<T>(String operationName, Future<T> Function() operation)
```

**Parameters:**
- `operationName` (String): Name for tracking
- `operation` (Function): Async operation to track

**Returns:** `Future<T>` - Operation result

**Example:**
```dart
final result = await performanceService.trackAsyncOperation(
  'network-request',
  () => makeRequest(),
);
```

##### `getPerformanceReport()`
Gets comprehensive performance report.

```dart
Map<String, dynamic> getPerformanceReport()
```

**Returns:** `Map<String, dynamic>` - Performance metrics

**Example:**
```dart
final report = performanceService.getPerformanceReport();
print('Average duration: ${report['avgDuration']}ms');
```

##### `getHealthScore()`
Gets overall system health score (0-100).

```dart
double getHealthScore()
```

**Returns:** `double` - Health score

**Example:**
```dart
final score = performanceService.getHealthScore();
if (score < 70) {
  print('System health is poor');
}
```

---

### AdvancedMeshRoutingService

Advanced mesh routing with multiple algorithms and load balancing.

#### Class Definition

```dart
class AdvancedMeshRoutingService {
  static final AdvancedMeshRoutingService _instance = AdvancedMeshRoutingService._internal();
  factory AdvancedMeshRoutingService() => _instance;
  AdvancedMeshRoutingService._internal();
}
```

#### Public Methods

##### `initialize()`
Initializes the mesh routing service.

```dart
Future<void> initialize() async
```

**Example:**
```dart
final routingService = AdvancedMeshRoutingService();
await routingService.initialize();
```

##### `addNode()`
Adds a node to the mesh network.

```dart
void addNode(MeshNode node)
```

**Parameters:**
- `node` (MeshNode): Node to add

**Example:**
```dart
routingService.addNode(MeshNode(
  id: 'node1',
  name: 'Device 1',
  neighbors: ['node2'],
  lastSeen: DateTime.now(),
));
```

##### `routeMessageWithLoadBalancing()`
Routes message with load balancing.

```dart
List<String> routeMessageWithLoadBalancing(String destinationId, Map<String, dynamic> message)
```

**Parameters:**
- `destinationId` (String): Target device ID
- `message` (Map): Message data

**Returns:** `List<String>` - Path of device IDs

**Example:**
```dart
final path = routingService.routeMessageWithLoadBalancing(
  'target-device',
  {'content': 'Hello'},
);
```

##### `getNetworkStatistics()`
Gets network topology statistics.

```dart
Map<String, dynamic> getNetworkStatistics()
```

**Returns:** `Map<String, dynamic>` - Network statistics

**Example:**
```dart
final stats = routingService.getNetworkStatistics();
print('Network size: ${stats['nodeCount']}');
```

---

## UI Components

### ProfessionalUIComponents

Professional UI component library with Material Design 3 compliance.

#### Static Methods

##### `professionalCard()`
Creates a professional card with animations.

```dart
static Widget professionalCard({
  required Widget child,
  EdgeInsetsGeometry? margin,
  EdgeInsetsGeometry? padding,
  Color? color,
  double? elevation,
  VoidCallback? onTap,
  bool enableHover = true,
  bool enableRipple = true,
})
```

**Example:**
```dart
ProfessionalUIComponents.professionalCard(
  child: Text('Card Content'),
  onTap: () => print('Card tapped'),
);
```

##### `professionalButton()`
Creates a professional button with multiple variants.

```dart
static Widget professionalButton({
  required String text,
  required VoidCallback onPressed,
  ButtonVariant variant = ButtonVariant.primary,
  ButtonSize size = ButtonSize.medium,
  IconData? icon,
  bool fullWidth = false,
  bool isLoading = false,
  bool disabled = false,
})
```

**Example:**
```dart
ProfessionalUIComponents.professionalButton(
  text: 'Submit',
  onPressed: () => handleSubmit(),
  variant: ButtonVariant.primary,
  icon: Icons.send,
);
```

##### `professionalTextField()`
Creates a professional text field with validation.

```dart
static Widget professionalTextField({
  required String label,
  required TextEditingController controller,
  String? hintText,
  String? errorText,
  IconData? prefixIcon,
  IconData? suffixIcon,
  bool obscureText = false,
  TextInputType keyboardType = TextInputType.text,
  ValueChanged<String>? onChanged,
  VoidCallback? onSuffixIconTap,
  bool enabled = true,
  int maxLines = 1,
})
```

**Example:**
```dart
ProfessionalUIComponents.professionalTextField(
  label: 'Password',
  controller: passwordController,
  obscureText: true,
  prefixIcon: Icons.lock,
);
```

---

## Data Models

### MeshNode

Represents a node in the mesh network.

```dart
class MeshNode {
  final String id;
  final String name;
  final List<String> neighbors;
  final DateTime lastSeen;
  final Map<String, dynamic> metadata;
}
```

### MeshRoute

Represents a route through the mesh network.

```dart
class MeshRoute {
  final String destination;
  final List<String> path;
  final int totalHops;
  final double reliability;
  final DateTime calculatedAt;
}
```

### MeshMessage

Represents a message in the mesh network.

```dart
class MeshMessage {
  final String id;
  final String destinationId;
  final Map<String, dynamic> message;
  final MeshRoute route;
  final DateTime createdAt;
}
```

### PerformanceMetric

Represents a performance measurement.

```dart
class PerformanceMetric {
  final String operationName;
  final Duration duration;
  final int memoryUsage;
  final int memoryDelta;
  final bool success;
  final DateTime timestamp;
  final String? error;
}
```

---

## Enums

### NetworkStatus

Network status enumeration.

```dart
enum NetworkStatus {
  disconnected,
  connected,
  active,
  error,
  initializing,
  shuttingDown,
}
```

### ButtonVariant

Button style variants.

```dart
enum ButtonVariant { primary, secondary, outline, text }
```

### ButtonSize

Button size options.

```dart
enum ButtonSize { small, medium, large }
```

### StatusType

Status indicator types.

```dart
enum StatusType { success, warning, error, info, neutral }
```

---

## Error Handling

### Custom Exceptions

#### EncryptionException

Thrown for encryption-related errors.

```dart
class EncryptionException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
}
```

#### RoutingException

Thrown for routing-related errors.

```dart
class RoutingException implements Exception {
  final String message;
}
```

#### NetworkException

Thrown for network-related errors.

```dart
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;
}
```

#### OperationException

Thrown for general operation failures.

```dart
class OperationException implements Exception {
  final String message;
  final String? operationName;
  final dynamic originalError;
}
```

---

## Usage Examples

### Complete Network Setup

```dart
// Initialize all services
final networkService = NetworkService();
final encryptionService = AdvancedEncryptionService();
final routingService = AdvancedMeshRoutingService();
final errorService = ErrorHandlingService();
final performanceService = PerformanceMonitorService();

// Start monitoring
performanceService.startMonitoring();

// Initialize network
await errorService.executeWithErrorHandling(
  () => networkService.initialize(),
  'network-initialization',
);

// Add routing node
routingService.addNode(MeshNode(
  id: 'my-device',
  name: 'My Device',
  neighbors: [],
  lastSeen: DateTime.now(),
));

// Start advertising and discovery
await networkService.startAdvertising();
await networkService.startDiscovery();

// Listen for messages
networkService.messageStream.listen((message) async {
  // Decrypt message
  final decrypted = await errorService.executeWithRetry(
    () => encryptionService.decryptMessageAES(message, 'password'),
    'message-decryption',
  );
  
  print('Received: $decrypted');
});

// Send encrypted message
final message = {'content': 'Hello World!', 'timestamp': DateTime.now().millisecondsSinceEpoch};
final encrypted = encryptionService.encryptMessageAES(
  json.encode(message),
  'password',
);

await networkService.sendMessage(json.encode(encrypted));
```

### Performance Monitoring

```dart
// Track operation performance
final result = await performanceService.trackAsyncOperation(
  'data-processing',
  () async {
    // Simulate data processing
    await Future.delayed(Duration(seconds: 2));
    return 'Processed data';
  },
);

// Get performance report
final report = performanceService.getPerformanceReport();
print('Average operation time: ${report['avgDuration']}ms');

// Get health score
final healthScore = performanceService.getHealthScore();
if (healthScore < 70) {
  print('System health needs attention');
}

// Listen for performance alerts
performanceService.alertStream.listen((alert) {
  print('Performance alert: ${alert.message}');
});
```

---

## Best Practices

### Error Handling

1. **Always wrap operations in try-catch blocks**
2. **Use the ErrorHandlingService for retry logic**
3. **Provide meaningful error messages**
4. **Log errors for debugging**

### Performance

1. **Track critical operations with PerformanceMonitorService**
2. **Monitor memory usage and prevent leaks**
3. **Use async operations for I/O tasks**
4. **Implement proper cleanup in dispose methods**

### Security

1. **Always encrypt sensitive data**
2. **Use unique salts for each encryption**
3. **Verify message integrity**
4. **Implement proper key management**

### Network

1. **Handle network failures gracefully**
2. **Implement proper cleanup on disconnect**
3. **Use appropriate timeouts**
4. **Monitor network health**

---

## Version History

### v1.0.0
- Initial release with core P2P functionality
- AES-256-GCM encryption
- Basic mesh routing
- Performance monitoring
- Professional UI components

---

For more detailed examples and advanced usage, see the [README.md](../README.md) and test files in the [test/](../test) directory.
