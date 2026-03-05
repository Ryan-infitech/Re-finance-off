import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static final EncryptionService instance = EncryptionService._init();

  EncryptionService._init();

  encrypt_lib.Key? _aesKey;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedKey = prefs.getString('app_encryption_key');

    if (storedKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      storedKey = base64Encode(keyBytes);
      await prefs.setString('app_encryption_key', storedKey);
    }

    _aesKey = encrypt_lib.Key.fromBase64(storedKey);
  }

  // PBKDF2-like password hashing (multiple rounds SHA-256)
  String hashPassword(String password, String salt) {
    Uint8List result = Uint8List.fromList(utf8.encode(password + salt));
    for (int i = 0; i < 10000; i++) {
      result = Uint8List.fromList(sha256.convert(result).bytes);
    }
    return base64Encode(result);
  }

  String generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  // Encrypt with random IV prepended to ciphertext
  String encryptData(String plainText) {
    if (_aesKey == null) {
      throw StateError('EncryptionService belum diinisialisasi');
    }
    final random = Random.secure();
    final ivBytes = List<int>.generate(16, (_) => random.nextInt(256));
    final iv = encrypt_lib.IV(Uint8List.fromList(ivBytes));

    final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(_aesKey!, mode: encrypt_lib.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Prepend IV to ciphertext so we can decrypt later
    final combined = ivBytes + encrypted.bytes;
    return base64Encode(combined);
  }

  // Decrypt by extracting IV from first 16 bytes
  String decryptData(String encryptedText) {
    if (_aesKey == null) {
      throw StateError('EncryptionService belum diinisialisasi');
    }
    final combined = base64Decode(encryptedText);
    final ivBytes = combined.sublist(0, 16);
    final cipherBytes = combined.sublist(16);

    final iv = encrypt_lib.IV(Uint8List.fromList(ivBytes));
    final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(_aesKey!, mode: encrypt_lib.AESMode.cbc));
    return encrypter.decrypt(encrypt_lib.Encrypted(Uint8List.fromList(cipherBytes)), iv: iv);
  }

  String encryptAmount(double amount) {
    return encryptData(amount.toString());
  }

  double decryptAmount(String encryptedAmount) {
    return double.parse(decryptData(encryptedAmount));
  }
}
