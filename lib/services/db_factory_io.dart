import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// Opens (and caches) the sembast database backed by sqflite on native
/// platforms (iOS and macOS). A relative [name] is resolved by sqflite
/// against the platform's default databases directory, so we never touch
/// `dart:io` or `path_provider` directly.
Future<Database> openAppDatabase(String name) {
  final factory = getDatabaseFactorySqflite(sqflite.databaseFactory);
  return factory.openDatabase(name);
}