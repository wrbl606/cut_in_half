import 'package:flutter/material.dart';

import '../models/player_progress.dart';
import '../services/storage_service.dart';

/// Settings screen — sound toggle only for v1.
///
/// Reads and writes the persisted [PlayerProgress.soundEnabled] preference so
/// it stays in sync with the toggle on the main menu (single source of truth).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.storage});

  final StorageService? storage;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final StorageService _storage = widget.storage ?? StorageService();
  bool _soundEnabled = true;
  PlayerProgress? _progress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final progress = await _storage.load();
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _soundEnabled = progress.soundEnabled;
    });
  }

  Future<void> _setSoundEnabled(bool value) async {
    final progress = _progress ?? PlayerProgress();
    progress.soundEnabled = value;
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _soundEnabled = value;
    });
    await _storage.save(progress);
  }

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
          onChanged: _setSoundEnabled,
        ),
      ),
    );
  }
}
