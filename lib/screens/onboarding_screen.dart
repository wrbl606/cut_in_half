import 'package:flutter/material.dart';

import '../models/attempt.dart';
import '../models/cut_line.dart';
import '../models/level.dart';
import '../services/attempt_store.dart';
import '../services/image_masker.dart';
import '../services/level_loader.dart';
import '../services/splitter.dart';
import '../services/storage_service.dart';
import '../widgets/cut_canvas.dart';
import 'menu_screen.dart';

/// First-run tutorial. Reuses the first single-player level (level_01 /
/// Apple) with the full cutting mechanic active, and — after a short
/// delay — animates a diagonal gesture guide from the bottom-left of the
/// shape to the top-right to teach the core swipe-to-cut action.
///
/// The onboarding ends as soon as the player draws their first cut (which,
/// for Apple, also completes the level's required cut). It then records that
/// cut as the player's first single-player attempt for level_01, shows a
/// short congrats message, persists that onboarding has been seen so it is
/// only shown once, and finally hands off to the menu after the message is
/// dismissed.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.storage,
    this.onComplete,
  });

  final StorageService? storage;

  /// Invoked once the onboarding experience is complete (after the flag has
  /// been persisted, the cut recorded, and the congrats message dismissed).
  /// When null, the screen replaces itself with the [MenuScreen] via
  /// [Navigator.pushReplacement].
  final VoidCallback? onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const String _levelId = 'level_01';

  /// Delay before the diagonal gesture guide sweeps, per the task spec.
  static const Duration _hintDelay = Duration(seconds: 2);

  late final StorageService _storage = widget.storage ?? StorageService();
  Level? _level;
  ImageMask? _mask;
  bool _canvasReady = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _loadLevel();
  }

  Future<void> _loadLevel() async {
    final levels = await LevelLoader.loadAll();
    Level level;
    try {
      level = levels.firstWhere((l) => l.id == _levelId);
    } catch (_) {
      level = levels.isEmpty
          ? Level(
              id: _levelId,
              title: 'Apple',
              image: 'assets/images/apple_1.png',
              timeLimit: 30,
              targetPieces: 2,
              initialCuts: const [],
              unlockPoints: 0,
            )
          : levels.first;
    }
    if (!mounted) return;
    setState(() => _level = level);
  }

  void _onCutsChanged(List<CutLine> cuts) {
    // The onboarding goal is to teach the swipe: as soon as the player
    // commits their first cut, the experience is complete. For Apple
    // (target_pieces = 2) this also satisfies the level's single required
    // cut, covering the "or the level is completed" path.
    if (cuts.isNotEmpty && !_finished) {
      _complete(cuts);
    }
  }

  void _onCanvasReady(ImageMask mask) {
    _mask = mask;
    if (!_canvasReady) setState(() => _canvasReady = true);
  }

  Future<void> _complete(List<CutLine> cuts) async {
    if (_finished) return;
    _finished = true;
    // Persist that onboarding has been seen so it is not shown again.
    final progress = await _storage.load();
    progress.onboardingCompleted = true;
    await _storage.save(progress);
    // Store the apple cut as the player's first single-player attempt for
    // level_01, mirroring the single-player path in cut_screen.dart.
    await _recordAttempt(cuts);
    if (!mounted) return;
    // Let the player know they're ready before handing off to the menu.
    // Navigation happens only after the congrats message is dismissed.
    await _showCongratsDialog();
    if (!mounted) return;
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MenuScreen(storage: widget.storage),
        ),
      );
    }
  }

  Future<void> _recordAttempt(List<CutLine> cuts) async {
    final level = _level;
    if (level == null) return;
    final store = AttemptStore();
    final mask = _mask;
    List<double> percents;
    double accuracy;
    int points;
    bool objectiveMet;
    String? objectiveMessage;
    if (mask != null) {
      final pieces = Splitter.split(mask, cuts);
      final result = Splitter.buildResult(
        levelId: level.id,
        cuts: cuts,
        pieces: pieces,
        remainingSeconds: 0,
        requiredCuts: level.requiredCuts,
        targetPieces: level.targetPieces,
      );
      percents = result.pieces.map((p) => p.percent).toList();
      accuracy = result.accuracy;
      points = result.points;
      objectiveMet = result.objectiveMet;
      objectiveMessage = result.objectiveMessage;
    } else {
      // The image mask may not be ready yet (e.g. while the asset is still
      // decoding). Still record the cut so it appears in the attempt
      // history; percents/accuracy are left empty until the result can be
      // computed.
      percents = const <double>[];
      accuracy = 0.0;
      points = 0;
      objectiveMet = cuts.length == level.requiredCuts;
      objectiveMessage = null;
    }
    await store.record(Attempt.fromResult(
      id: store.newAttemptId('sp'),
      levelId: level.id,
      assetPath: level.image,
      title: level.title,
      targetPieces: level.targetPieces,
      timeLimit: level.timeLimit,
      cuts: cuts,
      percents: percents,
      accuracy: accuracy,
      points: points,
      remainingSeconds: 0,
      mode: AttemptMode.single,
      objectiveMet: objectiveMet,
      objectiveMessage: objectiveMessage,
    ));
  }

  Future<void> _showCongratsDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Nice cut!'),
        content: const Text(
          "You're ready to play! Your first cut has been saved as your "
          'first attempt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    if (level == null) {
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
    return PopScope(
      // Keep the player focused on the tutorial; the only way out is to
      // draw a cut, mirroring the cut screen.
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Learn to Cut'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Swipe across the ${level.title} to cut it in half.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: CutCanvas(
                    assetPath: level.image,
                    initialCuts: level.initialCuts,
                    targetPieces: level.targetPieces,
                    onCutsChanged: _onCutsChanged,
                    onReady: _onCanvasReady,
                    gameplayActive: _canvasReady,
                    hintDelay: _hintDelay,
                    hintDiagonal: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
