import 'package:flutter/material.dart';

import 'screens/menu_screen.dart';
import 'services/storage_service.dart';

class CutInHalfApp extends StatelessWidget {
  const CutInHalfApp({super.key, this.storage});

  final StorageService? storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cut In Half',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: MenuScreen(storage: storage),
    );
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
