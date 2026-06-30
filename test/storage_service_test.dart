import 'dart:convert';

import 'package:cut_in_half/models/attempt.dart';
import 'package:cut_in_half/models/cut_line.dart';
import 'package:cut_in_half/services/attempt_store.dart';
import 'package:cut_in_half/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Each storage test uses a fresh key namespace via SharedPreferences mock
  // initial values so tests stay isolated.

  test('StorageService round-trips PlayerProgress through SharedPreferences',
      () async {
    SharedPreferences.setMockInitialValues({
      'cut_in_half_progress': jsonEncode({
        'levels': {
          'level_1': {
            'best_accuracy': 87.5,
            'best_points': 120,
            'played': true,
          }
        },
        'sound_enabled': false,
      }),
    });

    final storage = StorageService();
    final loaded = await storage.load();
    expect(loaded.soundEnabled, isFalse);
    expect(loaded.forLevel('level_1')?.bestPoints, 120);
    expect(loaded.forLevel('level_1')?.bestAccuracy, 87.5);

    loaded.recordResult('level_2', 90, 70.0);
    loaded.soundEnabled = true;
    await storage.save(loaded);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cut_in_half_progress')!;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    expect((json['sound_enabled'] as bool), isTrue);
    expect(
      ((json['levels'] as Map)['level_2'] as Map)['best_points'],
      90,
    );
  });

  test('StorageService.load starts fresh on corrupt data', () async {
    SharedPreferences.setMockInitialValues({
      'cut_in_half_progress': 'not json',
    });
    final progress = await StorageService().load();
    expect(progress.soundEnabled, isTrue);
    expect(progress.levels, isEmpty);
  });

  test('AttemptStore records, prunes sessions atomically, and clears',
      () async {
    SharedPreferences.setMockInitialValues({});
    final store = AttemptStore();
    expect(await store.loadAll(), isEmpty);

    final sessionId = store.newSessionId();
    final cuts = <CutLine>[
      CutLine(
        id: 'c1',
        x1: 0.1,
        y1: 0.2,
        x2: 0.8,
        y2: 0.9,
        locked: false,
        isInitial: false,
      ),
    ];

    for (var i = 0; i < 3; i++) {
      await store.record(Attempt.fromResult(
        id: store.newAttemptId('sp'),
        levelId: 'lvl_static',
        assetPath: 'assets/images/apple.png',
        title: 'Apple',
        targetPieces: 2,
        timeLimit: 30,
        cuts: cuts,
        percents: const [50.0, 50.0],
        accuracy: 90.0 + i,
        points: 100 + i,
        remainingSeconds: 10,
        mode: AttemptMode.single,
      ));
    }
    final afterSingle = await store.loadAll();
    expect(afterSingle.length, 3);
    expect(afterSingle.first.points, 102);

    // A multiplayer session of two players is recorded atomically.
    final sessionAttempts = [
      Attempt.fromResult(
        id: store.newAttemptId('mp'),
        levelId: 'lvl_mp',
        assetPath: 'assets/images/banana.png',
        title: 'Banana',
        targetPieces: 3,
        timeLimit: 30,
        cuts: cuts,
        percents: const [33.3, 33.3, 33.4],
        accuracy: 80,
        points: 40,
        remainingSeconds: 5,
        mode: AttemptMode.multi,
        playerName: 'P1',
        sessionId: sessionId,
      ),
      Attempt.fromResult(
        id: store.newAttemptId('mp'),
        levelId: 'lvl_mp',
        assetPath: 'assets/images/banana.png',
        title: 'Banana',
        targetPieces: 3,
        timeLimit: 30,
        cuts: cuts,
        percents: const [50, 25, 25],
        accuracy: 70,
        points: 30,
        remainingSeconds: 8,
        mode: AttemptMode.multi,
        playerName: 'P2',
        sessionId: sessionId,
      ),
    ];
    await store.recordSession(sessionAttempts);

    final afterMp = await store.loadAll();
    expect(afterMp.length, 5);
    final sessionEntries = afterMp.where((a) => a.sessionId == sessionId).toList();
    expect(sessionEntries.length, 2);
    // Player order preserved (oldest first by midpoint).
    final ordered = sessionEntries
      ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
    expect(ordered.first.playerName, 'P1');
    expect(ordered.last.playerName, 'P2');

    await store.clear();
    expect(await store.loadAll(), isEmpty);
  });

  test('AttemptStore.loadAll starts fresh on corrupt data', () async {
    SharedPreferences.setMockInitialValues({
      'cut_in_half_attempts': 'broken',
    });
    expect(await AttemptStore().loadAll(), isEmpty);
  });
}