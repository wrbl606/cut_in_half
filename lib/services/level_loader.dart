import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/level.dart';

class LevelLoader {
  static const String _assetPath = 'assets/levels/levels.json';

  /// Loads and parses all levels from the bundled levels.json asset.
  static Future<List<Level>> loadAll() async {
    final raw = await rootBundle.loadString(_assetPath);
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
