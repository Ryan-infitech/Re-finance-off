import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pin_service.dart';
import 'home_screen.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;
  int _attempts = 0;
  static const _maxAttempts = 5;

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
      _attempts++;
      _pinController.clear();

      if (_attempts >= _maxAttempts) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terlalu banyak percobaan. Gunakan reset PIN.'),
            backgroundColor: Colors.red,
          ),
        );
        _showResetDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'PIN salah. Sisa percobaan: ${_maxAttempts - _attempts}'),
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
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isResetting = false;

            return AlertDialog(
              title: const Text('Reset PIN'),
              content: SingleChildScrollView(
                child: Column(
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                ElevatedButton(
                  onPressed: isResetting
                      ? null
                      : () async {
                          if (answerController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Jawaban tidak boleh kosong'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
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

                          setDialogState(() => isResetting = true);

                          final answerValid = await PinService.instance
                              .verifySecurityAnswer(answerController.text);

                          if (!answerValid) {
                            setDialogState(() => isResetting = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Jawaban keamanan salah'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final resetSuccess = await PinService.instance
                              .resetPin(newPinController.text);

                          setDialogState(() => isResetting = false);

                          if (!context.mounted) return;

                          if (resetSuccess) {
                            Navigator.pop(context);
                            setState(() => _attempts = 0);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('PIN berhasil direset'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal mereset PIN'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: const Text('Reset PIN'),
                ),
              ],
            );
          },
        );
      },
    );

    answerController.dispose();
    newPinController.dispose();
    confirmPinController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
