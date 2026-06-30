import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:sembast/sembast.dart';

import 'storage_backend_stub.dart'
    if (dart.library.io) 'storage_backend_native.dart'
    if (dart.library.js_interop) 'storage_backend_web.dart'
    as backend;

/// Opens (creating if necessary) the named application database.
///
/// The persistence layer is selected at compile time: sqflite on native
/// (iOS / macOS / Android) and indexed_db on Flutter Web. Databases are
/// cached for the lifetime of the process so screens can open them
/// independently without paying a reconnect cost on every read/write.
final Map<String, Future<Database>> _databaseCache =
    <String, Future<Database>>{};

/// The platform-selected factory, unless overridden for tests.
DatabaseFactory? _overrideFactory;

/// Replaces the storage backend factory. Tests inject an in-memory
/// factory so they never touch platform plugins (`sqflite`, indexed_db);
/// pass `null` to restore the default cross-platform backend.
@visibleForTesting
void setStorageBackendFactory(DatabaseFactory? factory) {
  _overrideFactory = factory;
  _databaseCache.clear();
}

Future<Database> openAppDatabase(String name) {
  if (_overrideFactory != null) {
    return _overrideFactory!.openDatabase(name);
  }
  return _databaseCache.putIfAbsent(name, () => backend.openAppDatabase(name));
}