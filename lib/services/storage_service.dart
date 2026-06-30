import 'package:sembast/sembast.dart';

import '../models/player_progress.dart';
import 'storage_backend.dart';

/// Sembast-backed persistence for single-player progress.
///
/// Replaces the previous JSON-file solution (which used `dart:io` File +
/// `path_provider`) so the same code runs on iOS, macOS, and Flutter Web.
/// The [PlayerProgress] document is stored as a single record keyed by
/// [_kRecordKey] in its own database file.
class StorageService {
  StorageService({this.dbName = 'cut_in_half_progress.db'});

  final String dbName;

  static final StoreRef<String, Map<String, dynamic>> _store =
      StoreRef<String, Map<String, dynamic>>('progress');
  static const String _kRecordKey = 'progress';

  Future<Database> _db() => openAppDatabase(dbName);

  Future<PlayerProgress> load() async {
    try {
      final db = await _db();
      final json = await _store.record(_kRecordKey).get(db);
      if (json == null) return PlayerProgress();
      return PlayerProgress.fromJson(json);
    } catch (_) {
      // Corrupt or unreadable: start fresh.
      return PlayerProgress();
    }
  }

  Future<void> save(PlayerProgress progress) async {
    final db = await _db();
    await _store.record(_kRecordKey).put(db, progress.toJson());
  }
}