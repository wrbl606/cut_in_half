import 'dart:io';

import 'package:cut_in_half/models/attempt.dart';
import 'package:cut_in_half/models/cut_line.dart';
import 'package:cut_in_half/models/player_progress.dart';
import 'package:cut_in_half/services/attempt_store.dart';
import 'package:cut_in_half/services/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the persistence services round-trip data through [LocalStore].
/// These tests run on the `dart:io` (mobile/desktop) implementation, so they
/// also guard the file-based path that iOS/macOS rely on (acceptance criteria
/// #2, #3, #4). The web implementation shares the same service logic and is
/// covered by `flutter build web` compiling cleanly.
const String _supportDir = '/tmp/cut_in_half_persistence_test';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async {
        if (call.method == 'getApplicationSupportDirectory') {
          return _supportDir;
        }
        return null;
      },
    );
    final dir = Directory(_supportDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    // Start each test with a clean shared attempts file.
    final attemptsFile = File('$_supportDir/cut_in_half_attempts.json');
    if (attemptsFile.existsSync()) attemptsFile.deleteSync();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  group('StorageService', () {
    test('save then load round-trips player progress', () async {
      final storage = StorageService(fileName: 'test_progress_round.json');
      final progress = PlayerProgress();
      progress.recordResult('level_01', 88, 88.5);
      progress.soundEnabled = false;
      await storage.save(progress);

      final loaded =
          await StorageService(fileName: 'test_progress_round.json').load();
      expect(loaded.forLevel('level_01')?.bestPoints, 88);
      expect(loaded.forLevel('level_01')?.bestAccuracy, 88.5);
      expect(loaded.forLevel('level_01')?.played, isTrue);
      expect(loaded.soundEnabled, isFalse);
      expect(loaded.totalCumulativePoints, 88);
    });

    test('load returns fresh progress when no file exists', () async {
      final loaded =
          await StorageService(fileName: 'test_progress_missing.json').load();
      expect(loaded.levels, isEmpty);
      expect(loaded.soundEnabled, isTrue);
    });

    test('load returns fresh progress on corrupt JSON', () async {
      File('$_supportDir/test_progress_corrupt.json')
          .writeAsStringSync('{ not valid json');
      final loaded =
          await StorageService(fileName: 'test_progress_corrupt.json').load();
      expect(loaded.levels, isEmpty);
    });
  });

  group('AttemptStore', () {
    Attempt attempt(String id, int timestampMs) => Attempt(
          id: id,
          levelId: 'level_01',
          assetPath: 'assets/images/circle.png',
          title: 'Circle',
          targetPieces: 2,
          timeLimit: 30,
          cuts: [
            CutLine(
                id: 'c',
                x1: 0.5,
                y1: 0,
                x2: 0.5,
                y2: 1,
                locked: false,
                isInitial: false)
          ],
          percents: const [50.0, 50.0],
          accuracy: 90.0,
          points: 90,
          remainingSeconds: 10,
          timestampMs: timestampMs,
          mode: AttemptMode.single,
        );

    test('record persists and loadAll returns newest-first', () async {
      final store = AttemptStore();
      await store.record(attempt('a1', 1000));
      await store.record(attempt('a2', 2000));

      final loaded = await store.loadAll();
      expect(loaded.length, 2);
      expect(loaded.first.id, 'a2');
      expect(loaded.last.id, 'a1');
    });

    test('a fresh store loads empty without a backing file', () async {
      final loaded = await AttemptStore().loadAll();
      expect(loaded, isEmpty);
    });

    test('clear removes all attempts', () async {
      final store = AttemptStore();
      await store.record(attempt('a1', 1000));
      await store.clear();
      expect(await store.loadAll(), isEmpty);
    });

    test('attempts survive a reload via a new store instance', () async {
      await AttemptStore().record(attempt('a1', 1000));
      await AttemptStore().record(attempt('a2', 3000));
      final reloaded = await AttemptStore().loadAll();
      expect(reloaded.map((a) => a.id).toList(), ['a2', 'a1']);
    });
  });
}
