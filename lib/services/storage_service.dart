import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_progress.dart';

/// SharedPreferences-backed persistence for single-player progress.
///
/// Works across all Flutter targets (mobile, desktop, web) without touching
/// `dart:io`. JSON-encodes the [PlayerProgress] tree under a single key.
class StorageService {
  StorageService({this.prefsKey = 'cut_in_half_progress'});

  final String prefsKey;

  Future<PlayerProgress> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw == null || raw.trim().isEmpty) return PlayerProgress();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PlayerProgress.fromJson(json);
    } catch (_) {
      // Corrupt or unreadable: start fresh.
      return PlayerProgress();
    }
  }

  Future<void> save(PlayerProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, jsonEncode(progress.toJson()));
  }
}