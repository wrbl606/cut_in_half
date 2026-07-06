import 'dart:math' as math;

import '../models/cut_line.dart';
import 'image_masker.dart';

/// Implements §2 validity rules for a cut line:
///   1. Both endpoints land on a **transparent** pixel of the image — i.e. a
///      pixel whose alpha is at/below the mask's transparency threshold. This
///      intentionally replaces the older "strictly outside the non-transparent
///      axis-aligned bounding box" rule so cut endpoints may sit on any
///      transparent pixel *anywhere* in the image — including negative space
///      / holes interior to the shape's AABB (crescents, donuts, letters,
///      stencils, etc.). Endpoints that fall outside the displayed image
///      rect are clamped to the image edge by the canvas; clamped edge pixels
///      are transparent for the bundled art, so they keep working as "padding."
///   2. The segment intersects the non-transparent region at least once.
///   3. The segment does not overlap any existing cut's segment in the same
///      [0,1] normalized coordinate space (crossing, endpoint-on-segment, and
///      full collinear overlaps are all rejected).
class CutValidity {
  /// Returns true iff [line] is a valid cut for the given [mask].
  static bool check(CutLine line, ImageMask mask) =>
      checkWith(line, mask, const <CutLine>[]);

  /// Returns true iff [line] is a valid cut for the given [mask], also
  /// rejecting it if its segment overlaps any cut in [existing]. The cut
  /// whose id matches [excludeId] (the one being moved) is skipped so a cut
  /// is never compared against its own pre-move position.
  static bool checkWith(
    CutLine line,
    ImageMask mask,
    Iterable<CutLine> existing, {
    String? excludeId,
  }) {
    if (mask.isEmpty) return false;

    // Endpoint test is now per-pixel: the endpoint must NOT be on an opaque
    // pixel. Using the mask directly (rather than its AABB) is what lets
    // endpoints live on internal transparent holes of the shape.
    final p1Transparent = _onTransparentPixel(line.x1, line.y1, mask);
    final p2Transparent = _onTransparentPixel(line.x2, line.y2, mask);
    if (!p1Transparent || !p2Transparent) return false;

    if (!_segmentIntersectsMask(line, mask)) return false;

    for (final c in existing) {
      if (excludeId != null && c.id == excludeId) continue;
      if (_segmentsOverlap(
        line.x1, line.y1, line.x2, line.y2,
        c.x1, c.y1, c.x2, c.y2,
      )) {
        return false;
      }
    }
    return true;
  }

  /// True iff the pixel under the normalized point (x, y) is transparent
  /// (i.e. the mask is `false` there). Coordinates outside the [0,1] range
  /// are clamped to the nearest edge pixel before lookup, matching the
  /// canvas's own coordinate normalization.
  static bool _onTransparentPixel(double x, double y, ImageMask mask) {
    final px = mask.toPixelX(x);
    final py = mask.toPixelY(y);
    // `pixelInside` returns true only when the pixel is opaque. An endpoint
    // outside the image bounds (letterbox taps that were clamped to the edge)
    // will resolve to an edge pixel — transparent for art with padding, so
    // those still count as valid "outside the shape" placements.
    return !mask.pixelInside(px, py);
  }

  /// Walks the segment at sub-pixel resolution and checks for any
  /// non-transparent pixel it passes through.
  static bool _segmentIntersectsMask(CutLine line, ImageMask mask) {
    final mw = mask.width;
    final mh = mask.height;
    final px1 = line.x1 * (mw - 1);
    final py1 = line.y1 * (mh - 1);
    final px2 = line.x2 * (mw - 1);
    final py2 = line.y2 * (mh - 1);
    final dx = px2 - px1;
    final dy = py2 - py1;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return false;
    final len = math.sqrt(lenSq);
    final steps = (len * 2).ceil(); // half-pixel sampling
    if (steps == 0) return false;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = (px1 + t * dx).round();
      final y = (py1 + t * dy).round();
      if (x >= 0 && x < mw && y >= 0 && y < mh && mask.mask[y * mw + x]) {
        return true;
      }
    }
    return false;
  }

  /// Returns true iff the two [0,1]-normalized segments share any point.
  /// Covers the three overlap categories required by TASK-5:
  ///   * proper crossing (non-parallel segments that intersect)
  ///   * endpoint-on-segment (a shared or interior endpoint)
  ///   * collinear overlap (segments on the same line, partial or full)
  static bool _segmentsOverlap(
    double x1, double y1, double x2, double y2, // segment A
    double x3, double y3, double x4, double y4, // segment B
  ) {
    // Treat a zero-length "segment" as a single point; degenerate cuts are
    // not user-drawable but we still answer deterministically.
    final dx1 = x2 - x1, dy1 = y2 - y1;
    final dx2 = x4 - x3, dy2 = y4 - y3;
    final len1Sq = dx1 * dx1 + dy1 * dy1;
    final len2Sq = dx2 * dx2 + dy2 * dy2;

    // Endpoints-on-other-segment handles shared endpoint, T-junction, and the
    // case where a degenerate point lies on the other segment.
    if (len1Sq > 0 &&
        (_pointOnSegment(x1, y1, x3, y3, x4, y4) ||
            _pointOnSegment(x2, y2, x3, y3, x4, y4))) {
      return true;
    }
    if (len2Sq > 0 &&
        (_pointOnSegment(x3, y3, x1, y1, x2, y2) ||
            _pointOnSegment(x4, y4, x1, y1, x2, y2))) {
      return true;
    }
    if (len1Sq == 0 || len2Sq == 0) return false;

    // Orientation tests for a proper crossing via the standard sign-of-cross
    // product method. d1/d2 are the per-segment divisor doubles.
    final d1 = _orient(x3, y3, x4, y4, x1, y1);
    final d2 = _orient(x3, y3, x4, y4, x2, y2);
    final d3 = _orient(x1, y1, x2, y2, x3, y3);
    final d4 = _orient(x1, y1, x2, y2, x4, y4);

    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
      return true;
    }

    // Collinear (all four orientations ~0): project both segments onto the
    // dominant axis and test for an overlapping interval.
    if (d1 == 0 && d2 == 0 && d3 == 0 && d4 == 0) {
      return _collinearOverlap(
          x1, y1, x2, y2, x3, y3, x4, y4, dx1, dy1, dx2, dy2);
    }
    return false;
  }

  /// Signed area * 2 of triangle (a, b, c); 0 means collinear. We use exact
  /// integer-style comparison on floats — endpoints come from normalized
  /// coordinates that are kept short (no transcendental math), so exact
  /// equality against 0 is appropriate here.
  static double _orient(
      double ax, double ay, double bx, double by, double cx, double cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
  }

  /// True iff point (px, py) lies on the closed segment (a, b).
  static bool _pointOnSegment(
      double px, double py, double ax, double ay, double bx, double by) {
    final cross = (bx - ax) * (py - ay) - (by - ay) * (px - ax);
    if (cross != 0) return false;
    // On the infinite line — now check within the segment's bounding box.
    final minX = math.min(ax, bx), maxX = math.max(ax, bx);
    final minY = math.min(ay, by), maxY = math.max(ay, by);
    return px >= minX && px <= maxX && py >= minY && py <= maxY;
  }

  /// Both segments are known collinear; return true iff their projections
  /// on the dominant axis overlap (covers partial and full overlaps).
  static bool _collinearOverlap(
    double x1, double y1, double x2, double y2,
    double x3, double y3, double x4, double y4,
    double dx1, double dy1, double dx2, double dy2,
  ) {
    // Project each endpoint onto the other segment's parameter t in [0, 1].
    // If either segment's parameter range overlaps [0, 1], the segments
    // share at least one point.
    final len1Sq = dx1 * dx1 + dy1 * dy1;
    final len2Sq = dx2 * dx2 + dy2 * dy2;
    // Parameter of (x3,y3) and (x4,y4) along segment A.
    final t3 = (dx1 * (x3 - x1) + dy1 * (y3 - y1)) / len1Sq;
    final t4 = (dx1 * (x4 - x1) + dy1 * (y4 - y1)) / len1Sq;
    final aMin = math.min(t3, t4), aMax = math.max(t3, t4);
    if (aMax >= 0 && aMin <= 1) return true;
    // Parameter of (x1,y1) and (x2,y2) along segment B.
    final t1 = (dx2 * (x1 - x3) + dy2 * (y1 - y3)) / len2Sq;
    final t2 = (dx2 * (x2 - x3) + dy2 * (y2 - y3)) / len2Sq;
    final bMin = math.min(t1, t2), bMax = math.max(t1, t2);
    return bMax >= 0 && bMin <= 1;
  }
}