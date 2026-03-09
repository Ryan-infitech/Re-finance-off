import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/encryption_service.dart';
import 'services/image_service.dart';
import 'services/pin_service.dart';
import 'services/theme_service.dart';
import 'screens/pin_setup_screen.dart';
import 'screens/pin_entry_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize encryption service
  await EncryptionService.instance.initialize();
  
  // Initialize theme service
  await ThemeService.instance.initialize();
  
  // Initialize date formatting
  await initializeDateFormatting('id_ID', null);
  
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Refinance#',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          themeMode: ThemeService.instance.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              surfaceTintColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              surfaceTintColor: Color(0xFF1E1E1E),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E1E1E),
              surfaceTintColor: const Color(0xFF1E1E1E),
            ),
          ),
          home: const InactivityWrapper(child: SplashScreen()),
        );
      },
    );
  }
}

/// Wraps the app to detect user inactivity and auto-lock after timeout
class InactivityWrapper extends StatefulWidget {
  final Widget child;
  const InactivityWrapper({super.key, required this.child});

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> with WidgetsBindingObserver {
  Timer? _inactivityTimer;
  static const _timeoutMinutes = 5;
  bool _isOnAuthScreen = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // App went to background — lock immediately
      _lockApp();
    } else if (state == AppLifecycleState.resumed) {
      _resetTimer();
    }
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _isOnAuthScreen = false;
    _inactivityTimer = Timer(
      const Duration(minutes: _timeoutMinutes),
      _lockApp,
    );
  }

  void _lockApp() {
    _inactivityTimer?.cancel();
    if (_isOnAuthScreen) return;
    _isOnAuthScreen = true;
    // Cleanup decrypted temp images from memory/disk
    ImageService.instance.cleanupTempImages();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PinEntryScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _resetTimer,
      onPanDown: (_) => _resetTimer(),
      child: widget.child,
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
      body: Center(
        child: Image.asset(
          'assets/images/splash.gif',
          width: 300,
        ),
      ),
    );
  }
}
