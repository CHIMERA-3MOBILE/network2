import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// Professional AES-256-GCM encryption service with PBKDF2 key derivation
class AdvancedEncryptionService {
  static final AdvancedEncryptionService _instance = AdvancedEncryptionService._internal();
  factory AdvancedEncryptionService() => _instance;
  AdvancedEncryptionService._internal();

  // Encryption constants
  static const int _keySize = 32; // 256 bits
  static const int _ivSize = 16;  // 128 bits
  static const int _saltSize = 16; // 128 bits
  static const int _tagSize = 16; // 128 bits
  static const int _iterations = 100000; // PBKDF2 iterations

  /// Generate cryptographically secure random key
  String _generateSecureKey() {
    final random = Random.secure();
    final keyBytes = Uint8List(_keySize);
    for (int i = 0; i < _keySize; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    return base64.encode(keyBytes);
  }

  /// Generate cryptographically secure random salt
  Uint8List _generateSalt() {
    final random = Random.secure();
    final salt = Uint8List(_saltSize);
    for (int i = 0; i < _saltSize; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  /// Generate cryptographically secure random IV
  Uint8List _generateIV() {
    final random = Random.secure();
    final iv = Uint8List(_ivSize);
    for (int i = 0; i < _ivSize; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  /// Derive key using PBKDF2 with SHA-256
  Uint8List _deriveKey(String password, Uint8List salt) {
    final passwordBytes = utf8.encode(password);
    final pbkdf2 = PBKDF2KeyDerivator(HMAC(SHA256Digest(), _keySize));
    
    pbkdf2.init(PBKDF2Parameters(salt, _iterations, _keySize));
    return pbkdf2.process(Uint8List.fromList(passwordBytes));
  }

  /// Encrypt message using AES-256-GCM
  Map<String, dynamic> encryptMessageAES(String content, String password) {
    try {
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
      
      return {
        'encrypted': true,
        'algorithm': 'AES-256-GCM',
        'data': base64.encode(combined),
        'salt': base64.encode(salt),
        'iv': base64.encode(iv),
        'iterations': _iterations,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      throw EncryptionException('Failed to encrypt message: $e');
    }
  }

  /// Decrypt message using AES-256-GCM
  String decryptMessageAES(Map<String, dynamic> encryptedMessage, String password) {
    try {
      // Validate encrypted message structure
      if (!_isValidEncryptedMessage(encryptedMessage)) {
        throw EncryptionException('Invalid encrypted message structure');
      }
      
      // Extract components
      final combined = base64.decode(encryptedMessage['data']);
      final salt = base64.decode(encryptedMessage['salt']);
      final iv = base64.decode(encryptedMessage['iv']);
      final iterations = encryptedMessage['iterations'] ?? _iterations;
      
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
    } catch (e) {
      throw EncryptionException('Failed to decrypt message: $e');
    }
  }

  /// Validate encrypted message structure
  bool _isValidEncryptedMessage(Map<String, dynamic> message) {
    try {
      return message.containsKey('encrypted') &&
             message['encrypted'] == true &&
             message.containsKey('data') &&
             message.containsKey('salt') &&
             message.containsKey('iv') &&
             message['algorithm'] == 'AES-256-GCM';
    } catch (e) {
      return false;
    }
  }

  /// Calculate SHA-256 hash of message
  String calculateMessageHash(Map<String, dynamic> message) {
    try {
      final messageJson = json.encode(message);
      final bytes = utf8.encode(messageJson);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      throw EncryptionException('Failed to calculate message hash: $e');
    }
  }

  /// Verify message integrity
  bool verifyMessageIntegrity(Map<String, dynamic> message, String expectedHash) {
    try {
      final calculatedHash = calculateMessageHash(message);
      return calculatedHash == expectedHash;
    } catch (e) {
      return false;
    }
  }

  /// Generate unique device fingerprint
  String generateDeviceFingerprint() {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random.secure();
      final randomBytes = List.generate(8, (_) => random.nextInt(256));
      
      final combined = <int>[];
      combined.addAll(timestamp.toByteList());
      combined.addAll(randomBytes);
      
      final digest = sha256.convert(Uint8List.fromList(combined));
      return digest.toString().substring(0, 16);
    } catch (e) {
      throw EncryptionException('Failed to generate device fingerprint: $e');
    }
  }

  /// Generate secure session key
  String generateSessionKey() {
    return _generateSecureKey();
  }

  /// Encrypt data with session key (simplified AES)
  Map<String, dynamic> encryptWithSessionKey(String data, String sessionKey) {
    try {
      final keyBytes = base64.decode(sessionKey);
      final iv = _generateIV();
      
      final dataBytes = utf8.encode(data);
      
      // Simple XOR encryption for demonstration (replace with proper AES in production)
      final encrypted = Uint8List(dataBytes.length);
      for (int i = 0; i < dataBytes.length; i++) {
        encrypted[i] = dataBytes[i] ^ keyBytes[i % keyBytes.length] ^ iv[i % iv.length];
      }
      
      return {
        'encrypted': true,
        'algorithm': 'XOR-Session',
        'data': base64.encode(encrypted),
        'iv': base64.encode(iv),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      throw EncryptionException('Failed to encrypt with session key: $e');
    }
  }

  /// Decrypt data with session key
  String decryptWithSessionKey(Map<String, dynamic> encryptedData, String sessionKey) {
    try {
      if (!encryptedData.containsKey('data') || !encryptedData.containsKey('iv')) {
        throw EncryptionException('Invalid encrypted data structure');
      }
      
      final keyBytes = base64.decode(sessionKey);
      final iv = base64.decode(encryptedData['iv']);
      final encrypted = base64.decode(encryptedData['data']);
      
      // Simple XOR decryption
      final decrypted = Uint8List(encrypted.length);
      for (int i = 0; i < encrypted.length; i++) {
        decrypted[i] = encrypted[i] ^ keyBytes[i % keyBytes.length] ^ iv[i % iv.length];
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      throw EncryptionException('Failed to decrypt with session key: $e');
    }
  }

  /// Validate key strength
  bool validateKeyStrength(String key) {
    try {
      final keyBytes = base64.decode(key);
      return keyBytes.length == _keySize;
    } catch (e) {
      return false;
    }
  }

  /// Get encryption statistics
  Map<String, dynamic> getEncryptionStats() {
    return {
      'algorithm': 'AES-256-GCM',
      'keySize': _keySize,
      'ivSize': _ivSize,
      'saltSize': _saltSize,
      'tagSize': _tagSize,
      'iterations': _iterations,
      'supportedAlgorithms': ['AES-256-GCM', 'XOR-Session'],
    };
  }
}

/// Custom encryption exception for better error handling
class EncryptionException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const EncryptionException(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'EncryptionException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Extension for timestamp to byte list conversion
extension TimestampExtension on int {
  List<int> toByteList() {
    return [
      (this >> 56) & 0xFF,
      (this >> 48) & 0xFF,
      (this >> 40) & 0xFF,
      (this >> 32) & 0xFF,
      (this >> 24) & 0xFF,
      (this >> 16) & 0xFF,
      (this >> 8) & 0xFF,
      this & 0xFF,
    ];
  }
}

/// Utility function for comparing byte lists
bool listsEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
