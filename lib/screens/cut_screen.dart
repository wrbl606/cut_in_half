import 'dart:async';

import 'package:flutter/material.dart';

import '../models/attempt.dart';
import '../models/cut_line.dart';
import '../models/level.dart';
import '../models/level_result.dart';
import '../services/attempt_store.dart';
import '../services/image_masker.dart';
import '../services/splitter.dart';
import '../services/storage_service.dart';
import '../widgets/animated_text.dart';
import '../widgets/cut_canvas.dart';
import 'result_screen.dart';

/// Shared gameplay screen: timer HUD + cut canvas + Ready button.
///
/// In single-player mode ([onComplete] is null), finishing pushes the
/// [ResultScreen] as a replacement. In multiplayer mode, [onComplete] is
/// invoked with the result and the caller handles navigation.
class CutScreen extends StatefulWidget {
  const CutScreen({
    super.key,
    required this.level,
    this.onComplete,
  });

  final Level level;
  final ValueChanged<LevelResult>? onComplete;

  @override
  State<CutScreen> createState() => _CutScreenState();
}

class _CutScreenState extends State<CutScreen>
    with TickerProviderStateMixin {
  ImageMask? _mask;
  List<CutLine> _cuts = const <CutLine>[];
  bool _canvasReady = false;
  bool _finished = false;
  bool _drawing = false;

  late final AnimationController _pulse;
  Timer? _timer;
  Timer? _countdownTimer;
  int _remaining = 0;
  int _countdown = 3;
  bool _countdownActive = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.level.timeLimit;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  int get _requiredCuts => widget.level.targetPieces - 1;
  bool get _ready => _cuts.length == _requiredCuts;

  void _onCutsChanged(List<CutLine> cuts) {
    setState(() => _cuts = cuts);
  }

  void _onDragChanged(bool active) {
    if (_drawing != active) setState(() => _drawing = active);
  }

  void _onCanvasReady(ImageMask mask) {
    setState(() {
      _mask = mask;
      _canvasReady = true;
    });
    if (_isMultiplayer) {
      setState(() {
        _countdownActive = true;
        _countdown = 3;
      });
      _startCountdown();
    } else {
      _startTimer();
    }
  }

  bool get _isMultiplayer => widget.onComplete != null;

  /// Plays a 3-second fullscreen countdown, then hands control to the
  /// player by starting the actual cut timer.
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _countdown = _countdown - 1);
      if (_countdown <= 0) {
        _countdownTimer?.cancel();
        setState(() => _countdownActive = false);
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _remaining - 1);
      if (_remaining <= 5 && _remaining > 0) {
        _pulse.repeat(reverse: true);
      } else {
        _pulse.stop();
      }
      if (_remaining <= 0) {
        _timer?.cancel();
        _finish();
      }
    });
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    _pulse.stop();
    final mask = _mask;
    if (mask == null) return;
    final pieces = Splitter.split(mask, _cuts);
    final result = Splitter.buildResult(
      levelId: widget.level.id,
      cuts: _cuts,
      pieces: pieces,
      remainingSeconds:
                _isMultiplayer ? (_remaining < 0 ? 0 : _remaining) : 0,
      requiredCuts: widget.level.requiredCuts,
      targetPieces: widget.level.targetPieces,
    );
    if (!mounted) return;
    if (widget.onComplete != null) {
      widget.onComplete!(result);
    } else {
      // Single-player: persist best-score progress and record the attempt,
      // then show ResultScreen.
      final storage = StorageService();
      final progress = await storage.load();
      progress.recordResult(widget.level.id, result.points, result.accuracy);
      await storage.save(progress);
      final attempts = AttemptStore();
      await attempts.record(Attempt.fromResult(
        id: attempts.newAttemptId('sp'),
        levelId: widget.level.id,
        assetPath: widget.level.image,
        title: widget.level.title,
        targetPieces: widget.level.targetPieces,
        timeLimit: widget.level.timeLimit,
        cuts: result.cuts,
        percents: result.pieces.map((p) => p.percent).toList(),
        accuracy: result.accuracy,
        points: result.points,
        remainingSeconds: result.remainingSeconds,
        mode: AttemptMode.single,
        objectiveMet: result.objectiveMet,
        objectiveMessage: result.objectiveMessage,
      ));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            assetPath: widget.level.image,
            result: result,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Disable back navigation entirely on the cut screen so the player
      // can focus on gameplay. The only way out is completing the level.
      canPop: false,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(widget.level.title),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              centerTitle: false,
              actions: [
                if (_canvasReady && !_countdownActive && _isMultiplayer)
                  _buildTimer(),
                const SizedBox(width: 16),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  if (_canvasReady && !_countdownActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Make $_requiredCuts cut${_requiredCuts == 1 ? "" : "s"} '
                            'to produce ${widget.level.targetPieces} '
                            'piece${widget.level.targetPieces == 1 ? "" : "s"}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: CutCanvas(
                        assetPath: widget.level.image,
                        initialCuts: widget.level.initialCuts,
                        targetPieces: widget.level.targetPieces,
                        onCutsChanged: _onCutsChanged,
                        onReady: _onCanvasReady,
                        onDragChanged: _onDragChanged,
                        gameplayActive:
                            _canvasReady && !_countdownActive,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${_cuts.length}/$_requiredCuts cuts',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _ready ? Colors.black : const Color(0xFFEEEEEE),
                          foregroundColor:
                              _ready ? Colors.white : const Color(0xFF999999),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 36, vertical: 14),
                          shape: const RoundedRectangleBorder(),
                          elevation: 0,
                        ),
                        onPressed:
                            _ready && !_countdownActive ? _finish : null,
                        child: const Text('Ready', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
          if (_countdownActive) _buildCountdownOverlay(),
        ],
      ),
    );
  }

  /// A fullscreen overlay covering the entire screen including the app bar.
  Widget _buildCountdownOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismissCountdown,
        child: Material(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: AnimatedText(
              value: '$_countdown',
              duration: const Duration(milliseconds: 900),
              slideDistance: 24,
              blurSigma: 3,
              jitter: 6,
              style: TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _dismissCountdown() {
    _countdownTimer?.cancel();
    if (!_countdownActive) return;
    setState(() => _countdownActive = false);
    _startTimer();
  }

  Widget _buildTimer() {
    final isLow = _remaining <= 5 && _remaining > 0;
    if (!isLow) {
      return Text(
        '${_remaining}s',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF000000),
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );
    }
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final on = _pulse.value > 0.5;
        return Text(
          '${_remaining}s',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: on ? const Color(0xFFCC0000) : const Color(0xFF000000),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}
