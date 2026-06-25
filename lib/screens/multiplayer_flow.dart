import 'package:flutter/material.dart';

import '../models/attempt.dart';
import '../models/level.dart';
import '../models/level_result.dart';
import '../services/attempt_store.dart';
import '../services/randomizer.dart';
import '../widgets/pass_splash.dart';
import 'cut_screen.dart';
import 'standings_screen.dart';

/// Drives the multiplayer hot-swap loop:
/// PassSplash → CutScreen → (store) → PassSplash → … → Standings.
class MultiplayerFlow extends StatefulWidget {
  const MultiplayerFlow({
    super.key,
    required this.playerNames,
    required this.availableImages,
  });

  final List<String> playerNames;
  final List<String> availableImages;

  @override
  State<MultiplayerFlow> createState() => _MultiplayerFlowState();
}

class _MultiplayerFlowState extends State<MultiplayerFlow> {
  late final Level _level;
  final List<LevelResult> _results = <LevelResult>[];
  final AttemptStore _attemptStore = AttemptStore();
  late final String _sessionId;
  int _current = 0;
  _Phase _phase = _Phase.pass;

  @override
  void initState() {
    super.initState();
    _level = Randomizer().generate(
      availableImages: widget.playerNames.isEmpty
          ? const <String>[]
          : widget.availableImages,
    );
    _sessionId = _attemptStore.newSessionId();
  }

  void _startTurn() {
    setState(() => _phase = _Phase.play);
  }

  void _onCutComplete(LevelResult result) {
    _results.add(result);
    _attemptStore.record(Attempt.fromResult(
      id: _attemptStore.newAttemptId('mp'),
      levelId: _level.id,
      assetPath: _level.image,
      title: _level.title,
      targetPieces: _level.targetPieces,
      timeLimit: _level.timeLimit,
      cuts: result.cuts,
      percents: result.pieces.map((p) => p.percent).toList(),
      accuracy: result.accuracy,
      points: result.points,
      remainingSeconds: result.remainingSeconds,
      mode: AttemptMode.multi,
      playerName: widget.playerNames[_current],
      sessionId: _sessionId,
      objectiveMet: result.objectiveMet,
      objectiveMessage: result.objectiveMessage,
    ));
    if (_current + 1 >= widget.playerNames.length) {
      setState(() => _phase = _Phase.done);
    } else {
      setState(() {
        _current += 1;
        _phase = _Phase.pass;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.pass:
        return PassSplash(
          playerName: widget.playerNames[_current],
          playerIndex: _current,
          totalPlayers: widget.playerNames.length,
          onStart: _startTurn,
        );
      case _Phase.play:
        return CutScreen(
          level: _level,
          onComplete: _onCutComplete,
        );
      case _Phase.done:
        final ranked = <PlayerResult>[
          for (var i = 0; i < widget.playerNames.length; i++)
            PlayerResult(
              name: widget.playerNames[i],
              result: _results[i],
            ),
        ];
        return StandingsScreen(
          results: ranked,
          assetPath: _level.image,
          sessionId: _sessionId,
          sessionTitle: 'Multiplayer · ${_level.title}',
        );
    }
  }
}

enum _Phase { pass, play, done }
