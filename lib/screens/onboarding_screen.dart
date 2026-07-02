import 'package:flutter/material.dart';

import '../models/cut_line.dart';
import '../models/level.dart';
import '../services/image_masker.dart';
import '../services/level_loader.dart';
import '../services/storage_service.dart';
import '../widgets/cut_canvas.dart';
import 'menu_screen.dart';

/// First-run tutorial. Reuses the first single-player level (level_01 /
/// Sparrow) with the full cutting mechanic active, and — after a short
/// delay — animates a diagonal gesture guide from the bottom-left of the
/// shape to the top-right to teach the core swipe-to-cut action.
///
/// The onboarding ends as soon as the player draws their first cut (which,
/// for Sparrow, also completes the level's required cut). It persists that
/// it has been seen so it is only shown once, then hands off to the menu.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.storage,
    this.onComplete,
  });

  final StorageService? storage;

  /// Invoked once the onboarding experience is complete (after the flag has
  /// been persisted). When null, the screen replaces itself with the
  /// [MenuScreen] via [Navigator.pushReplacement].
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
              title: 'Sparrow',
              image: 'assets/images/1047665181.png',
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
    // commits their first cut, the experience is complete. For Sparrow
    // (target_pieces = 2) this also satisfies the level's single required
    // cut, covering the "or the level is completed" path.
    if (cuts.isNotEmpty && !_finished) {
      _complete();
    }
  }

  void _onCanvasReady(ImageMask _) {
    if (!_canvasReady) setState(() => _canvasReady = true);
  }

  Future<void> _complete() async {
    if (_finished) return;
    _finished = true;
    // Persist that onboarding has been seen so it is not shown again.
    final progress = await _storage.load();
    progress.onboardingCompleted = true;
    await _storage.save(progress);
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
