import 'package:flutter/material.dart';

/// Settings screen — sound toggle only for v1.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: const Text('Sound', style: TextStyle(color: Colors.black)),
        trailing: Switch(
          value: _soundEnabled,
          activeThumbColor: Colors.black,
          onChanged: (v) => setState(() => _soundEnabled = v),
        ),
      ),
    );
  }
}
