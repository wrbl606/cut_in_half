import '../models/cut_line.dart';
import '../models/level_result.dart';
import 'image_masker.dart';

/// Pure functions that apply a sequence of cut lines to an alpha mask,
/// producing the resulting regions with areas and bounding boxes.
class Splitter {
  /// Splits [mask] by [cuts] (normalized [0,1]) into non-empty regions.
  /// Returns one [PieceInfo] per non-empty region, in stable order of
  /// appearance (top-to-bottom, then left-to-right by bbox).
  static List<PieceInfo> split(ImageMask mask, List<CutLine> cuts) {
    final mw = mask.width;
    final mh = mask.height;
    final size = mw * mh;

    if (mask.totalArea == 0) return const <PieceInfo>[];

    // regionBits[i] = bitmask of "right side" choices per cut.
    final regionBits = List<int>.filled(size, 0);

    for (var k = 0; k < cuts.length; k++) {
      final c = cuts[k];
      // Pre-compute line in mask pixel space.
      final px1 = c.x1 * (mw - 1);
      final py1 = c.y1 * (mh - 1);
      final px2 = c.x2 * (mw - 1);
      final py2 = c.y2 * (mh - 1);
      final dx = px2 - px1;
      final dy = py2 - py1;
      final bit = 1 << k;
      for (var y = 0; y < mh; y++) {
        final rowBase = y * mw;
        for (var x = 0; x < mw; x++) {
          if (!mask.mask[rowBase + x]) continue;
          // cross product: > 0 → right side, <= 0 → left side
          final cross = dx * (y - py1) - dy * (x - px1);
          if (cross > 0) {
            regionBits[rowBase + x] |= bit;
          }
        }
      }
    }

    // Group non-transparent pixels by regionBits value.
    final groups = <int, _RegionAcc>{};
    for (var y = 0; y < mh; y++) {
      final rowBase = y * mw;
      for (var x = 0; x < mw; x++) {
        final idx = rowBase + x;
        if (!mask.mask[idx]) continue;
        final key = regionBits[idx];
        final acc = groups[key] ??= _RegionAcc();
        acc.area++;
        if (x < acc.minX) acc.minX = x;
        if (y < acc.minY) acc.minY = y;
        if (x > acc.maxX) acc.maxX = x;
        if (y > acc.maxY) acc.maxY = y;
      }
    }

    final total = mask.totalArea;
    final pieces = <PieceInfo>[];
    var regionId = 0;
    // Stable order: sort by (minY, minX) so pieces appear top-to-bottom,
    // left-to-right.
    final sorted = groups.entries.toList()
      ..sort((a, b) {
        final r = a.value.minY.compareTo(b.value.minY);
        if (r != 0) return r;
        return a.value.minX.compareTo(b.value.minX);
      });

    for (final entry in sorted) {
      final acc = entry.value;
      final bw = acc.maxX - acc.minX + 1;
      final bh = acc.maxY - acc.minY + 1;
      final rmask = List<bool>.filled(bw * bh, false);
      final key = entry.key;
      for (var y = acc.minY; y <= acc.maxY; y++) {
        final rowBase = y * mw;
        for (var x = acc.minX; x <= acc.maxX; x++) {
          if (mask.mask[rowBase + x] && regionBits[rowBase + x] == key) {
            rmask[(y - acc.minY) * bw + (x - acc.minX)] = true;
          }
        }
      }
      final percent = (acc.area / total) * 100;
      pieces.add(PieceInfo(
        regionId: regionId++,
        area: acc.area,
        percent: percent,
        bboxMinX: mw > 1 ? acc.minX / (mw - 1) : 0.0,
        bboxMinY: mh > 1 ? acc.minY / (mh - 1) : 0.0,
        bboxMaxX: mw > 1 ? acc.maxX / (mw - 1) : 0.0,
        bboxMaxY: mh > 1 ? acc.maxY / (mh - 1) : 0.0,
        maskWidth: bw,
        maskHeight: bh,
        mask: rmask,
      ));
    }

    return pieces;
  }

  /// Computes accuracy per §6: 100 * (1 - N * Σ d_i / 2), clamped to [0, 100].
  /// No cuts (single piece) → 0%, since the image was never split.
  static double accuracy(List<PieceInfo> pieces) {
    final n = pieces.length;
    if (n <= 1) return 0.0;
    final ideal = 1.0 / n;
    var sumDev = 0.0;
    for (final p in pieces) {
      final share = p.percent / 100.0;
      sumDev += (share - ideal).abs();
    }
    final a = 100.0 * (1.0 - n * sumDev / 2.0);
    if (a < 0) return 0.0;
    if (a > 100) return 100.0;
    return a;
  }

  /// Builds a [LevelResult] given the final pieces and metadata.
  ///
  /// When [requiredCuts] and/or [targetPieces] are supplied, the result is
  /// checked against the level objective: if the number of cuts or the
  /// number of resulting pieces does not match, [LevelResult.accuracy] is
  /// forced to 0 and a human-readable reason is attached via
  /// [LevelResult.objectiveMessage].
  static LevelResult buildResult({
    required String levelId,
    required List<CutLine> cuts,
    required List<PieceInfo> pieces,
    required int remainingSeconds,
    int? requiredCuts,
    int? targetPieces,
  }) {
    final cutsOk = requiredCuts == null || cuts.length == requiredCuts;
    final piecesOk = targetPieces == null || pieces.length == targetPieces;
    final objectiveMet = cutsOk && piecesOk;
    final baseAcc = accuracy(pieces);
    final acc = objectiveMet ? baseAcc : 0.0;

    String? message;
    if (!objectiveMet) {
      final reasons = <String>[];
      if (!cutsOk) {
        reasons.add('Made ${cuts.length} cut${cuts.length == 1 ? "" : "s"} '
            'instead of $requiredCuts');
      }
      if (!piecesOk) {
        reasons.add('Produced ${pieces.length} piece${pieces.length == 1 ? "" : "s"} '
            'instead of $targetPieces');
      }
      message = reasons.join(' · ');
    }

    return LevelResult(
      levelId: levelId,
      cuts: List<CutLine>.unmodifiable(cuts),
      pieces: List<PieceInfo>.unmodifiable(pieces),
      accuracy: acc,
      points: acc.round(),
      remainingSeconds: remainingSeconds,
      objectiveMet: objectiveMet,
      objectiveMessage: message,
    );
  }
}

class _RegionAcc {
  int area = 0;
  int minX = 1 << 30;
  int minY = 1 << 30;
  int maxX = -1;
  int maxY = -1;
}
