import 'package:flutter/material.dart';

import '../models/level_result.dart';
import '../widgets/miniature_cut.dart';
import 'attempts_screen.dart';

class PlayerResult {
  PlayerResult({required this.name, required this.result});
  final String name;
  final LevelResult result;
}

/// Final multiplayer standings — ranked by accuracy, ties broken by
/// remaining time at Ready press. Each player's cut is rendered as a
/// miniature in a grid so all players' cuts can be compared side-by-side
/// against the same image.
class StandingsScreen extends StatelessWidget {
  const StandingsScreen({
    super.key,
    required this.results,
    required this.assetPath,
    this.sessionId,
    this.sessionTitle,
  });

  final List<PlayerResult> results;

  /// Asset rendered in every player's miniature (all players cut the
  /// same image in a match).
  final String assetPath;

  /// Multiplayer session id used to filter the per-session attempt view.
  final String? sessionId;
  final String? sessionTitle;

  List<PlayerResult> get _ranked {
    final list = List<PlayerResult>.of(results);
    list.sort((a, b) {
      final r = b.result.accuracy.compareTo(a.result.accuracy);
      if (r != 0) return r;
      return b.result.remainingSeconds.compareTo(a.result.remainingSeconds);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final ranked = _ranked;
    final winner = ranked.first;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Standings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Winner header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WINNER',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          winner.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF000000),
                            height: 0.95,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${winner.result.accuracy.toStringAsFixed(1)}%  ·  '
                          '${winner.result.points} pts',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF666666),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF000000)),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1000 ? 3 : 2;
                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 0,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: ranked.length,
                    itemBuilder: (context, i) {
                      final r = ranked[i];
                      final isWinner = r.name == winner.name;
                      final colIndex = i % crossAxisCount;
                      final rowIndex = i ~/ crossAxisCount;
                      final isLastCol = colIndex == crossAxisCount - 1;
                      final rowCount = (ranked.length + crossAxisCount - 1) ~/
                          crossAxisCount;
                      final isLastRow = rowIndex == rowCount - 1;
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: isLastCol
                                ? BorderSide.none
                                : const BorderSide(
                                    color: Color(0xFFEEEEEE), width: 1),
                            bottom: isLastRow
                                ? BorderSide.none
                                : const BorderSide(
                                    color: Color(0xFFEEEEEE), width: 1),
                          ),
                        ),
                        child: _StandingTile(
                          rank: i + 1,
                          name: r.name,
                          result: r.result,
                          assetPath: assetPath,
                          isWinner: isWinner,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Color(0xFF000000)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sessionId != null)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: const RoundedRectangleBorder(),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AttemptsScreen(
                              sessionId: sessionId,
                              title: sessionTitle,
                            ),
                          ),
                        ),
                        child: const Text('Attempts',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  if (sessionId != null) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: const RoundedRectangleBorder(),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                      child: const Text('Done', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandingTile extends StatelessWidget {
  const _StandingTile({
    required this.rank,
    required this.name,
    required this.result,
    required this.assetPath,
    required this.isWinner,
  });

  final int rank;
  final String name;
  final LevelResult result;
  final String assetPath;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MiniatureCut(
              assetPath: assetPath,
              cuts: result.cuts,
              backgroundColor:
                  isWinner ? const Color(0xFFFFF6E5) : const Color(0xFFF6F6F6),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isWinner
                      ? const Color(0xFF000000)
                      : const Color(0xFF999999),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isWinner ? FontWeight.w800 : FontWeight.w600,
                    color: const Color(0xFF000000),
                  ),
                ),
              ),
              Text(
                '${result.accuracy.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isWinner
                      ? const Color(0xFF000000)
                      : const Color(0xFF666666),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: [
              for (final p in result.pieces)
                Text(
                  '${p.percent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF999999),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}