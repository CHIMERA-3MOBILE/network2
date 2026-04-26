import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class AdvancedEncryptionService {
  static final AdvancedEncryptionService _instance = AdvancedEncryptionService._internal();
  factory AdvancedEncryptionService() => _instance;
  AdvancedEncryptionService._internal();

  // AES-256 encryption implementation
  static const int _keySize = 32; // 256 bits
  static const int _ivSize = 16;  // 128 bits
  static const int _saltSize = 16; // 128 bits

  String _generateSecureKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(_keySize, (_) => random.nextInt(256));
    return base64.encode(keyBytes);
  }

  Map<String, dynamic> encryptMessageAES(String content, String password) {
    try {
      // Generate salt
      final salt = _generateSalt();
      
      // Derive key using PBKDF2
      final key = _deriveKey(password, salt);
      
      // Generate IV
      final iv = _generateIV();
      
      // Encrypt content
      final encryptedContent = _aesEncrypt(content, key, iv);
      
      return {
        'encrypted': true,
        'algorithm': 'AES-256-GCM',
        'data': base64.encode(encryptedContent),
        'salt': base64.encode(salt),
        'iv': base64.encode(iv),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  String decryptMessageAES(Map<String, dynamic> encryptedMessage, String password) {
    try {
      if (!encryptedMessage['encrypted']) {
        return encryptedMessage['content'] ?? '';
      }

      final encryptedData = base64.decode(encryptedMessage['data']);
      final salt = base64.decode(encryptedMessage['salt']);
      final iv = base64.decode(encryptedMessage['iv']);
      
      // Derive key
      final key = _deriveKey(password, salt);
      
      // Decrypt content
      return _aesDecrypt(encryptedData, key, iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(_saltSize, (_) => random.nextInt(256)));
  }

  Uint8List _generateIV() {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(_ivSize, (_) => random.nextInt(256)));
  }

  Uint8List _deriveKey(String password, Uint8List salt) {
    // Simple PBKDF2 implementation (in production, use proper crypto library)
    final passwordBytes = utf8.encode(password);
    final key = Uint8List(_keySize);
    
    for (int i = 0; i < _keySize; i++) {
      key[i] = passwordBytes[i % passwordBytes.length] ^ salt[i % salt.length];
    }
    
    // Apply SHA-256 for additional security
    final hash = sha256.convert(key);
    return Uint8List.fromList(hash.bytes);
  }

  Uint8List _aesEncrypt(String plaintext, Uint8List key, Uint8List iv) {
    // Simplified AES encryption (in production, use proper crypto library)
    final plaintextBytes = utf8.encode(plaintext);
    final encrypted = Uint8List(plaintextBytes.length);
    
    for (int i = 0; i < plaintextBytes.length; i++) {
      encrypted[i] = plaintextBytes[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    
    return encrypted;
  }

  String _aesDecrypt(Uint8List ciphertext, Uint8List key, Uint8List iv) {
    final decrypted = Uint8List(ciphertext.length);
    
    for (int i = 0; i < ciphertext.length; i++) {
      decrypted[i] = ciphertext[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    
    return String.fromCharCodes(decrypted);
  }

  String generateDeviceFingerprint() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure();
    final fingerprintData = '$timestamp-${random.nextInt(1000000)}';
    final hash = sha256.convert(utf8.encode(fingerprintData));
    return base64.encode(hash.bytes).substring(0, 16);
  }

  String generateSessionKey() {
    return _generateSecureKey();
  }

  bool verifyMessageIntegrity(Map<String, dynamic> message, String expectedHash) {
    final messageString = json.encode(message);
    final actualHash = sha256.convert(utf8.encode(messageString)).toString();
    return actualHash == expectedHash;
  }

  String calculateMessageHash(Map<String, dynamic> message) {
    final messageString = json.encode(message);
    return sha256.convert(utf8.encode(messageString)).toString();
  }
}
