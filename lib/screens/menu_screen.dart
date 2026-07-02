import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/animated_text.dart';
import '../models/player_progress.dart';
import 'multi_setup_screen.dart';
import '../services/storage_service.dart';
import 'progress_screen.dart';

/// Cycles the last word of the game title ("CUT IN ____") between the
/// common fractional targets: half, quarters, eighths.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, this.storage});

  final StorageService? storage;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const List<String> _fractions = ['HALF', 'THIRDS', 'QUARTERS'];
  int _fractionIndex = 0;
  Timer? _cycle;
  late final StorageService _storage = widget.storage ?? StorageService();
  bool _soundEnabled = true;
  PlayerProgress? _progress;

  @override
  void initState() {
    super.initState();
    _cycle = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() => _fractionIndex = (_fractionIndex + 1) % _fractions.length);
    });
    _loadSoundPreference();
  }

  @override
  void dispose() {
    _cycle?.cancel();
    super.dispose();
  }

  Future<void> _loadSoundPreference() async {
    final progress = await _storage.load();
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _soundEnabled = progress.soundEnabled;
    });
  }

  Future<void> _toggleSound() async {
    final progress = _progress ?? PlayerProgress();
    progress.soundEnabled = !progress.soundEnabled;
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _soundEnabled = progress.soundEnabled;
    });
    await _storage.save(progress);
  }

  @override
  Widget build(BuildContext context) {
    final fraction = _fractions[_fractionIndex];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  Row(
                    children: [
                      const Text(
                        'CUT ',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: -2,
                          height: 0.9,
                        ),
                      ),
                      
                      const Text(
                        'IN ',
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w200,
                          color: Colors.black,
                          letterSpacing: -2,
                          height: 0.9,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      AnimatedText(
                        value: fraction,
                        duration: const Duration(milliseconds: 450),
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w200,
                          color: Colors.black,
                          letterSpacing: -2,
                          height: 0.9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'A precision party game.\nCut the object into equal pieces.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                  const Spacer(flex: 3),
                  _MenuButton(
                    label: 'Single Player',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProgressScreen(
                          storage: widget.storage,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MenuButton(
                    label: 'Multiplayer',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MultiSetupScreen(),
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: _soundEnabled ? 'Mute sound' : 'Unmute sound',
                icon: Icon(
                  _soundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: Colors.black,
                ),
                onPressed: _toggleSound,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward, color: Colors.black, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}