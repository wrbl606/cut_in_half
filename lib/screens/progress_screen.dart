import 'package:flutter/material.dart';

import '../models/level.dart';
import '../models/player_progress.dart';
import '../services/level_loader.dart';
import '../services/storage_service.dart';
import 'cut_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final StorageService _storage = StorageService();
  List<Level>? _levels;
  PlayerProgress? _progress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final levels = await LevelLoader.loadAll();
    final progress = await _storage.load();
    if (!mounted) return;
    setState(() {
      _levels = levels;
      _progress = progress;
    });
  }

  Future<void> _refreshProgress() async {
    final p = await _storage.load();
    if (!mounted) return;
    setState(() => _progress = p);
  }

  bool _isUnlocked(Level lvl, PlayerProgress p) {
    return p.totalCumulativePoints >= lvl.unlockPoints;
  }

  @override
  Widget build(BuildContext context) {
    final levels = _levels;
    final progress = _progress;
    if (levels == null || progress == null) {
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Levels'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: levels.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (context, i) {
          final lvl = levels[i];
          final unlocked = _isUnlocked(lvl, progress);
          final lp = progress.forLevel(lvl.id);
          return _LevelRow(
            level: lvl,
            unlocked: unlocked,
            bestAccuracy: lp?.bestAccuracy ?? 0,
            bestPoints: lp?.bestPoints ?? 0,
            cumulativePoints: progress.totalCumulativePoints,
            onTap: unlocked
                ? () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CutScreen(level: lvl),
                      ),
                    );
                    _refreshProgress();
                  }
                : null,
          );
        },
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.level,
    required this.unlocked,
    required this.bestAccuracy,
    required this.bestPoints,
    required this.cumulativePoints,
    required this.onTap,
  });

  final Level level;
  final bool unlocked;
  final double bestAccuracy;
  final int bestPoints;
  final int cumulativePoints;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      enabled: onTap != null,
      onTap: onTap,
      title: Row(
        children: [
          Icon(
            unlocked ? Icons.check : Icons.lock_outline,
            size: 16,
            color: unlocked ? const Color(0xFF000000) : const Color(0xFFBBBBBB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              level.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: unlocked ? const Color(0xFF000000) : const Color(0xFF999999),
              ),
            ),
          ),
          Text(
            unlocked
                ? (bestAccuracy > 0
                    ? '${bestAccuracy.toStringAsFixed(1)}%  ·  $bestPoints pts'
                    : '—')
                : '${level.unlockPoints} pts to unlock',
            style: TextStyle(
              fontSize: 13,
              color: unlocked ? const Color(0xFF666666) : const Color(0xFFBBBBBB),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
      subtitle: unlocked
          ? Padding(
              padding: const EdgeInsets.only(top: 4, left: 26),
              child: Text(
                '${level.targetPieces} pieces  ·  ${level.timeLimit}s  ·  '
                'cumulative $cumulativePoints pts',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            )
          : null,
    );
  }
}
