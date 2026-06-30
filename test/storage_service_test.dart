import 'package:cut_in_half/models/attempt.dart';
import 'package:cut_in_half/models/cut_line.dart';
import 'package:cut_in_half/models/player_progress.dart';
import 'package:cut_in_half/services/attempt_store.dart';
import 'package:cut_in_half/services/storage_backend.dart';
import 'package:cut_in_half/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

/// These tests drive the new sembast-backed persistence layer against an
/// in-memory factory, so they run on the test VM without sqflite or
/// indexed_db and verify the round-tripping that the screens rely on.
void main() {
  late DatabaseFactory factory;

  setUp(() {
    // A fresh isolated in-memory factory per test keeps tests independent.
    factory = newDatabaseFactoryMemory();
    setStorageBackendFactory(factory);
  });

  tearDown(() {
    setStorageBackendFactory(null);
  });

  group('StorageService', () {
    test('round-trips player progress across instances', () async {
      final writer = StorageService(dbName: 'test_progress.db');
      final progress = PlayerProgress()
        ..soundEnabled = false
        ..recordResult('level_01', 88, 88.5);
      await writer.save(progress);

      // A fresh service instance reads the same persisted document.
      final reader = StorageService(dbName: 'test_progress.db');
      final loaded = await reader.load();
      expect(loaded.soundEnabled, isFalse);
      expect(loaded.forLevel('level_01')?.bestPoints, 88);
      expect(loaded.forLevel('level_01')?.bestAccuracy, 88.5);
      expect(loaded.forLevel('level_01')?.played, isTrue);
    });

    test('load starts fresh when nothing is persisted', () async {
      final loaded = await StorageService(dbName: 'empty_progress.db').load();
      expect(loaded.soundEnabled, isTrue);
      expect(loaded.totalCumulativePoints, 0);
    });
  });

  group('AttemptStore', () {
    Attempt single(String id, String levelId, int ts) {
      return Attempt.fromResult(
        id: id,
        levelId: levelId,
        assetPath: 'assets/images/circle.png',
        title: 'Circle',
        targetPieces: 2,
        timeLimit: 30,
        cuts: [CutLine(id: 'c1', x1: 0.5, y1: 0, x2: 0.5, y2: 1, locked: false, isInitial: false)],
        percents: [50.0, 50.0],
        accuracy: 90.0,
        points: 90,
        remainingSeconds: 5,
        mode: AttemptMode.single,
        timestampMs: ts,
      );
    }

    test('records and lists single attempts newest-first', () async {
      final store = AttemptStore();
      await store.record(single(store.newAttemptId('sp'), 'l1', 1000));
      await store.record(single(store.newAttemptId('sp'), 'l1', 3000));

      final all = await store.loadAll();
      expect(all.length, 2);
      expect(all.first.timestampMs, 3000);
      expect(all.last.timestampMs, 1000);
    });

    test('records a multiplayer session as a grouped set', () async {
      final store = AttemptStore();
      final sessionId = store.newSessionId();
      final attempts = [
        Attempt.fromResult(
          id: store.newAttemptId('mp'),
          levelId: 'l1',
          assetPath: 'assets/images/circle.png',
          title: 'Circle',
          targetPieces: 2,
          timeLimit: 30,
          cuts: const [],
          percents: const [100.0],
          accuracy: 80.0,
          points: 80,
          remainingSeconds: 4,
          mode: AttemptMode.multi,
          playerName: 'Alice',
          sessionId: sessionId,
          timestampMs: 5000,
        ),
        Attempt.fromResult(
          id: store.newAttemptId('mp'),
          levelId: 'l1',
          assetPath: 'assets/images/circle.png',
          title: 'Circle',
          targetPieces: 2,
          timeLimit: 30,
          cuts: const [],
          percents: const [100.0],
          accuracy: 60.0,
          points: 60,
          remainingSeconds: 2,
          mode: AttemptMode.multi,
          playerName: 'Bob',
          sessionId: sessionId,
          timestampMs: 5001,
        ),
      ];
      await store.recordSession(attempts);

      final all = await store.loadAll();
      expect(all.length, 2);
      // The session's attempts keep a shared sessionId and stay grouped.
      expect(all.every((a) => a.sessionId == sessionId), isTrue);
      expect(all.map((a) => a.playerName).toSet(), {'Alice', 'Bob'});
    });

    test('records persist across new AttemptStore instances', () async {
      final a = AttemptStore();
      await a.record(single(a.newAttemptId('sp'), 'l1', 7000));
      final b = AttemptStore();
      final all = await b.loadAll();
      expect(all.length, 1);
      expect(all.first.levelId, 'l1');
    });

    test('clear empties all stored attempts', () async {
      final store = AttemptStore();
      await store.record(single(store.newAttemptId('sp'), 'l1', 100));
      expect((await store.loadAll()).length, 1);
      await store.clear();
      expect((await store.loadAll()), isEmpty);
    });
  });
}