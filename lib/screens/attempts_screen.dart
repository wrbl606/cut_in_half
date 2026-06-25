import 'package:flutter/material.dart';

import '../models/attempt.dart';
import '../services/attempt_store.dart';
import '../widgets/miniature_cut.dart';

/// Browse and compare every stored attempt — single-player and
/// multiplayer — as miniature cut previews. Multiplayer attempts are
/// grouped by session so each match's players can be compared head-to-head.
class AttemptsScreen extends StatefulWidget {
  const AttemptsScreen({super.key});

  @override
  State<AttemptsScreen> createState() => _AttemptsScreenState();
}

class _AttemptsScreenState extends State<AttemptsScreen> {
  final AttemptStore _store = AttemptStore();
  List<Attempt>? _attempts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await _store.loadAll();
    if (!mounted) return;
    setState(() => _attempts = a);
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear attempt history?'),
        content: const Text(
          'This permanently removes all stored single and multiplayer '
          'attempts. Best-score progression is unaffected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear',
                style: TextStyle(color: Color(0xFFCC0000))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _store.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final attempts = _attempts;
    if (attempts == null) {
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
        title: const Text('Attempts'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (attempts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: _clear,
              tooltip: 'Clear history',
            ),
        ],
      ),
      body: SafeArea(
        child: attempts.isEmpty
            ? const _EmptyState()
            : _GroupedAttempts(attempts: attempts),
      ),
    );
  }
}

enum _Grouping { all, multi, single }

class _GroupedAttempts extends StatefulWidget {
  const _GroupedAttempts({required this.attempts});
  final List<Attempt> attempts;

  @override
  State<_GroupedAttempts> createState() => _GroupedAttemptsState();
}

class _GroupedAttemptsState extends State<_GroupedAttempts> {
  _Grouping _grouping = _Grouping.all;

  List<_AttemptGroup> _buildAll(List<Attempt> all) {
    // Group multiplayer by session; each single attempt is its own group.
    final bySession = <String, _AttemptGroup>{};
    for (final a in all) {
      final key = a.sessionId ?? 'solo_${a.id}';
      (bySession[key] ??= _AttemptGroup(
              key: key,
              mode: a.mode,
              title: a.mode == AttemptMode.multi
                  ? 'Multiplayer · ${a.title}'
                  : a.title,
              assetPath: a.assetPath,
              sessionId: a.sessionId))
          .attempts
          .add(a);
    }
    return bySession.values.toList()
      ..sort((g1, g2) {
        final a = g1.attempts.first.timestampMs;
        final b = g2.attempts.first.timestampMs;
        return b.compareTo(a);
      });
  }

  List<_AttemptGroup> _groups(List<Attempt> all) {
    final base = _buildAll(all);
    switch (_grouping) {
      case _Grouping.multi:
        return base.where((g) => g.mode == AttemptMode.multi).toList();
      case _Grouping.single:
        return base.where((g) => g.mode == AttemptMode.single).toList();
      case _Grouping.all:
        return base;
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.attempts;
    final groups = _groups(all);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: _grouping == _Grouping.all,
                onTap: () => setState(() => _grouping = _Grouping.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Single',
                selected: _grouping == _Grouping.single,
                onTap: () => setState(() => _grouping = _Grouping.single),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Multiplayer',
                selected: _grouping == _Grouping.multi,
                onTap: () => setState(() => _grouping = _Grouping.multi),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        Expanded(
          child: groups.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 32),
                  itemCount: groups.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  itemBuilder: (context, i) {
                    final g = groups[i];
                    return _GroupCard(group: g);
                  },
                ),
        ),
      ],
    );
  }
}

class _AttemptGroup {
  _AttemptGroup({
    required this.key,
    required this.mode,
    required this.title,
    required this.assetPath,
    this.sessionId,
  });

  final String key;
  final AttemptMode mode;
  final String title;
  final String assetPath;
  final String? sessionId;
  final List<Attempt> attempts = <Attempt>[];
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});
  final _AttemptGroup group;

  @override
  Widget build(BuildContext context) {
    final list = List<Attempt>.of(group.attempts)
      ..sort((a, b) {
        // Multiplayer: keep play order (oldest first) for side-by-side;
        // single: best first.
        if (group.mode == AttemptMode.multi) {
          return a.timestampMs.compareTo(b.timestampMs);
        }
        return b.accuracy.compareTo(a.accuracy);
      });
    final reference = list.first;
    final time = reference.timestamp;
    final timeLabel =
        '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$timeLabel  ·  ${reference.targetPieces} pieces  ·  '
                      '${list.length} attempt${list.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ComparisonGrid(group: group, ordered: list),
        ],
      ),
    );
  }
}

class _ComparisonGrid extends StatelessWidget {
  const _ComparisonGrid({required this.group, required this.ordered});
  final _AttemptGroup group;
  final List<Attempt> ordered;

  @override
  Widget build(BuildContext context) {
    const tileH = 132.0;
    return SizedBox(
      height: tileH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ordered.length,
        separatorBuilder: (_, _) => const SizedBox(width: 1),
        itemBuilder: (context, i) {
          final a = ordered[i];
          const width = 128.0;
          final isLast = i == ordered.length - 1;
          return Container(
            width: width,
            decoration: isLast
                ? null
                : const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                    ),
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 96,
                  child: MiniatureCut(
                    assetPath: a.assetPath,
                    cuts: a.cuts,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (a.mode == AttemptMode.multi &&
                          a.playerName != null)
                        Text(
                          a.playerName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000000),
                          ),
                        ),
                      Row(
                        children: [
                          Text(
                            '${a.accuracy.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  a.objectiveMet ? FontWeight.w700 : FontWeight.w500,
                              color: a.objectiveMet
                                  ? const Color(0xFF000000)
                                  : const Color(0xFFCC0000),
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${a.points}p',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF999999),
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          for (final p in a.percents)
                            Text(
                              p.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFBBBBBB),
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF000000) : const Color(0xFFF0F0F0),
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFFFFFFFF) : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'No attempts yet.\nPlay a level to start collecting cuts.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
        ),
      ),
    );
  }
}