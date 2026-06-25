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
/// remaining time at Ready press.
///
/// Two distinct sections:
/// 1. **Leaderboard** — ranked list of players with their accuracy,
///    points, and remaining time.
/// 2. **Attempts** — each player's cut rendered as a miniature in a
///    2-column grid so all players' cuts can be compared side-by-side
///    against the same image.
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
    final winner = ranked.isNotEmpty ? ranked.first : null;
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
            Expanded(
              child: ranked.isEmpty
                  ? const Center(
                      child: Text(
                        'No results',
                        style: TextStyle(color: Color(0xFF999999)),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _Leaderboard(ranked: ranked, winner: winner),
                        const Divider(
                            height: 1, color: Color(0xFF000000)),
                        _AttemptsSection(
                          ranked: ranked,
                          winner: winner,
                          assetPath: assetPath,
                        ),
                      ],
                    ),
            ),
            const Divider(height: 1, color: Color(0xFF000000)),
            _StandingsActions(
              sessionId: sessionId,
              sessionTitle: sessionTitle,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact ranked list of players with their stats.
class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.ranked, required this.winner});

  final List<PlayerResult> ranked;
  final PlayerResult? winner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('Leaderboard'),
        for (int i = 0; i < ranked.length; i++)
          _LeaderboardRow(
            rank: i + 1,
            player: ranked[i],
            isWinner:
                winner != null && ranked[i].name == winner!.name,
          ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.player,
    required this.isWinner,
  });

  final int rank;
  final PlayerResult player;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final result = player.result;
    final accent = isWinner
        ? const Color(0xFF000000)
        : const Color(0xFF999999);
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isWinner
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: const Color(0xFF000000),
                        ),
                      ),
                    ),
                    if (!result.objectiveMet) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'objective failed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFCC0000),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${result.points} pts  ·  '
                  '${result.remainingSeconds}s left  ·  '
                  '${result.pieces.length} pieces',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (isWinner)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.emoji_events_outlined,
                  size: 18, color: Color(0xFF000000)),
            ),
          const SizedBox(width: 8),
          Text(
            '${result.accuracy.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isWinner
                  ? const Color(0xFF000000)
                  : const Color(0xFF666666),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// 2-column grid of miniature cuts, one per player.
class _AttemptsSection extends StatelessWidget {
  const _AttemptsSection({
    required this.ranked,
    required this.winner,
    required this.assetPath,
  });

  final List<PlayerResult> ranked;
  final PlayerResult? winner;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('Attempts'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
            childAspectRatio: 0.72,
          ),
          itemCount: ranked.length,
          itemBuilder: (context, i) {
            final r = ranked[i];
            final isWinner =
                winner != null && r.name == winner!.name;
            final colIndex = i % 2;
            final rowIndex = i ~/ 2;
            final isLastCol = colIndex == 1;
            final rowCount = (ranked.length + 1) ~/ 2;
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
              child: _AttemptTile(
                rank: i + 1,
                player: r,
                assetPath: assetPath,
                isWinner: isWinner,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({
    required this.rank,
    required this.player,
    required this.assetPath,
    required this.isWinner,
  });

  final int rank;
  final PlayerResult player;
  final String assetPath;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final result = player.result;
    final bg = isWinner
        ? const Color(0xFFFFF6E5)
        : const Color(0xFFF6F6F6);
    final accent = isWinner
        ? const Color(0xFF000000)
        : const Color(0xFF999999);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: MiniatureCut(
                    assetPath: assetPath,
                    cuts: result.cuts,
                    backgroundColor: bg,
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    color: isWinner
                        ? const Color(0xFF000000)
                        : const Color(0xCC000000),
                    child: Text(
                      '#$rank',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFFFFF),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                if (!result.objectiveMet)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      color: const Color(0xFFFFEAEA),
                      child: const Text(
                        'objective failed',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFCC0000),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  player.name,
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
                  color: accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${result.points} pts  ·  '
            '${result.pieces.map((p) => '${p.percent.toStringAsFixed(1)}%').join('  ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF999999),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
          color: Color(0xFF999999),
        ),
      ),
    );
  }
}

class _StandingsActions extends StatelessWidget {
  const _StandingsActions({this.sessionId, this.sessionTitle});

  final String? sessionId;
  final String? sessionTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
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
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Done', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}