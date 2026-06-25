import 'package:flutter/material.dart';

import '../services/level_loader.dart';
import 'multiplayer_flow.dart';

class MultiSetupScreen extends StatefulWidget {
  const MultiSetupScreen({super.key});

  @override
  State<MultiSetupScreen> createState() => _MultiSetupScreenState();
}

class _MultiSetupScreenState extends State<MultiSetupScreen> {
  int _playerCount = 2;
  late List<TextEditingController> _nameControllers;

  @override
  void initState() {
    super.initState();
    _nameControllers = List.generate(
      12,
      (i) => TextEditingController(text: 'P${i + 1}'),
    );
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Multiplayer'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Players',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black),
                  ),
                  const Spacer(),
                  Text('$_playerCount',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black)),
                ],
              ),
              Slider(
                value: _playerCount.toDouble(),
                min: 2,
                max: 12,
                divisions: 10,
                activeColor: Colors.black,
                inactiveColor: const Color(0xFFDDDDDD),
                onChanged: (v) => setState(() => _playerCount = v.round()),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _playerCount,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: _nameControllers[i],
                      decoration: InputDecoration(
                        labelText: 'Player ${i + 1}',
                        labelStyle: const TextStyle(color: Color(0xFF999999)),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                ),
                onPressed: _start,
                child: const Text('Start', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _start() async {
    final names = <String>[];
    for (var i = 0; i < _playerCount; i++) {
      final t = _nameControllers[i].text.trim();
      names.add(t.isEmpty ? 'P${i + 1}' : t);
    }
    final levels = await LevelLoader.loadAll();
    if (!mounted) return;
    final images = levels.map((l) => l.image).toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiplayerFlow(
          playerNames: names,
          availableImages: images,
        ),
      ),
    );
  }
}
