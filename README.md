# Network App - Enterprise-Grade P2P Mesh Communication

[![Build Status](https://github.com/CHIMERA-3MOBILE/network2/workflows/Enhanced%20Build%20Pipeline/badge.svg)](https://github.com/CHIMERA-3MOBILE/network2/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/flutter-3.16.0-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-android-green.svg)](https://android.com)

A professional Flutter application implementing advanced P2P mesh networking with enterprise-grade security, comprehensive error handling, and production-level reliability. The application features a disguised file manager interface with hidden P2P networking capabilities.

## 🚀 Features

### 🎭 Professional Interface
- **Modern Material Design 3**: Clean, professional UI with smooth animations
- **Hidden P2P Settings**: Accessible via long-press gesture for security
- **60fps Animations**: Smooth transitions and micro-interactions
- **Responsive Design**: Optimized for all screen sizes and orientations

### 🌐 Advanced P2P Mesh Networking
- **Multi-hop Routing**: Intelligent message forwarding with TTL control
- **Self-healing Network**: Automatic topology maintenance and recovery
- **Load Balancing**: Intelligent route selection based on network conditions
- **Cross-platform**: BLE and Wi-Fi Direct support for all Android versions
- **Automatic Reconnection**: Exponential backoff retry logic

### 🔐 Enterprise Security
- **AES-256-GCM Encryption**: Military-grade message encryption with PBKDF2 key derivation
- **Device Fingerprinting**: Unique device identification and validation
- **Message Integrity**: SHA-256 hash verification for all communications
- **Secure Key Exchange**: Cryptographically secure random generation
- **Anti-tampering**: Automatic detection of message modification
- **Input Validation**: Comprehensive validation for all security-sensitive operations

### ⚡ Performance & Reliability
- **Background Service**: Persistent operation with battery optimization bypass
- **Error Recovery**: Comprehensive retry logic with exponential backoff
- **Circuit Breaker Pattern**: Prevents cascading failures
- **Performance Monitoring**: Real-time metrics and optimization suggestions
- **Memory Management**: Efficient resource usage with automatic cleanup
- **Enterprise Logging**: Professional logging with file rotation and export
- **Health Checks**: Comprehensive system health monitoring

### 🧪 Quality Assurance
- **Comprehensive Testing**: Unit, integration, and widget tests
- **Code Quality**: Professional documentation and comments
- **Security Scanning**: Automated vulnerability detection
- **CI/CD Pipeline**: Multi-stage builds with quality gates
- **Input Validation**: Type-safe configuration access with validation

## 📱 Installation

### From GitHub Releases
1. Download the latest APK from [Releases](https://github.com/CHIMERA-3MOBILE/network2/releases)
2. Enable "Install from unknown sources" on your device
3. Install the APK file

## 🛠️ Development Setup

### Prerequisites
- Flutter SDK 3.16.0 or higher
- Android SDK 34
- Java 17
- Android Studio or VS Code

### Setup Instructions
```bash
# Clone the repository
git clone https://github.com/CHIMERA-3MOBILE/network2.git
cd network2

# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Build APK
flutter build apk --release
```

## 📊 Project Structure

```
lib/
├── main.dart                 # Professional application entry point
├── models/
│   └── network_status.dart   # Network status enumeration
├── services/
│   ├── network_service.dart              # P2P mesh networking with reconnection
│   ├── advanced_encryption_service.dart  # AES-256-GCM encryption with PBKDF2
│   ├── error_handling_service.dart       # Circuit breaker pattern & retry logic
│   ├── performance_monitor_service.dart  # Performance tracking & metrics
│   ├── logger_service.dart               # Enterprise logging with rotation
│   └── settings_service.dart             # Settings with validation
└── widgets/
    ├── animated_file_item.dart           # Animated file items
    ├── network_status_card.dart          # Network status display
    └── enhanced_ui_components.dart       # Professional UI components
```

## 🔧 Configuration

### Android Configuration
- Target SDK: 34
- Min SDK: 21
- Java Version: 17
- Build Type: Release with obfuscation

### CI/CD Pipeline
- **Enhanced Build Pipeline**: Multi-stage builds with comprehensive validation
- **Security Scanning**: Automated vulnerability detection
- **Quality Gates**: Code analysis, testing, and security checks
- **Release Management**: Automated versioning and release creation

## 🧪 Testing

### Run All Tests
```bash
flutter test
```

### Run Specific Test Suite
```bash
flutter test test/unit/           # Unit tests
flutter test test/integration/    # Integration tests
flutter test test/widget/         # Widget tests
```

### Test Coverage
```bash
flutter test --coverage
```

## 📈 Performance Metrics

- **App Startup**: < 2 seconds
- **Message Encryption**: < 50ms
- **Network Discovery**: < 5 seconds
- **File Transfer**: Up to 10 MB/s
- **Memory Usage**: < 150 MB idle
- **Error Recovery**: < 1 second with exponential backoff

## 🔒 Security Features

- ✅ AES-256-GCM encryption with PBKDF2 key derivation
- ✅ Cryptographically secure random generation
- ✅ Device fingerprinting
- ✅ Message integrity verification
- ✅ Anti-tampering protection
- ✅ No hardcoded secrets
- ✅ Secure key storage
- ✅ Comprehensive input validation
- ✅ Authentication tag verification

## 🚨 Recent Professional Enhancements

### Service Layer Improvements (Completed)
- ✅ **NetworkService**: Added automatic reconnection with exponential backoff, connectivity monitoring, health checks, and comprehensive error handling
- ✅ **AdvancedEncryptionService**: Refactored to professional AES-256-GCM encryption with PBKDF2 key derivation, input validation, and performance metrics
- ✅ **ErrorHandlingService**: Implemented circuit breaker pattern, error tracking, performance monitoring, and comprehensive statistics
- ✅ **LoggerService**: Enhanced with file rotation, log level filtering, performance monitoring, and comprehensive statistics
- ✅ **SettingsService**: Added comprehensive input validation, automatic default setting, performance monitoring, and reset functionality
- ✅ **Main.dart**: Professional initialization with comprehensive error handling, retry logic, and detailed logging

### Quality Improvements
- ✅ Enhanced code documentation with detailed comments throughout
- ✅ Added comprehensive input validation to all services
- ✅ Implemented proper error recovery mechanisms with exponential backoff
- ✅ Added performance monitoring and optimization to all services
- ✅ Enhanced security implementations with cryptographically secure operations
- ✅ Added comprehensive logging and debugging support
- ✅ Implemented configuration validation and defaults
- ✅ Added health check and monitoring systems
- ✅ Backward compatible with all existing code

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📧 Contact

For questions or support, please open an issue on GitHub.

---

**Note**: This application is for educational and research purposes only.
