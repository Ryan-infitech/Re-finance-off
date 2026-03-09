import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/encryption_service.dart';
import '../services/database_helper.dart';
import '../services/image_service.dart';
import '../services/pin_service.dart';
import 'home_screen.dart';
import 'pin_setup_screen.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;
  bool _fingerprintAvailable = false;
  bool _isLockedOut = false;
  String _lockoutMessage = '';

  @override
  void initState() {
    super.initState();
    _checkLockout();
    _checkFingerprint();
  }

  Future<void> _checkLockout() async {
    final lockedOut = await PinService.instance.isLockedOut();
    if (lockedOut) {
      final remaining = await PinService.instance.getLockoutRemaining();
      if (remaining != null && mounted) {
        setState(() {
          _isLockedOut = true;
          _lockoutMessage =
              'Terlalu banyak percobaan. Coba lagi dalam ${remaining.inMinutes + 1} menit.';
        });
      }
    } else {
      if (mounted) setState(() => _isLockedOut = false);
    }
  }

  Future<void> _checkFingerprint() async {
    final isEnabled = await PinService.instance.isFingerprintEnabled();
    final isAvailable = await PinService.instance.isBiometricAvailable();
    setState(() {
      _fingerprintAvailable = isEnabled && isAvailable;
    });
    if (_fingerprintAvailable) {
      _authenticateWithFingerprint();
    }
  }

  Future<void> _authenticateWithFingerprint() async {
    final success = await PinService.instance.authenticateWithBiometric();
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text;
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN minimal 4 digit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check lockout before attempting
    await _checkLockout();
    if (_isLockedOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lockoutMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final isValid = await PinService.instance.verifyPin(pin);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (isValid) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      _pinController.clear();

      // Check if now locked out
      final lockedOut = await PinService.instance.isLockedOut();
      if (lockedOut) {
        await _checkLockout();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_lockoutMessage),
            backgroundColor: Colors.red,
          ),
        );
        _showResetDialog();
      } else {
        final remaining = await PinService.instance.getRemainingAttempts();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PIN salah. Sisa percobaan: $remaining'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showResetDialog() async {
    final question = await PinService.instance.getSecurityQuestion();
    if (question == null || !mounted) return;

    final answerController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // 0 = verify answer, 1 = enter new PIN
        int step = 0;
        bool isProcessing = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(step == 0 ? 'Verifikasi Keamanan' : 'PIN Baru'),
              content: SingleChildScrollView(
                child: step == 0
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            question,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: answerController,
                            decoration: const InputDecoration(
                              labelText: 'Jawaban',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.question_answer),
                            ),
                          ),
                          if (errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Jawaban benar! Silakan buat PIN baru.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: newPinController,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              labelText: 'PIN Baru (4-6 digit)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: confirmPinController,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Konfirmasi PIN Baru',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                        ],
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                if (step == 0) ...[
                  TextButton(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Reset dari Awal'),
                                content: const Text(
                                  'Jika Anda lupa jawaban pertanyaan keamanan, '
                                  'satu-satunya cara adalah reset dari awal. '
                                  'Semua data (transaksi, PIN, pengaturan) akan DIHAPUS PERMANEN.\n\n'
                                  'Lanjutkan?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Hapus Semua Data'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true && context.mounted) {
                              await ImageService.instance.deleteAllImages();
                              await DatabaseHelper.instance.deleteAllTransactions();
                              await EncryptionService.instance.deleteKey();
                              await PinService.instance.resetFullSetup();
                              // Re-initialize encryption with new key
                              await EncryptionService.instance.initialize();
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                this.context,
                                MaterialPageRoute(
                                  builder: (_) => const PinSetupScreen(),
                                ),
                              );
                            }
                          },
                    child: const Text(
                      'Reset dari Awal',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            if (answerController.text.trim().isEmpty) {
                              setDialogState(() {
                                errorMessage = 'Jawaban tidak boleh kosong';
                              });
                              return;
                            }

                            setDialogState(() {
                              isProcessing = true;
                              errorMessage = null;
                            });

                            final answerValid = await PinService.instance
                                .verifySecurityAnswer(answerController.text);

                            if (!context.mounted) return;

                            if (answerValid) {
                              setDialogState(() {
                                step = 1;
                                isProcessing = false;
                              });
                            } else {
                              setDialogState(() {
                                isProcessing = false;
                                errorMessage =
                                    'Jawaban salah. Silakan coba lagi.';
                                answerController.clear();
                              });
                            }
                          },
                    child: isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verifikasi'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            if (newPinController.text.length < 4) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN minimal 4 digit'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            if (newPinController.text !=
                                confirmPinController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN tidak cocok'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            setDialogState(() => isProcessing = true);

                            final resetSuccess = await PinService.instance
                                .resetPin(newPinController.text);

                            setDialogState(() => isProcessing = false);

                            if (!context.mounted) return;

                            if (resetSuccess) {
                              Navigator.pop(context);
                              setState(() => _isLockedOut = false);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN berhasil direset'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gagal mereset PIN'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Reset PIN'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Image.asset(
                  'assets/images/refinance.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.account_balance_wallet,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    );
                  },
                ),
                const SizedBox(height: 16),

                Text(
                  'Masukkan PIN untuk melanjutkan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // PIN field
                TextFormField(
                  controller: _pinController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePin
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscurePin = !_obscurePin),
                    ),
                  ),
                  onFieldSubmitted: (_) => _verifyPin(),
                ),
                const SizedBox(height: 24),

                // Verify button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Masuk', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),

                // Forgot PIN
                TextButton(
                  onPressed: _showResetDialog,
                  child: const Text('Lupa PIN?'),
                ),

                // Fingerprint button
                if (_fingerprintAvailable) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        IconButton.filled(
                          onPressed: _authenticateWithFingerprint,
                          icon: const Icon(Icons.fingerprint, size: 40),
                          iconSize: 40,
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gunakan Sidik Jari',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
