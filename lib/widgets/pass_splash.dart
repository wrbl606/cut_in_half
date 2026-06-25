import 'package:flutter/material.dart';

/// Full-screen splash shown between multiplayer turns.
///
/// Displays "Pass to [playerName]" and a button to begin that player's turn.
class PassSplash extends StatelessWidget {
  const PassSplash({
    super.key,
    required this.playerName,
    required this.playerIndex,
    required this.totalPlayers,
    required this.onStart,
  });

  final String playerName;
  final int playerIndex;
  final int totalPlayers;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Turn ${playerIndex + 1} of $totalPlayers',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 2,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pass to',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 8),
              Text(
                playerName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000000),
                  foregroundColor: const Color(0xFFFFFFFF),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                ),
                onPressed: onStart,
                child: const Text('Start turn', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
