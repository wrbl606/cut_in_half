import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_progress.dart';

/// Key-value-backed persistence for single-player progress, built on
/// `shared_preferences` so it works on web, iOS, macOS, and Android.
class StorageService {
  StorageService({this.prefKey = 'cut_in_half_progress'});

  final String prefKey;

  Future<PlayerProgress> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefKey);
      if (raw == null || raw.trim().isEmpty) return PlayerProgress();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PlayerProgress.fromJson(json);
    } catch (_) {
      // Corrupt or unreadable: start fresh.
      return PlayerProgress();
    }
  }

  Future<void> save(PlayerProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKey, jsonEncode(progress.toJson()));
    } catch (_) {
      // Swallow persistence errors so gameplay (e.g. navigating to the
      // ResultScreen on web) is never blocked by a storage failure.
    }
  }
}