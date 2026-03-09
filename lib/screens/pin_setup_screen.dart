import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pin_service.dart';
import 'home_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  String? _selectedQuestion;
  bool _isLoading = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _enableFingerprint = false;
  bool _isBiometricAvailable = false;

  final List<String> _securityQuestions = [
    'Siapa nama hewan peliharaan pertama Anda?',
    'Di kota mana Anda lahir?',
    'Siapa nama guru favorit Anda?',
    'Apa makanan favorit Anda?',
    'Siapa nama sahabat kecil Anda?',
    'Apa nama sekolah dasar Anda?',
  ];

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await PinService.instance.isBiometricAvailable();
    setState(() {
      _isBiometricAvailable = available;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  Future<void> _setupPin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedQuestion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih pertanyaan keamanan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await PinService.instance.setupPin(
      pin: _pinController.text,
      username: _usernameController.text.trim(),
      securityQuestion: _selectedQuestion!,
      securityAnswer: _securityAnswerController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      await PinService.instance.setFingerprintEnabled(_enableFingerprint);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan PIN'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),

                  // Logo
                  Image.asset(
                    'assets/images/refinance.png',
                  width: 100,
                  height: 100,
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
                  'Selamat Datang!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Buat PIN untuk mengamankan data keuangan Anda',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Anda',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    if (value.trim().length < 2) {
                      return 'Nama minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // PIN
                TextFormField(
                  controller: _pinController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'PIN (4-6 digit)',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePin ? Icons.visibility : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscurePin = !_obscurePin),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'PIN tidak boleh kosong';
                    }
                    if (value.length < 4) {
                      return 'PIN minimal 4 digit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm PIN
                TextFormField(
                  controller: _confirmPinController,
                  obscureText: _obscureConfirmPin,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi PIN',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPin
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(
                          () => _obscureConfirmPin = !_obscureConfirmPin),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi PIN tidak boleh kosong';
                    }
                    if (value != _pinController.text) {
                      return 'PIN tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Security question dropdown
                DropdownButtonFormField<String>(
                  value: _selectedQuestion,
                  decoration: const InputDecoration(
                    labelText: 'Pertanyaan Keamanan',
                    prefixIcon: Icon(Icons.security),
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: _securityQuestions.map((q) {
                    return DropdownMenuItem(value: q, child: Text(q));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedQuestion = value);
                  },
                ),
                const SizedBox(height: 16),

                // Security answer
                TextFormField(
                  controller: _securityAnswerController,
                  decoration: const InputDecoration(
                    labelText: 'Jawaban Keamanan',
                    prefixIcon: Icon(Icons.question_answer),
                    border: OutlineInputBorder(),
                    helperText: 'Digunakan untuk reset PIN jika lupa',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Jawaban tidak boleh kosong';
                    }
                    if (value.trim().length < 2) {
                      return 'Jawaban minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Fingerprint option
                if (_isBiometricAvailable)
                  Card(
                    child: SwitchListTile(
                      title: const Text('Gunakan Sidik Jari'),
                      subtitle: const Text('Login dengan sidik jari'),
                      secondary: const Icon(Icons.fingerprint),
                      value: _enableFingerprint,
                      onChanged: (value) {
                        setState(() => _enableFingerprint = value);
                      },
                    ),
                  ),
                if (_isBiometricAvailable) const SizedBox(height: 16),

                // Setup button
                ElevatedButton(
                  onPressed: _isLoading ? null : _setupPin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Mulai', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
