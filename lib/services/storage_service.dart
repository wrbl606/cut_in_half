import 'dart:convert';

import '../models/player_progress.dart';
import 'local_store.dart';

/// JSON-backed persistence for single-player progress.
///
/// Reads and writes go through [LocalStore], which is file-based on
/// mobile/desktop and `localStorage`-backed on the web, so persistence
/// works on every Flutter platform.
class StorageService {
  StorageService({
    this.fileName = 'cut_in_half_progress.json',
    LocalStore? store,
  }) : _store = store ?? LocalStore();

  final String fileName;
  final LocalStore _store;

  Future<PlayerProgress> load() async {
    try {
      final raw = await _store.read(fileName);
      if (raw == null || raw.trim().isEmpty) return PlayerProgress();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PlayerProgress.fromJson(json);
    } catch (_) {
      // Corrupt or unreadable: start fresh.
      return PlayerProgress();
    }
  }

  Future<void> save(PlayerProgress progress) async {
    await _store.write(fileName, jsonEncode(progress.toJson()));
  }
}
