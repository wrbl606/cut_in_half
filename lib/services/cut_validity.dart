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
class CutValidity {
  /// Returns true iff [line] is a valid cut for the given [mask].
  static bool check(CutLine line, ImageMask mask) {
    if (mask.isEmpty) return false;

    // Endpoint test is now per-pixel: the endpoint must NOT be on an opaque
    // pixel. Using the mask directly (rather than its AABB) is what lets
    // endpoints live on internal transparent holes of the shape.
    final p1Transparent = _onTransparentPixel(line.x1, line.y1, mask);
    final p2Transparent = _onTransparentPixel(line.x2, line.y2, mask);
    if (!p1Transparent || !p2Transparent) return false;

    return _segmentIntersectsMask(line, mask);
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
}