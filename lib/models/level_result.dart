import 'cut_line.dart';

class PieceInfo {
  PieceInfo({
    required this.regionId,
    required this.area,
    required this.percent,
    required this.bboxMinX,
    required this.bboxMinY,
    required this.bboxMaxX,
    required this.bboxMaxY,
    required this.maskWidth,
    required this.maskHeight,
    required this.mask,
  });

  final int regionId;
  final int area;
  final double percent;

  /// Bounding box in normalized [0,1] coords (independent of mask scale).
  final double bboxMinX;
  final double bboxMinY;
  final double bboxMaxX;
  final double bboxMaxY;

  /// Region mask at mask-sample scale, covering the bbox.
  final int maskWidth;
  final int maskHeight;
  final List<bool> mask;
}

class LevelResult {
  LevelResult({
    required this.levelId,
    required this.cuts,
    required this.pieces,
    required this.accuracy,
    required this.points,
    required this.remainingSeconds,
    this.objectiveMet = true,
    this.objectiveMessage,
  });

  final String levelId;
  final List<CutLine> cuts;
  final List<PieceInfo> pieces;
  final double accuracy;
  final int points;
  final int remainingSeconds;

  /// Whether the level objective (correct cut count AND resulting piece
  /// count) was satisfied. When `false`, [accuracy] is forced to 0 and
  /// [objectiveMessage] explains the failure.
  final bool objectiveMet;
  final String? objectiveMessage;
}
