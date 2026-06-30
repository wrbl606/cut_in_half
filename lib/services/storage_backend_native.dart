/// Native (iOS / macOS / Android) storage backend: sembast persisted on
/// top of sqflite. sqflite resolves its own database directory via the
/// platform plugin, so this never touches `path_provider` or `dart:io`.
library;

import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

Future<Database> openAppDatabase(String name) {
  final factory = getDatabaseFactorySqflite(sqflite.databaseFactory);
  return factory.openDatabase(name);
}