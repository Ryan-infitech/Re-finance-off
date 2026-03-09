import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static final EncryptionService instance = EncryptionService._init();

  EncryptionService._init();

  encrypt_lib.Key? _aesKey;

  static const _keyStorageKey = 'app_encryption_key';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> initialize() async {
    String? storedKey = await _storage.read(key: _keyStorageKey);

    if (storedKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      storedKey = base64Encode(keyBytes);
      await _storage.write(key: _keyStorageKey, value: storedKey);
    }

    _aesKey = encrypt_lib.Key.fromBase64(storedKey);
  }

  Future<void> deleteKey() async {
    await _storage.delete(key: _keyStorageKey);
    _aesKey = null;
  }

  // PBKDF2-like password hashing (multiple rounds SHA-256)
  String hashPassword(String password, String salt) {
    Uint8List result = Uint8List.fromList(utf8.encode(password + salt));
    for (int i = 0; i < 100000; i++) {
      result = Uint8List.fromList(sha256.convert(result).bytes);
    }
    return base64Encode(result);
  }

  String generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  // Encrypt with AES-GCM (authenticated encryption) with random IV
  String encryptData(String plainText) {
    if (_aesKey == null) {
      throw StateError('EncryptionService belum diinisialisasi');
    }
    final random = Random.secure();
    final ivBytes = List<int>.generate(12, (_) => random.nextInt(256));
    final iv = encrypt_lib.IV(Uint8List.fromList(ivBytes));

    final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(_aesKey!, mode: encrypt_lib.AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Prepend IV to ciphertext so we can decrypt later
    final combined = ivBytes + encrypted.bytes;
    return base64Encode(combined);
  }

  // Decrypt by extracting IV from first 12 bytes (GCM standard)
  String decryptData(String encryptedText) {
    if (_aesKey == null) {
      throw StateError('EncryptionService belum diinisialisasi');
    }
    final combined = base64Decode(encryptedText);

    // Support both legacy CBC (16-byte IV) and new GCM (12-byte IV) formats
    // GCM ciphertext includes auth tag, so total is always > 28 bytes for non-empty plaintext
    // Try GCM first (12-byte IV), fall back to CBC (16-byte IV)
    try {
      final ivBytes = combined.sublist(0, 12);
      final cipherBytes = combined.sublist(12);
      final iv = encrypt_lib.IV(Uint8List.fromList(ivBytes));
      final encrypter = encrypt_lib.Encrypter(
          encrypt_lib.AES(_aesKey!, mode: encrypt_lib.AESMode.gcm));
      return encrypter.decrypt(
          encrypt_lib.Encrypted(Uint8List.fromList(cipherBytes)), iv: iv);
    } catch (_) {
      // Fallback: legacy CBC format (16-byte IV)
      final ivBytes = combined.sublist(0, 16);
      final cipherBytes = combined.sublist(16);
      final iv = encrypt_lib.IV(Uint8List.fromList(ivBytes));
      final encrypter = encrypt_lib.Encrypter(
          encrypt_lib.AES(_aesKey!, mode: encrypt_lib.AESMode.cbc));
      return encrypter.decrypt(
          encrypt_lib.Encrypted(Uint8List.fromList(cipherBytes)), iv: iv);
    }
  }

  String encryptAmount(double amount) {
    return encryptData(amount.toString());
  }

  double decryptAmount(String encryptedAmount) {
    return double.parse(decryptData(encryptedAmount));
  }
}
