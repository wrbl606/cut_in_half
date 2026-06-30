import 'package:sembast/sembast.dart';

import 'db_factory.dart';

/// Lazily-opened, process-wide singleton sembast database shared by the
/// [StorageService] (player progress) and [AttemptStore] (attempt history).
///
/// They live as independent stores inside a single database file so the two
/// evolve together but never collide. The underlying factory (sqflite on
/// native, IndexedDB on web) is resolved per-platform by [openAppDatabase].
const String kAppDatabaseName = 'cut_in_half.db';

Database? _instance;
Future<Database>? _openFuture;

/// Returns the shared app database, opening it once on first use.
Future<Database> getAppDatabase() {
  if (_instance != null) return Future.value(_instance);
  return _openFuture ??= openAppDatabase(kAppDatabaseName)
      .then((db) => _instance = db);
}