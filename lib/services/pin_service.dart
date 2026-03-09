import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'encryption_service.dart';

class PinService {
  static final PinService instance = PinService._init();

  PinService._init();

  // Sensitive keys → FlutterSecureStorage
  static const _pinKey = 'app_pin_hash';
  static const _pinSaltKey = 'app_pin_salt';
  static const _securityQuestionKey = 'app_security_question';
  static const _securityAnswerKey = 'app_security_answer_hash';
  static const _securityAnswerSaltKey = 'app_security_answer_salt';

  // Non-sensitive keys → SharedPreferences
  static const _pinSetupCompleteKey = 'app_pin_setup_complete';
  static const _usernameKey = 'app_username';
  static const _fingerprintEnabledKey = 'app_fingerprint_enabled';

  // Rate limiting keys → SharedPreferences (persistent)
  static const _pinAttemptsKey = 'app_pin_attempts';
  static const _pinLockoutUntilKey = 'app_pin_lockout_until';

  static const _maxAttempts = 5;
  static const _lockoutDurationMinutes = 5;

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Check if currently locked out
  Future<bool> isLockedOut() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntilStr = prefs.getString(_pinLockoutUntilKey);
    if (lockoutUntilStr == null) return false;
    final lockoutUntil = DateTime.tryParse(lockoutUntilStr);
    if (lockoutUntil == null) return false;
    if (DateTime.now().isBefore(lockoutUntil)) return true;
    // Lockout expired, reset
    await prefs.remove(_pinLockoutUntilKey);
    await prefs.setInt(_pinAttemptsKey, 0);
    return false;
  }

  // Get remaining lockout duration
  Future<Duration?> getLockoutRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntilStr = prefs.getString(_pinLockoutUntilKey);
    if (lockoutUntilStr == null) return null;
    final lockoutUntil = DateTime.tryParse(lockoutUntilStr);
    if (lockoutUntil == null) return null;
    final remaining = lockoutUntil.difference(DateTime.now());
    if (remaining.isNegative) return null;
    return remaining;
  }

  // Get remaining attempts
  Future<int> getRemainingAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt(_pinAttemptsKey) ?? 0;
    return _maxAttempts - attempts;
  }

  // Record a failed attempt, returns true if now locked out
  Future<bool> _recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = (prefs.getInt(_pinAttemptsKey) ?? 0) + 1;
    await prefs.setInt(_pinAttemptsKey, attempts);

    if (attempts >= _maxAttempts) {
      final lockoutUntil = DateTime.now().add(
        const Duration(minutes: _lockoutDurationMinutes),
      );
      await prefs.setString(_pinLockoutUntilKey, lockoutUntil.toIso8601String());
      return true;
    }
    return false;
  }

  // Reset attempt counter on success
  Future<void> _resetAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pinAttemptsKey, 0);
    await prefs.remove(_pinLockoutUntilKey);
  }

  // Check if PIN has been set up
  Future<bool> isPinSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinSetupCompleteKey) ?? false;
  }

  // Set up PIN for the first time
  Future<bool> setupPin({
    required String pin,
    required String username,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enc = EncryptionService.instance;

      // Hash PIN
      final pinSalt = enc.generateSalt();
      final pinHash = enc.hashPassword(pin, pinSalt);

      // Hash security answer (case-insensitive)
      final answerSalt = enc.generateSalt();
      final answerHash =
          enc.hashPassword(securityAnswer.toLowerCase().trim(), answerSalt);

      // Store sensitive data in secure storage
      await _secureStorage.write(key: _pinKey, value: pinHash);
      await _secureStorage.write(key: _pinSaltKey, value: pinSalt);
      await _secureStorage.write(key: _securityQuestionKey, value: securityQuestion);
      await _secureStorage.write(key: _securityAnswerKey, value: answerHash);
      await _secureStorage.write(key: _securityAnswerSaltKey, value: answerSalt);

      // Store non-sensitive data in SharedPreferences
      await prefs.setString(_usernameKey, username);
      await prefs.setBool(_pinSetupCompleteKey, true);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Verify PIN with persistent rate limiting
  Future<bool> verifyPin(String pin) async {
    try {
      // Check lockout first
      if (await isLockedOut()) return false;

      final enc = EncryptionService.instance;

      final storedHash = await _secureStorage.read(key: _pinKey);
      final storedSalt = await _secureStorage.read(key: _pinSaltKey);

      if (storedHash == null || storedSalt == null) return false;

      final inputHash = enc.hashPassword(pin, storedSalt);
      final isValid = inputHash == storedHash;

      if (isValid) {
        await _resetAttempts();
      } else {
        await _recordFailedAttempt();
      }

      return isValid;
    } catch (e) {
      return false;
    }
  }

  // Get security question
  Future<String?> getSecurityQuestion() async {
    return await _secureStorage.read(key: _securityQuestionKey);
  }

  // Verify security answer for PIN reset
  Future<bool> verifySecurityAnswer(String answer) async {
    try {
      final enc = EncryptionService.instance;

      final storedHash = await _secureStorage.read(key: _securityAnswerKey);
      final storedSalt = await _secureStorage.read(key: _securityAnswerSaltKey);

      if (storedHash == null || storedSalt == null) return false;

      final inputHash =
          enc.hashPassword(answer.toLowerCase().trim(), storedSalt);
      return inputHash == storedHash;
    } catch (e) {
      return false;
    }
  }

  // Reset PIN (after security answer verified)
  Future<bool> resetPin(String newPin) async {
    try {
      final enc = EncryptionService.instance;

      final pinSalt = enc.generateSalt();
      final pinHash = enc.hashPassword(newPin, pinSalt);

      await _secureStorage.write(key: _pinKey, value: pinHash);
      await _secureStorage.write(key: _pinSaltKey, value: pinSalt);

      // Reset rate limiting on successful PIN reset
      await _resetAttempts();

      return true;
    } catch (e) {
      return false;
    }
  }

  // Change PIN (requires old PIN verification)
  Future<bool> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    final isValid = await verifyPin(oldPin);
    if (!isValid) return false;
    return await resetPin(newPin);
  }

  // Get username
  Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey) ?? 'User';
  }

  // Update username
  Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  // Check if device supports biometrics
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      return false;
    }
  }

  // Check if fingerprint is enabled by user
  Future<bool> isFingerprintEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fingerprintEnabledKey) ?? false;
  }

  // Enable/disable fingerprint
  Future<void> setFingerprintEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fingerprintEnabledKey, enabled);
  }

  // Full reset - clear all PIN and security data
  Future<void> resetFullSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear secure storage
      await _secureStorage.delete(key: _pinKey);
      await _secureStorage.delete(key: _pinSaltKey);
      await _secureStorage.delete(key: _securityQuestionKey);
      await _secureStorage.delete(key: _securityAnswerKey);
      await _secureStorage.delete(key: _securityAnswerSaltKey);
      // Clear shared preferences
      await prefs.remove(_pinSetupCompleteKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_fingerprintEnabledKey);
      await _resetAttempts();
    } catch (_) {}
  }

  // Authenticate with fingerprint
  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Gunakan sidik jari untuk masuk',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
