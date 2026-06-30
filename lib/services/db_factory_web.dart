import 'package:sembast_web/sembast_web.dart';

/// Opens (and caches) the sembast database backed by IndexedDB.
///
/// Used when the app is compiled for the web. The [name] doubles as the
/// IndexedDB database name; no filesystem path is required.
Future<Database> openAppDatabase(String name) =>
    databaseFactoryWeb.openDatabase(name);