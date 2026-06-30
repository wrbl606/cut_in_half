import 'package:cut_in_half/models/attempt.dart';
import 'package:cut_in_half/models/cut_line.dart';
import 'package:cut_in_half/services/attempt_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  late AttemptStore store;

  setUp(() async {
    final factory = newDatabaseFactoryMemory();
    final db = await factory.openDatabase('test_attempts.db');
    store = AttemptStore(database: db);
  });

  Attempt makeAttempt({
    required String id,
    String levelId = 'level_01',
    int points = 50,
    double accuracy = 50.0,
    AttemptMode mode = AttemptMode.single,
    String? playerName,
    String? sessionId,
    int? timestampMs,
  }) {
    return Attempt(
      id: id,
      levelId: levelId,
      assetPath: 'assets/images/circle.png',
      title: 'Circle',
      targetPieces: 2,
      timeLimit: 30,
      cuts: [CutLine(id: 'c1', x1: 0.5, y1: 0, x2: 0.5, y2: 1, locked: false, isInitial: false)],
      percents: const [50.0, 50.0],
      accuracy: accuracy,
      points: points,
      remainingSeconds: 5,
      timestampMs: timestampMs ?? DateTime.now().toUtc().millisecondsSinceEpoch,
      mode: mode,
      playerName: playerName,
      sessionId: sessionId,
    );
  }

  test('starts empty', () async {
    expect(await store.loadAll(), isEmpty);
  });

  test('records and reloads attempts newest-first', () async {
    await store.record(makeAttempt(id: 'a1', timestampMs: 1000, points: 10));
    await store.record(makeAttempt(id: 'a2', timestampMs: 2000, points: 20));
    final all = await store.loadAll();
    expect(all.map((a) => a.id), ['a2', 'a1']);
  });

  test('persists attempt history across instances', () async {
    await store.record(makeAttempt(id: 'a1', timestampMs: 1000));
    final reloaded = await AttemptStore(database: store.database!).loadAll();
    expect(reloaded, hasLength(1));
    expect(reloaded.first.id, 'a1');
  });

  test('keeps a multiplayer session grouped during pruning', () async {
    final sessionId = 'mp_session';
    final players = <Attempt>[];
    for (var i = 0; i < 150; i++) {
      players.add(makeAttempt(
        id: 'old_solo_$i',
        sessionId: null,
        timestampMs: 1000 + i,
        points: i,
      ));
    }
    await store.saveAll(players);

    // Now record a fresh multiplayer session of 3 players, then prune.
    final session = [
      makeAttempt(id: 'mp1', sessionId: sessionId, mode: AttemptMode.multi, timestampMs: 100000),
      makeAttempt(id: 'mp2', sessionId: sessionId, mode: AttemptMode.multi, timestampMs: 100001),
      makeAttempt(id: 'mp3', sessionId: sessionId, mode: AttemptMode.multi, timestampMs: 100002),
    ];
    final all = await store.recordSession(session);

    final reloaded = await store.loadAll();
    final sessionAttempts = reloaded.where((a) => a.sessionId == sessionId).toList();
    expect(sessionAttempts, hasLength(3),
        reason: 'the entire multiplayer session must survive pruning as a group');
    expect(reloaded.length, lessThanOrEqualTo(200));
    expect(all.length, reloaded.length);
  });

  test('clear empties the store', () async {
    await store.record(makeAttempt(id: 'a1', timestampMs: 1000));
    await store.clear();
    expect(await store.loadAll(), isEmpty);
  });

  test('newSessionId/newAttemptId are unique-ish strings', () {
    final sid = store.newSessionId();
    expect(sid, startsWith('mp_'));
    final aid = store.newAttemptId('sp');
    expect(aid, startsWith('sp_'));
    expect(store.newAttemptId('sp'), isNot(aid));
  });
}