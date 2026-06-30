import 'dart:math';

import 'package:sembast/sembast.dart';

import '../models/attempt.dart';
import 'storage_backend.dart';

/// Sembast-backed persistence for the full attempt history (both single
/// and multiplayer). Stored separately from the best-score progress
/// database so the two evolve independently.
class AttemptStore {
  static const String _dbName = 'cut_in_half_attempts.db';

  /// Maximum number of attempts kept. Oldest are pruned first; an entire
  /// multiplayer session is kept or discarded atomically so its player
  /// attempts stay grouped.
  static const int _cap = 200;

  static final StoreRef<String, List<dynamic>> _store =
      StoreRef<String, List<dynamic>>('attempts');
  static const String _kRecordKey = 'attempts';

  Future<Database> _db() => openAppDatabase(_dbName);

  /// Attempts newest-first.
  Future<List<Attempt>> loadAll() async {
    try {
      final db = await _db();
      final list = await _store.record(_kRecordKey).get(db);
      if (list == null) return <Attempt>[];
      final attempts = list
          .map((e) => Attempt.fromJson(e as Map<String, dynamic>))
          .toList();
      attempts.sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
      return attempts;
    } catch (_) {
      return <Attempt>[];
    }
  }

  Future<void> saveAll(List<Attempt> attempts) async {
    final db = await _db();
    final trimmed = _prune(attempts);
    await _store
        .record(_kRecordKey)
        .put(db, trimmed.map((a) => a.toJson()).toList());
  }

  /// Appends [attempt] and persists. Returns the updated list.
  Future<List<Attempt>> record(Attempt attempt) async {
    final all = await loadAll();
    all.insert(0, attempt);
    await saveAll(all);
    return all..sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
  }

  /// Atomically records all multiplayer attempts of a single session.
  /// They are time-stamped sequentially (preserving player order) so the
  /// group stays together even under pruning.
  Future<List<Attempt>> recordSession(List<Attempt> attempts) async {
    if (attempts.isEmpty) return loadAll();
    final all = await loadAll();
    final base = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (var i = 0; i < attempts.length; i++) {
      all.insert(
          0, attempts[i].copyWith(timestampMs: base + i));
    }
    await saveAll(all);
    return all..sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
  }

  Future<void> clear() async {
    await saveAll(const <Attempt>[]);
  }

  /// Pruning preserves whole multiplayer sessions: when forced to drop
  /// attempts beyond [_cap], the oldest session's attempts are removed
  /// together.
  List<Attempt> _prune(List<Attempt> attempts) {
    if (attempts.length <= _cap) return List<Attempt>.of(attempts);
    final sorted = List<Attempt>.of(attempts)
      ..sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
    final keep = <Attempt>[];
    // Group by session id, preserving single-player attempts as their
    // own "groups" (each its own session id == attempt id surrogate).
    final bySession = <String, List<Attempt>>{};
    for (final a in sorted) {
      final key = a.sessionId ?? 'solo_${a.id}';
      (bySession[key] ??= <Attempt>[]).add(a);
    }
    // Sessions are already ordered by their newest attempt because
    // `sorted` is newest-first and we iterate in that order.
    final sessionOrder = <String>[];
    final seen = <String>{};
    for (final a in sorted) {
      final key = a.sessionId ?? 'solo_${a.id}';
      if (seen.add(key)) sessionOrder.add(key);
    }
    var count = 0;
    for (final key in sessionOrder) {
      final group = bySession[key]!;
      if (count + group.length > _cap && keep.isNotEmpty) break;
      keep.addAll(group);
      count += group.length;
    }
    return keep;
  }

  /// Generates a session id for a multiplayer match.
  String newSessionId() {
    final r = Random();
    return 'mp_${DateTime.now().toUtc().millisecondsSinceEpoch}_'
        '${r.nextInt(1 << 32)}';
  }

  /// Generates a unique attempt id.
  String newAttemptId(String prefix) {
    final r = Random();
    return '${prefix}_${DateTime.now().toUtc().millisecondsSinceEpoch}_'
        '${r.nextInt(1 << 32)}';
  }
}