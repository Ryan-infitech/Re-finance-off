import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/encryption_service.dart';
import 'services/pin_service.dart';
import 'screens/pin_setup_screen.dart';
import 'screens/pin_entry_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize encryption service
  await EncryptionService.instance.initialize();
  
  // Initialize date formatting
  await initializeDateFormatting('id_ID', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Refinance#',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3));
    
    final isPinSetup = await PinService.instance.isPinSetup();
    
    if (!mounted) return;
    
    if (isPinSetup) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PinEntryScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PinSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/splash.gif',
          width: 300,
        ),
      ),
    );
  }
}
