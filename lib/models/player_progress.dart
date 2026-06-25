class LevelProgress {
  LevelProgress({
    this.bestAccuracy = 0.0,
    this.bestPoints = 0,
    this.played = false,
  });

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      bestAccuracy: (json['best_accuracy'] as num?)?.toDouble() ?? 0.0,
      bestPoints: (json['best_points'] as num?)?.toInt() ?? 0,
      played: json['played'] as bool? ?? false,
    );
  }

  double bestAccuracy;
  int bestPoints;
  bool played;

  Map<String, dynamic> toJson() => {
        'best_accuracy': bestAccuracy,
        'best_points': bestPoints,
        'played': played,
      };
}

class PlayerProgress {
  PlayerProgress({Map<String, LevelProgress>? levels}) : _levels = levels ?? {};

  factory PlayerProgress.fromJson(Map<String, dynamic> json) {
    final levels = <String, LevelProgress>{};
    final raw = json['levels'] as Map<String, dynamic>? ?? {};
    raw.forEach((key, value) {
      levels[key] = LevelProgress.fromJson(value as Map<String, dynamic>);
    });
    return PlayerProgress(levels: levels);
  }

  final Map<String, LevelProgress> _levels;

  Map<String, LevelProgress> get levels => _levels;

  /// Total cumulative points across all played levels (best scores only).
  int get totalCumulativePoints =>
      _levels.values.where((l) => l.played).fold(0, (s, l) => s + l.bestPoints);

  LevelProgress? forLevel(String levelId) => _levels[levelId];

  LevelProgress forLevelOrCreate(String levelId) {
    return _levels.putIfAbsent(levelId, () => LevelProgress());
  }

  /// Records a result. Best only improves; cumulative is derived from bests.
  /// Returns true if the best improved on this play.
  bool recordResult(String levelId, int points, double accuracy) {
    final p = forLevelOrCreate(levelId);
    var improved = false;
    if (!p.played || points > p.bestPoints) {
      p.bestPoints = points;
      p.bestAccuracy = accuracy;
      improved = true;
    }
    p.played = true;
    return improved;
  }

  Map<String, dynamic> toJson() => {
        'levels':
            _levels.map((key, value) => MapEntry(key, value.toJson())),
      };
}
