import 'package:cut_in_half/models/cut_line.dart';
import 'package:cut_in_half/services/cut_validity.dart';
import 'package:cut_in_half/services/image_masker.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mask with a centered filled square: bbox [0.25, 0.25] - [0.75, 0.75].
ImageMask _centeredSquareMask({int size = 100}) {
  final arr = List<bool>.filled(size * size, false);
  final min = size ~/ 4;
  final max = (3 * size) ~/ 4;
  for (var y = min; y < max; y++) {
    for (var x = min; x < max; x++) {
      arr[y * size + x] = true;
    }
  }
  return ImageMask(
    width: size,
    height: size,
    mask: arr,
    totalArea: (max - min) * (max - min),
    bboxMinX: min / (size - 1),
    bboxMinY: min / (size - 1),
    bboxMaxX: (max - 1) / (size - 1),
    bboxMaxY: (max - 1) / (size - 1),
  );
}

CutLine _line(double x1, double y1, double x2, double y2) {
  return CutLine(
    id: 't',
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    locked: false,
    isInitial: false,
  );
}

/// Mask shaped like a thick ring (filled outer square with a centered
/// transparent hole): opaque pixels form a frame. The hole is INSIDE the
/// non-transparent AABB but transparent — the case the per-pixel rule is
/// meant to allow endpoints on.
ImageMask _ringMask({int size = 100, int holeHalf = 10}) {
  final arr = List<bool>.filled(size * size, false);
  final min = size ~/ 4;
  final max = (3 * size) ~/ 4;
  final cx = size ~/ 2;
  final cy = size ~/ 2;
  var area = 0;
  for (var y = min; y < max; y++) {
    for (var x = min; x < max; x++) {
      final insideHole =
          (x - cx).abs() <= holeHalf && (y - cy).abs() <= holeHalf;
      if (!insideHole) {
        arr[y * size + x] = true;
        area++;
      }
    }
  }
  return ImageMask(
    width: size,
    height: size,
    mask: arr,
    totalArea: area,
    bboxMinX: min / (size - 1),
    bboxMinY: min / (size - 1),
    bboxMaxX: (max - 1) / (size - 1),
    bboxMaxY: (max - 1) / (size - 1),
  );
}

void main() {
  group('CutValidity.check', () {
    test('valid cut: endpoints outside bbox, segment crosses the shape', () {
      final mask = _centeredSquareMask();
      // Vertical cut through the middle, endpoints in the padding area.
      final line = _line(0.5, 0.0, 0.5, 1.0);
      expect(CutValidity.check(line, mask), isTrue);
    });

    test('invalid: endpoint inside the bbox', () {
      final mask = _centeredSquareMask();
      // Start point at center (inside bbox), end outside.
      final line = _line(0.5, 0.5, 0.5, 1.0);
      expect(CutValidity.check(line, mask), isFalse);
    });

    test('invalid: both endpoints inside the bbox', () {
      final mask = _centeredSquareMask();
      final line = _line(0.3, 0.3, 0.7, 0.7);
      expect(CutValidity.check(line, mask), isFalse);
    });

    test('invalid: segment does not intersect the shape', () {
      final mask = _centeredSquareMask();
      // Horizontal line in the top padding, outside the bbox entirely.
      final line = _line(0.0, 0.05, 1.0, 0.05);
      expect(CutValidity.check(line, mask), isFalse);
    });

    test('valid: cut grazes the corner of the shape', () {
      final mask = _centeredSquareMask();
      // Diagonal that passes through the top-left corner area of the bbox.
      final line = _line(0.0, 0.0, 1.0, 1.0);
      expect(CutValidity.check(line, mask), isTrue);
    });

    test('invalid: empty mask rejects all cuts', () {
      final mask = ImageMask(
        width: 10,
        height: 10,
        mask: List<bool>.filled(100, false),
        totalArea: 0,
        bboxMinX: 0,
        bboxMinY: 0,
        bboxMaxX: 0,
        bboxMaxY: 0,
      );
      expect(CutValidity.check(_line(0, 0, 1, 1), mask), isFalse);
    });

    // The per-pixel rule's whole point: endpoints may sit on transparent
    // pixels INSIDE the shape's non-transparent AABB (negative space / holes).
    group('per-pixel (negative space) rule', () {
      test('valid: both endpoints in transparent hole inside the AABB', () {
        final mask = _ringMask();
        // Cross the ring through the central hole; endpoints sit on transparent
        // pixels that are *inside* the ring's non-transparent bbox.
        final line = _line(0.5, 0.05, 0.5, 0.95);
        expect(CutValidity.check(line, mask), isTrue);
      });

      test('valid: endpoint in internal hole + endpoint in outer padding', () {
        final mask = _ringMask();
        final line = _line(0.5, 0.5, 0.05, 0.5);
        expect(CutValidity.check(line, mask), isTrue);
      });

      test('invalid: endpoint on an opaque pixel inside the AABB', () {
        final mask = _ringMask();
        // (0.30, 0.30) lands on the ring frame (opaque), still inside the AABB.
        final line = _line(0.30, 0.30, 0.05, 0.5);
        expect(CutValidity.check(line, mask), isFalse);
      });

      test('invalid: segment skips the shape entirely (cross-hole only)', () {
        final mask = _ringMask();
        // Both endpoints inside the hole, segment stays within the hole.
        final line = _line(0.45, 0.5, 0.55, 0.5);
        expect(CutValidity.check(line, mask), isFalse);
      });
    });
  });
}
