import 'package:sembast/sembast.dart';

import '../models/player_progress.dart';
import 'database.dart';

/// Sembast-backed persistence for single-player progress.
///
/// Player progress is stored as a single document (key `progress`) inside a
/// `progress` store within the shared app database. On native platforms the
/// database is backed by sqflite; on web by IndexedDB — `dart:io` and
/// `path_provider` are intentionally never referenced here so the same code
/// runs unchanged on iOS, macOS, and the browser.
class StorageService {
  StorageService({this.dbName = kAppDatabaseName, this.database});

  final String dbName;

  /// Optional injected database (used in tests to swap in an in-memory
  /// sembast factory). When null the shared [getAppDatabase] singleton is
  /// used, which selects sqflite on native and IndexedDB on web.
  final Database? database;

  static final StoreRef<String, Map<String, Object?>> _store =
      stringMapStoreFactory.store('progress');
  static const String _progressKey = 'progress';

  Future<Database> _db() =>
      database != null ? Future.value(database!) : getAppDatabase();

  Future<PlayerProgress> load() async {
    try {
      final db = await _db();
      final raw = await _store.record(_progressKey).get(db);
      if (raw == null || raw.isEmpty) return PlayerProgress();
      return PlayerProgress.fromJson(_asDynamicMap(raw));
    } catch (_) {
      // Corrupt or unreadable: start fresh.
      return PlayerProgress();
    }
  }

  Future<void> save(PlayerProgress progress) async {
    final db = await _db();
    await _store.record(_progressKey).put(db, progress.toJson());
  }
}

Map<String, dynamic> _asDynamicMap(Map<String, Object?> raw) {
  final result = <String, dynamic>{};
  raw.forEach((key, value) {
    if (value is Map<String, Object?>) {
      result[key] = _asDynamicMap(value);
    } else {
      result[key] = value;
    }
  });
  return result;
}