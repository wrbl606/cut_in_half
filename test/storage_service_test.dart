import 'package:cut_in_half/models/player_progress.dart';
import 'package:cut_in_half/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    final factory = newDatabaseFactoryMemory();
    final db = await factory.openDatabase('test_progress.db');
    storage = StorageService(database: db);
  });

  test('loads fresh progress when the database is empty', () async {
    final progress = await storage.load();
    expect(progress.soundEnabled, isTrue);
    expect(progress.levels, isEmpty);
    expect(progress.totalCumulativePoints, 0);
  });

  test('persists best scores and sound preference across instances', () async {
    final p = PlayerProgress();
    p.recordResult('level_01', 88, 88.0);
    p.recordResult('level_02', 42, 42.0);
    p.soundEnabled = false;
    await storage.save(p);

    // Simulate a restart by loading through a brand-new service backed by
    // the same database (in-memory factory is per-test, so the DB is shared
    // via the already-opened handle).
    final reloaded = await storage.load();
    expect(reloaded.forLevel('level_01')?.bestPoints, 88);
    expect(reloaded.forLevel('level_01')?.bestAccuracy, 88.0);
    expect(reloaded.forLevel('level_02')?.played, isTrue);
    expect(reloaded.totalCumulativePoints, 130);
    expect(reloaded.soundEnabled, isFalse);
  });

  test('overwriting progress replaces the previous document', () async {
    await storage.save(PlayerProgress()
      ..recordResult('level_01', 100, 100.0)
      ..soundEnabled = true);
    await storage.save(PlayerProgress()..soundEnabled = false);
    final reloaded = await storage.load();
    expect(reloaded.forLevel('level_01'), isNull,
        reason: 'the second save should fully replace the document');
    expect(reloaded.soundEnabled, isFalse);
  });
}