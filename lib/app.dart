import 'package:flutter/material.dart';

import 'models/player_progress.dart';
import 'screens/menu_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/storage_service.dart';

class CutInHalfApp extends StatefulWidget {
  const CutInHalfApp({super.key, this.storage});

  final StorageService? storage;

  /// Whether the app should show the first-run onboarding tutorial for the
  /// given progress. Onboarding runs only for truly new players: no recorded
  /// level progress and the onboarding flag not yet set. Existing players
  /// (any recorded level progress) always skip it.
  static bool shouldShowOnboarding(PlayerProgress progress) {
    return !progress.onboardingCompleted && progress.levels.isEmpty;
  }

  @override
  State<CutInHalfApp> createState() => _CutInHalfAppState();
}

class _CutInHalfAppState extends State<CutInHalfApp> {
  late final StorageService _storage = widget.storage ?? StorageService();
  bool _booted = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final progress = await _storage.load();
    if (!mounted) return;
    setState(() {
      _showOnboarding = CutInHalfApp.shouldShowOnboarding(progress);
      _booted = true;
    });
  }

  void _onOnboardingComplete() {
    if (!mounted) return;
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cut In Half',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: _home(),
    );
  }

  Widget _home() {
    if (!_booted) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeCap: StrokeCap.square),
          ),
        ),
      );
    }
    if (_showOnboarding) {
      return OnboardingScreen(
        storage: widget.storage,
        onComplete: _onOnboardingComplete,
      );
    }
    return MenuScreen(storage: widget.storage);
  }

  ThemeData _theme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF000000),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF000000),
        onSecondary: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF000000),
        error: Color(0xFFCC0000),
        onError: Color(0xFFFFFFFF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF000000),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF000000),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEEE),
        space: 1,
        thickness: 1,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF000000)),
        bodyMedium: TextStyle(color: Color(0xFF000000)),
        bodySmall: TextStyle(color: Color(0xFF666666)),
      ),
    );
  }
}
