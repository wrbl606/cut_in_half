// ignore_for_file: avoid_web_libraries_in_flutter
/// Web storage backend: sembast persisted on top of indexed_db via
/// `sembast_web`. This implementation is only compiled for Flutter Web.
library;

import 'package:sembast_web/sembast_web.dart';

Future<Database> openAppDatabase(String name) =>
    databaseFactoryWeb.openDatabase(name);