import 'cut_line.dart';

/// Mode of play that produced an [Attempt].
enum AttemptMode { single, multi }

/// One stored cut attempt — captures enough data to re-render a
/// miniature preview of the cuts and compare across players / attempts.
///
/// Stores the cuts (normalized coords) + the level's asset path, the
/// per-piece percentages, and metadata (mode, player name, session).
/// Miniatures are rendered on demand from `assetPath` + `cuts`, so the
/// file stays small (no encoded bitmaps).
class Attempt {
  Attempt({
    required this.id,
    required this.levelId,
    required this.assetPath,
    required this.title,
    required this.targetPieces,
    required this.timeLimit,
    required this.cuts,
    required this.percents,
    required this.accuracy,
    required this.points,
    required this.remainingSeconds,
    required this.timestampMs,
    required this.mode,
    this.playerName,
    this.sessionId,
    this.objectiveMet = true,
    this.objectiveMessage,
  });

  factory Attempt.fromResult({
    required String id,
    required String levelId,
    required String assetPath,
    required String title,
    required int targetPieces,
    required int timeLimit,
    required List<CutLine> cuts,
    required List<double> percents,
    required double accuracy,
    required int points,
    required int remainingSeconds,
    required AttemptMode mode,
    String? playerName,
    String? sessionId,
    bool objectiveMet = true,
    String? objectiveMessage,
    int? timestampMs,
  }) {
    return Attempt(
      id: id,
      levelId: levelId,
      assetPath: assetPath,
      title: title,
      targetPieces: targetPieces,
      timeLimit: timeLimit,
      cuts: cuts,
      percents: percents,
      accuracy: accuracy,
      points: points,
      remainingSeconds: remainingSeconds,
      timestampMs: timestampMs ??
          DateTime.now().toUtc().millisecondsSinceEpoch,
      mode: mode,
      playerName: playerName,
      sessionId: sessionId,
      objectiveMet: objectiveMet,
      objectiveMessage: objectiveMessage,
    );
  }

  factory Attempt.fromJson(Map<String, dynamic> json) {
    final rawCuts = (json['cuts'] as List<dynamic>?) ?? const <dynamic>[];
    final cuts =
        rawCuts.map((c) => CutLine.fromJson(c as Map<String, dynamic>)).toList();
    final rawPercents =
        (json['percents'] as List<dynamic>?) ?? const <dynamic>[];
    final percents = rawPercents
        .map((p) => (p as num).toDouble())
        .toList(growable: false);
    return Attempt(
      id: json['id'] as String? ?? '',
      levelId: json['level_id'] as String? ?? '',
      assetPath: json['asset_path'] as String? ?? '',
      title: json['title'] as String? ?? '',
      targetPieces: (json['target_pieces'] as num?)?.toInt() ?? 0,
      timeLimit: (json['time_limit'] as num?)?.toInt() ?? 0,
      cuts: cuts,
      percents: percents,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      remainingSeconds: (json['remaining_seconds'] as num?)?.toInt() ?? 0,
      timestampMs: (json['timestamp_ms'] as num?)?.toInt() ??
          DateTime.now().toUtc().millisecondsSinceEpoch,
      mode: (json['mode'] as String?) == 'multi'
          ? AttemptMode.multi
          : AttemptMode.single,
      playerName: json['player_name'] as String?,
      sessionId: json['session_id'] as String?,
      objectiveMet: json['objective_met'] as bool? ?? true,
      objectiveMessage: json['objective_message'] as String?,
    );
  }

  final String id;
  final String levelId;
  final String assetPath;
  final String title;
  final int targetPieces;
  final int timeLimit;

  /// Player-drawn + initial cut lines (all), normalized [0,1].
  final List<CutLine> cuts;

  /// Resulting piece percentages in order, 0..100.
  final List<double> percents;

  final double accuracy;
  final int points;
  final int remainingSeconds;

  /// UTC milliseconds since epoch when the attempt finished.
  final int timestampMs;

  final AttemptMode mode;

  /// Player name for multiplayer attempts; null for single-player.
  final String? playerName;

  /// Multiplayer session id grouping attempts from the same match.
  /// Null for single-player.
  final String? sessionId;

  final bool objectiveMet;
  final String? objectiveMessage;

  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true);

  Map<String, dynamic> toJson() => {
        'id': id,
        'level_id': levelId,
        'asset_path': assetPath,
        'title': title,
        'target_pieces': targetPieces,
        'time_limit': timeLimit,
        'cuts': cuts.map((c) => c.toJson()).toList(),
        'percents': percents,
        'accuracy': accuracy,
        'points': points,
        'remaining_seconds': remainingSeconds,
        'timestamp_ms': timestampMs,
        'mode': mode == AttemptMode.multi ? 'multi' : 'single',
        'player_name': playerName,
        'session_id': sessionId,
        'objective_met': objectiveMet,
        'objective_message': objectiveMessage,
      };

  Attempt copyWith({
    String? id,
    String? levelId,
    String? assetPath,
    String? title,
    int? targetPieces,
    int? timeLimit,
    List<CutLine>? cuts,
    List<double>? percents,
    double? accuracy,
    int? points,
    int? remainingSeconds,
    int? timestampMs,
    AttemptMode? mode,
    String? playerName,
    String? sessionId,
    bool? objectiveMet,
    String? objectiveMessage,
  }) {
    return Attempt(
      id: id ?? this.id,
      levelId: levelId ?? this.levelId,
      assetPath: assetPath ?? this.assetPath,
      title: title ?? this.title,
      targetPieces: targetPieces ?? this.targetPieces,
      timeLimit: timeLimit ?? this.timeLimit,
      cuts: cuts ?? this.cuts,
      percents: percents ?? this.percents,
      accuracy: accuracy ?? this.accuracy,
      points: points ?? this.points,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      timestampMs: timestampMs ?? this.timestampMs,
      mode: mode ?? this.mode,
      playerName: playerName ?? this.playerName,
      sessionId: sessionId ?? this.sessionId,
      objectiveMet: objectiveMet ?? this.objectiveMet,
      objectiveMessage: objectiveMessage ?? this.objectiveMessage,
    );
  }
}