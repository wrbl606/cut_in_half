import 'package:cut_in_half/models/cut_line.dart';
import 'package:cut_in_half/models/level_result.dart';
import 'package:cut_in_half/services/image_masker.dart';
import 'package:cut_in_half/services/splitter.dart';
import 'package:flutter_test/flutter_test.dart';

ImageMask _squareMask({int size = 100}) {
  final mask = List<bool>.filled(size * size, true);
  return ImageMask(
    width: size,
    height: size,
    mask: mask,
    totalArea: size * size,
    bboxMinX: 0.0,
    bboxMinY: 0.0,
    bboxMaxX: size > 1 ? 1.0 : 0.0,
    bboxMaxY: size > 1 ? 1.0 : 0.0,
  );
}

void main() {
  group('Splitter.split', () {
    test('single vertical cut splits a square into two equal halves', () {
      final mask = _squareMask(size: 100);
      final cuts = [
        _normLine(0.5, 0.0, 0.5, 1.0),
      ];
      final pieces = Splitter.split(mask, cuts);
      expect(pieces.length, 2);
      final total = pieces.fold<double>(0, (s, p) => s + p.percent);
      expect(total, closeTo(100, 0.01));
      for (final p in pieces) {
        expect(p.percent, closeTo(50, 0.5));
      }
    });

    test('two perpendicular cuts split a square into four equal pieces', () {
      final mask = _squareMask(size: 100);
      final cuts = [
        _normLine(0.5, 0.0, 0.5, 1.0),
        _normLine(0.0, 0.5, 1.0, 0.5),
      ];
      final pieces = Splitter.split(mask, cuts);
      expect(pieces.length, 4);
      for (final p in pieces) {
        expect(p.percent, closeTo(25, 0.5));
      }
    });

    test('no cuts → single piece covering the whole mask', () {
      final mask = _squareMask(size: 80);
      final pieces = Splitter.split(mask, const []);
      expect(pieces.length, 1);
      expect(pieces.first.percent, closeTo(100, 0.01));
      expect(pieces.first.area, 80 * 80);
    });

    test('diagonal cut on a square gives two triangular pieces', () {
      final mask = _squareMask(size: 100);
      final cuts = [
        _normLine(0.0, 0.0, 1.0, 1.0),
      ];
      final pieces = Splitter.split(mask, cuts);
      expect(pieces.length, 2);
      final total = pieces.fold<double>(0, (s, p) => s + p.percent);
      expect(total, closeTo(100, 0.01));
      // Both triangles should be roughly equal (≈50%).
      for (final p in pieces) {
        expect(p.percent, closeTo(50, 1.0));
      }
    });

    test('respects alpha shape — only non-transparent pixels counted', () {
      // Half-filled mask: left half transparent, right half filled.
      const size = 100;
      final maskArr = List<bool>.filled(size * size, false);
      for (var y = 0; y < size; y++) {
        for (var x = size ~/ 2; x < size; x++) {
          maskArr[y * size + x] = true;
        }
      }
      final mask = ImageMask(
        width: size,
        height: size,
        mask: maskArr,
        totalArea: size * size ~/ 2,
        bboxMinX: (size / 2 - 1) / (size - 1),
        bboxMinY: 0.0,
        bboxMaxX: 1.0,
        bboxMaxY: 1.0,
      );
      // Vertical cut at the middle of the filled half.
      final pieces = Splitter.split(mask, [_normLine(0.75, 0.0, 0.75, 1.0)]);
      expect(pieces.length, 2);
      for (final p in pieces) {
        expect(p.percent, closeTo(50, 1.0));
      }
    });
  });

  group('Splitter.accuracy', () {
    test('perfectly equal pieces → 100', () {
      final pieces = [
        _piece(25), _piece(25), _piece(25), _piece(25),
      ];
      expect(Splitter.accuracy(pieces), 100.0);
    });

    test('maximally uneven (one piece, rest empty) → 0', () {
      final pieces = [
        _piece(100), _piece(0), _piece(0), _piece(0),
      ];
      expect(Splitter.accuracy(pieces), lessThanOrEqualTo(0.1));
    });

    test('two pieces 60/40 → accuracy between 0 and 100', () {
      final pieces = [_piece(60), _piece(40)];
      final acc = Splitter.accuracy(pieces);
      // Ideal = 0.5 each; d1=d2=0.10; Σd=0.20; acc = 100*(1 - 2*0.20/2) = 80.
      expect(acc, closeTo(80, 0.01));
    });

    test('single piece (no cuts) → 0', () {
      expect(Splitter.accuracy([_piece(100)]), 0.0);
    });
  });

  group('Splitter.buildResult', () {
    test('points = round(accuracy)', () {
      final pieces = [_piece(60), _piece(40)];
      final result = Splitter.buildResult(
        levelId: 'test',
        cuts: const [],
        pieces: pieces,
        remainingSeconds: 10,
      );
      expect(result.points, result.accuracy.round());
      expect(result.remainingSeconds, 10);
      expect(result.levelId, 'test');
      expect(result.objectiveMet, isTrue);
      expect(result.objectiveMessage, isNull);
    });

    test('wrong number of pieces → 0% accuracy with reason', () {
      // Even split into 4 pieces, but the level expected only 2.
      final pieces = [_piece(25), _piece(25), _piece(25), _piece(25)];
      final cuts = [
        CutLine(id: 'a', x1: 0, y1: 0, x2: 1, y2: 1, locked: false, isInitial: false),
        CutLine(id: 'b', x1: 0, y1: 1, x2: 1, y2: 0, locked: false, isInitial: false),
        CutLine(id: 'c', x1: 0, y1: .5, x2: 1, y2: .5, locked: false, isInitial: false),
      ];
      final result = Splitter.buildResult(
        levelId: 'test',
        cuts: cuts,
        pieces: pieces,
        remainingSeconds: 5,
        requiredCuts: 3,
        targetPieces: 2,
      );
      expect(result.accuracy, 0.0);
      expect(result.points, 0);
      expect(result.objectiveMet, isFalse);
      expect(result.objectiveMessage, isNotNull);
      expect(result.objectiveMessage, contains('Produced 4 pieces'));
      expect(result.objectiveMessage, contains('instead of 2'));
    });

    test('wrong number of cuts → 0% accuracy with reason', () {
      final pieces = [_piece(50), _piece(50)];
      final cuts = [
        CutLine(id: 'a', x1: 0.5, y1: 0, x2: 0.5, y2: 1, locked: false, isInitial: false),
        CutLine(id: 'b', x1: 0, y1: 0.5, x2: 1, y2: 0.5, locked: false, isInitial: false),
      ];
      final result = Splitter.buildResult(
        levelId: 'test',
        cuts: cuts,
        pieces: pieces,
        remainingSeconds: 0,
        requiredCuts: 1,
        targetPieces: 2,
      );
      expect(result.accuracy, 0.0);
      expect(result.objectiveMet, isFalse);
      // Pieces match; only the cut count is wrong.
      expect(result.objectiveMessage, isNot(contains('Produced')));
      expect(result.objectiveMessage, contains('Made 2 cuts'));
      expect(result.objectiveMessage, contains('instead of 1'));
    });

    test('matching objective keeps computed accuracy', () {
      final pieces = [_piece(50), _piece(50)];
      final cuts = [
        CutLine(id: 'a', x1: 0.5, y1: 0, x2: 0.5, y2: 1, locked: false, isInitial: false),
      ];
      final result = Splitter.buildResult(
        levelId: 'test',
        cuts: cuts,
        pieces: pieces,
        remainingSeconds: 12,
        requiredCuts: 1,
        targetPieces: 2,
      );
      expect(result.objectiveMet, isTrue);
      expect(result.accuracy, closeTo(100, 0.01));
      expect(result.objectiveMessage, isNull);
    });
  });
}

// --- helpers ----------------------------------------------------------------

CutLine _normLine(double x1, double y1, double x2, double y2) {
  return CutLine(
    id: 'test',
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    locked: false,
    isInitial: false,
  );
}

PieceInfo _piece(double percent) {
  return PieceInfo(
    regionId: 0,
    area: percent.round(),
    percent: percent,
    bboxMinX: 0,
    bboxMinY: 0,
    bboxMaxX: 1,
    bboxMaxY: 1,
    maskWidth: 1,
    maskHeight: 1,
    mask: const [true],
  );
}
