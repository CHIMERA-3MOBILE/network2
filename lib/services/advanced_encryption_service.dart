import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'logger_service.dart';

/// Professional AES-256-GCM encryption service with PBKDF2 key derivation
/// 
/// This service provides enterprise-grade encryption capabilities with:
/// - AES-256-GCM encryption for maximum security
/// - PBKDF2 key derivation with configurable iterations
/// - Cryptographically secure random number generation
/// - Message integrity verification via authentication tags
/// - Comprehensive error handling and validation
/// - Performance optimization for mobile devices
class AdvancedEncryptionService {
  static final AdvancedEncryptionService _instance = AdvancedEncryptionService._internal();
  factory AdvancedEncryptionService() => _instance;
  AdvancedEncryptionService._internal();

  // Encryption constants following NIST recommendations
  static const int _keySize = 32; // 256 bits for AES-256
  static const int _ivSize = 16;  // 128 bits for GCM IV
  static const int _saltSize = 16; // 128 bits for PBKDF2 salt
  static const int _tagSize = 16; // 128 bits for GCM authentication tag
  static const int _iterations = 100000; // PBKDF2 iterations (NIST recommended)
  static const int _maxMessageSize = 1024 * 1024; // 1MB max message size
  
  final LoggerService _logger = LoggerService();
  
  // Performance monitoring
  int _encryptionCount = 0;
  int _decryptionCount = 0;
  DateTime _lastReset = DateTime.now();

  /// Generate cryptographically secure random key
  /// 
  /// Uses cryptographically secure random number generator
  /// to generate a 256-bit key encoded in base64 format.
  /// 
  /// Returns base64-encoded 256-bit key
  String _generateSecureKey() {
    try {
      final random = Random.secure();
      final keyBytes = Uint8List(_keySize);
      for (int i = 0; i < _keySize; i++) {
        keyBytes[i] = random.nextInt(256);
      }
      return base64.encode(keyBytes);
    } catch (e, stackTrace) {
      _logger.error('Failed to generate secure key', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generate cryptographically secure random salt
  /// 
  /// Uses cryptographically secure random number generator
  /// to generate a 128-bit salt for key derivation.
  /// 
  /// Returns 128-bit salt as Uint8List
  Uint8List _generateSalt() {
    try {
      final random = Random.secure();
      final salt = Uint8List(_saltSize);
      for (int i = 0; i < _saltSize; i++) {
        salt[i] = random.nextInt(256);
      }
      return salt;
    } catch (e, stackTrace) {
      _logger.error('Failed to generate salt', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generate cryptographically secure random IV
  /// 
  /// Uses cryptographically secure random number generator
  /// to generate a 128-bit initialization vector for GCM mode.
  /// 
  /// Returns 128-bit IV as Uint8List
  Uint8List _generateIV() {
    try {
      final random = Random.secure();
      final iv = Uint8List(_ivSize);
      for (int i = 0; i < _ivSize; i++) {
        iv[i] = random.nextInt(256);
      }
      return iv;
    } catch (e, stackTrace) {
      _logger.error('Failed to generate IV', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Derive key using PBKDF2 with SHA-256
/// 
/// Uses PBKDF2-HMAC-SHA256 with 100,000 iterations to derive
/// a 256-bit key from a password and salt, following NIST recommendations.
/// 
/// [password] - The password to derive the key from
/// [salt] - The salt for key derivation
/// Returns 256-bit derived key as Uint8List
  Uint8List _deriveKey(String password, Uint8List salt) {
    try {
      if (password.isEmpty) {
        throw ArgumentError('Password cannot be empty');
      }
      if (salt.length != _saltSize) {
        throw ArgumentError('Salt must be $_saltSize bytes');
      }
      
      final passwordBytes = utf8.encode(password);
      final pbkdf2 = PBKDF2KeyDerivator(HMAC(SHA256Digest(), _keySize));
      
      pbkdf2.init(PBKDF2Parameters(salt, _iterations, _keySize));
      return pbkdf2.process(Uint8List.fromList(passwordBytes));
    } catch (e, stackTrace) {
      _logger.error('Failed to derive key', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Encrypt message using AES-256-GCM with comprehensive validation
/// 
/// Encrypts the given content using AES-256-GCM with automatic
/// salt and IV generation, and includes authentication tag for integrity verification.
/// 
/// [content] - The plaintext message to encrypt
/// [password] - The password for key derivation
/// Returns map containing encrypted data, salt, IV, and metadata
/// 
/// Throws [ArgumentError] if content or password is invalid
/// Throws [Exception] if encryption fails
  Map<String, dynamic> encryptMessageAES(String content, String password) {
    try {
      // Input validation
      if (content.isEmpty) {
        throw ArgumentError('Content cannot be empty');
      }
      if (password.isEmpty) {
        throw ArgumentError('Password cannot be empty');
      }
      if (content.length > _maxMessageSize) {
        throw ArgumentError('Content exceeds maximum size of $_maxMessageSize bytes');
      }
      
      // Generate salt and IV
      final salt = _generateSalt();
      final iv = _generateIV();
      
      // Derive key
      final key = _deriveKey(password, salt);
      
      // Convert content to bytes
      final contentBytes = utf8.encode(content);
      
      // Create cipher
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          true,
          AEADParameters(
            KeyParameter(key),
            _tagSize * 8, // tag size in bits
            iv,
            Uint8List(0), // no additional data
          ),
        );
      
      // Encrypt
      final encryptedBytes = cipher.process(Uint8List.fromList(contentBytes));
      final tag = cipher.mac;
      
      // Combine encrypted data and tag
      final combined = Uint8List(encryptedBytes.length + tag.length);
      combined.setRange(0, encryptedBytes.length, encryptedBytes);
      combined.setRange(encryptedBytes.length, combined.length, tag);
      
      _encryptionCount++;
      
      return {
        'encrypted': true,
        'algorithm': 'AES-256-GCM',
        'data': base64.encode(combined),
        'salt': base64.encode(salt),
        'iv': base64.encode(iv),
        'iterations': _iterations,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e, stackTrace) {
      _logger.error('Failed to encrypt message', error: e, stackTrace: stackTrace);
      throw EncryptionException('Failed to encrypt message: $e');
    }
  }

  /// Decrypt message using AES-256-GCM with comprehensive validation
  /// 
  /// Decrypts the given encrypted message using AES-256-GCM with
  /// authentication tag verification for integrity checking.
  /// 
  /// [encryptedMessage] - The encrypted message map containing data, salt, IV
  /// [password] - The password for key derivation
  /// Returns decrypted plaintext message
  /// 
  /// Throws [ArgumentError] if encrypted message structure is invalid
  /// Throws [EncryptionException] if decryption fails or authentication fails
  String decryptMessageAES(Map<String, dynamic> encryptedMessage, String password) {
    try {
      // Validate encrypted message structure
      if (!_isValidEncryptedMessage(encryptedMessage)) {
        throw ArgumentError('Invalid encrypted message structure');
      }
      if (password.isEmpty) {
        throw ArgumentError('Password cannot be empty');
      }
      
      // Extract components
      final combined = base64.decode(encryptedMessage['data']);
      final salt = base64.decode(encryptedMessage['salt']);
      final iv = base64.decode(encryptedMessage['iv']);
      final iterations = encryptedMessage['iterations'] ?? _iterations;
      
      // Validate sizes
      if (salt.length != _saltSize) {
        throw ArgumentError('Invalid salt size');
      }
      if (iv.length != _ivSize) {
        throw ArgumentError('Invalid IV size');
      }
      
      // Derive key
      final key = _deriveKey(password, salt);
      
      // Split encrypted data and tag
      final encryptedBytes = combined.sublist(0, combined.length - _tagSize);
      final tag = combined.sublist(combined.length - _tagSize);
      
      // Create cipher
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(
            KeyParameter(key),
            _tagSize * 8,
            iv,
            Uint8List(0),
          ),
        );
      
      // Decrypt
      final decryptedBytes = cipher.process(Uint8List.fromList(encryptedBytes));
      
      // Verify tag
      if (!listsEqual(cipher.mac, tag)) {
        throw EncryptionException('Authentication failed - invalid tag');
      }
      
      return utf8.decode(decryptedBytes);
    } catch (e, stackTrace) {
      _logger.error('Failed to decrypt message', error: e, stackTrace: stackTrace);
      throw EncryptionException('Failed to decrypt message: $e');
    }
  }

  /// Validate encrypted message structure
  /// 
  /// Verifies that the encrypted message map contains all required
  /// fields and has valid data types.
  bool _isValidEncryptedMessage(Map<String, dynamic> message) {
    return message.containsKey('encrypted') &&
           message['encrypted'] == true &&
           message.containsKey('data') &&
           message.containsKey('salt') &&
           message.containsKey('iv') &&
           message['data'] is String &&
           message['salt'] is String &&
           message['iv'] is String;
  }

  /// Get performance metrics for monitoring and debugging
  /// 
  /// Returns a map containing:
  /// - encryptionCount: total number of encryptions performed
  /// - decryptionCount: total number of decryptions performed
  /// - lastReset: timestamp of last metrics reset
  /// - uptime: time since last reset in seconds
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'encryptionCount': _encryptionCount,
      'decryptionCount': _decryptionCount,
      'lastReset': _lastReset.toIso8601String(),
      'uptime': DateTime.now().difference(_lastReset).inSeconds,
    };
  }

  /// Reset performance metrics counters
  void resetMetrics() {
    _encryptionCount = 0;
    _decryptionCount = 0;
    _lastReset = DateTime.now();
    _logger.info('Encryption service metrics reset');
  }

  /// Generate a secure session key for temporary encryption
  /// 
  /// Generates a cryptographically secure random key for
  /// temporary session-based encryption.
  /// 
  /// Returns base64-encoded 256-bit session key
  String generateSessionKey() {
    return _generateSecureKey();
  }

  /// Hash data using SHA-256 for integrity verification
  /// 
  /// Computes SHA-256 hash of the given data for integrity
  /// verification and message authentication.
  /// 
  /// [data] - The data to hash
  /// Returns hex-encoded SHA-256 hash
  String hashData(String data) {
    try {
      final bytes = utf8.encode(data);
      final hash = sha256.convert(bytes);
      return hash.toString();
    } catch (e, stackTrace) {
      _logger.error('Failed to hash data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

/// Custom exception for encryption-related errors
class EncryptionException implements Exception {
  final String message;
  
  EncryptionException(this.message);
  
  @override
  String toString() => 'EncryptionException: $message';
}

/// Utility function for comparing byte lists
bool listsEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
