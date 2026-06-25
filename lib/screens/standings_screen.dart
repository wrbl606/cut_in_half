import 'package:flutter/material.dart';

import '../models/level_result.dart';

class PlayerResult {
  PlayerResult({required this.name, required this.result});
  final String name;
  final LevelResult result;
}

/// Final multiplayer standings — ranked by accuracy, ties broken by
/// remaining time at Ready press.
class StandingsScreen extends StatelessWidget {
  const StandingsScreen({super.key, required this.results});

  final List<PlayerResult> results;

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
          children: [
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
                      Text(
                        winner.name,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF000000),
                          height: 0.95,
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
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: ranked.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (context, i) {
                  final r = ranked[i];
                  final isWinner = r.name == winner.name;
                  return _StandingRow(rank: i + 1, result: r, isWinner: isWinner);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
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
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.rank,
    required this.result,
    required this.isWinner,
  });

  final int rank;
  final PlayerResult result;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final pieces = result.result.pieces;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isWinner ? const Color(0xFF000000) : const Color(0xFF999999),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        isWinner ? FontWeight.w800 : FontWeight.w500,
                    color: const Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    for (final p in pieces)
                      Text(
                        '${p.percent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF999999),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${result.result.accuracy.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isWinner ? const Color(0xFF000000) : const Color(0xFF666666),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
