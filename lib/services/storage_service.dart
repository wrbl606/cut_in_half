import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/player_progress.dart';

/// JSON-file-backed persistence for single-player progress.
class StorageService {
  StorageService({this.fileName = 'cut_in_half_progress.json'});

  final String fileName;

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<PlayerProgress> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return PlayerProgress();
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return PlayerProgress();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PlayerProgress.fromJson(json);
    } catch (_) {
      // Corrupt or unreadable: start fresh.
      return PlayerProgress();
    }
  }

  Future<void> save(PlayerProgress progress) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(progress.toJson()), flush: true);
  }
}
