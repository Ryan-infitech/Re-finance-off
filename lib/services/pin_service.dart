import 'package:shared_preferences/shared_preferences.dart';
import 'encryption_service.dart';

class PinService {
  static final PinService instance = PinService._init();

  PinService._init();

  static const _pinKey = 'app_pin_hash';
  static const _pinSaltKey = 'app_pin_salt';
  static const _securityQuestionKey = 'app_security_question';
  static const _securityAnswerKey = 'app_security_answer_hash';
  static const _securityAnswerSaltKey = 'app_security_answer_salt';
  static const _pinSetupCompleteKey = 'app_pin_setup_complete';
  static const _usernameKey = 'app_username';

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

      await prefs.setString(_pinKey, pinHash);
      await prefs.setString(_pinSaltKey, pinSalt);
      await prefs.setString(_securityQuestionKey, securityQuestion);
      await prefs.setString(_securityAnswerKey, answerHash);
      await prefs.setString(_securityAnswerSaltKey, answerSalt);
      await prefs.setString(_usernameKey, username);
      await prefs.setBool(_pinSetupCompleteKey, true);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enc = EncryptionService.instance;

      final storedHash = prefs.getString(_pinKey);
      final storedSalt = prefs.getString(_pinSaltKey);

      if (storedHash == null || storedSalt == null) return false;

      final inputHash = enc.hashPassword(pin, storedSalt);
      return inputHash == storedHash;
    } catch (e) {
      return false;
    }
  }

  // Get security question
  Future<String?> getSecurityQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_securityQuestionKey);
  }

  // Verify security answer for PIN reset
  Future<bool> verifySecurityAnswer(String answer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enc = EncryptionService.instance;

      final storedHash = prefs.getString(_securityAnswerKey);
      final storedSalt = prefs.getString(_securityAnswerSaltKey);

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
      final prefs = await SharedPreferences.getInstance();
      final enc = EncryptionService.instance;

      final pinSalt = enc.generateSalt();
      final pinHash = enc.hashPassword(newPin, pinSalt);

      await prefs.setString(_pinKey, pinHash);
      await prefs.setString(_pinSaltKey, pinSalt);

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
}
