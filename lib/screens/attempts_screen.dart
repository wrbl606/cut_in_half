import 'package:flutter/material.dart';

import '../models/attempt.dart';
import '../services/attempt_store.dart';
import '../widgets/miniature_cut.dart';

/// Browse and compare stored attempts as miniature cut previews.
///
/// When [levelId] is set, only single-player attempts for that level are
/// shown. When [sessionId] is set, only the multiplayer attempts of that
/// session are shown. When neither is set, all attempts are listed with
/// All / Single / Multiplayer filters.
class AttemptsScreen extends StatefulWidget {
  const AttemptsScreen({super.key, this.levelId, this.sessionId, this.title});

  final String? levelId;
  final String? sessionId;
  final String? title;

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

  List<Attempt> _filtered(List<Attempt> all) {
    if (widget.levelId != null) {
      return all
          .where((a) =>
              a.mode == AttemptMode.single && a.levelId == widget.levelId)
          .toList();
    }
    if (widget.sessionId != null) {
      return all
          .where((a) =>
              a.mode == AttemptMode.multi && a.sessionId == widget.sessionId)
          .toList();
    }
    return all;
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
    final raw = _attempts;
    if (raw == null) {
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
    final attempts = _filtered(raw);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title ?? 'Attempts'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (widget.levelId == null &&
              widget.sessionId == null &&
              attempts.isNotEmpty)
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
            : _GroupedAttempts(
                attempts: attempts,
                forceSingleLevel: widget.levelId != null,
                forceSession: widget.sessionId != null,
              ),
      ),
    );
  }
}

enum _Grouping { all, multi, single }

class _GroupedAttempts extends StatefulWidget {
  const _GroupedAttempts({
    required this.attempts,
    this.forceSingleLevel = false,
    this.forceSession = false,
  });
  final List<Attempt> attempts;
  final bool forceSingleLevel;
  final bool forceSession;

  @override
  State<_GroupedAttempts> createState() => _GroupedAttemptsState();
}

class _GroupedAttemptsState extends State<_GroupedAttempts> {
  _Grouping _grouping = _Grouping.all;

  bool get _filtered =>
      widget.forceSingleLevel || widget.forceSession;

  List<_AttemptGroup> _buildAll(List<Attempt> all) {
    // Multiplayer attempts are grouped by session. Single-player attempts
    // are grouped per level so all replays of a level sit together.
    final groups = <String, _AttemptGroup>{};
    for (final a in all) {
      final key = a.mode == AttemptMode.multi
          ? 'multi_${a.sessionId ?? a.id}'
          : 'level_${a.levelId}';
      groups[key] ??= _AttemptGroup(
        key: key,
        mode: a.mode,
        title: a.mode == AttemptMode.multi
            ? 'Multiplayer · ${a.title}'
            : a.title,
        assetPath: a.assetPath,
        sessionId: a.sessionId,
      );
      groups[key]!.attempts.add(a);
    }
    return groups.values.toList()
      ..sort((g1, g2) {
        // Newest attempt in the group determines the group order.
        final a = g1.attempts.fold<int>(0,
            (m, x) => x.timestampMs > m ? x.timestampMs : m);
        final b = g2.attempts.fold<int>(0,
            (m, x) => x.timestampMs > m ? x.timestampMs : m);
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
        if (!_filtered)
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
        if (!_filtered) const Divider(height: 1, color: Color(0xFFEEEEEE)),
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
    final newest = group.attempts.reduce((x, y) =>
        x.timestampMs > y.timestampMs ? x : y);
    final best = group.attempts.reduce((x, y) =>
        x.accuracy > y.accuracy ? x : y);
    final time = newest.timestamp;
    final timeLabel =
        '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final meta = group.mode == AttemptMode.multi
        ? '$timeLabel  ·  ${newest.targetPieces} pieces  ·  '
            '${list.length} player${list.length == 1 ? '' : 's'}'
        : '${newest.targetPieces} pieces  ·  ${list.length} attempt'
            '${list.length == 1 ? '' : 's'}  ·  best ${best.accuracy.toStringAsFixed(1)}%'
            '  ·  last $timeLabel';
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
                      meta,
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
          _ComparisonGrid(ordered: list),
        ],
      ),
    );
  }
}

class _ComparisonGrid extends StatelessWidget {
  const _ComparisonGrid({required this.ordered});
  final List<Attempt> ordered;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1000 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
            childAspectRatio: 0.78,
          ),
          itemCount: ordered.length,
          itemBuilder: (context, i) {
            final a = ordered[i];
            final colIndex = i % crossAxisCount;
            final rowIndex = i ~/ crossAxisCount;
            final isLastCol = colIndex == crossAxisCount - 1;
            final rowCount = (ordered.length + crossAxisCount - 1) ~/ crossAxisCount;
            final isLastRow = rowIndex == rowCount - 1;
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  right: isLastCol
                      ? BorderSide.none
                      : const BorderSide(color: Color(0xFFEEEEEE), width: 1),
                  bottom: isLastRow
                      ? BorderSide.none
                      : const BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: _AttemptTile(attempt: a),
            );
          },
        );
      },
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({required this.attempt});
  final Attempt attempt;

  @override
  Widget build(BuildContext context) {
    final a = attempt;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MiniatureCut(
              assetPath: a.assetPath,
              cuts: a.cuts,
            ),
          ),
          const SizedBox(height: 6),
          if (a.mode == AttemptMode.multi && a.playerName != null)
            Text(
              a.playerName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
            )
          else if (a.mode == AttemptMode.single)
            Text(
              _shortDate(a.timestamp),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF999999),
                fontFeatures: [FontFeature.tabularFigures()],
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
                  fontFeatures: const [FontFeature.tabularFigures()],
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

String _shortDate(DateTime t) {
  final day = t.day.toString().padLeft(2, '0');
  final month = t.month.toString().padLeft(2, '0');
  final hour = t.hour.toString().padLeft(2, '0');
  final minute = t.minute.toString().padLeft(2, '0');
  return '$month-$day $hour:$minute';
}