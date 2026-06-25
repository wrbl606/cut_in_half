import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

class ImageMask {
  ImageMask({
    required this.width,
    required this.height,
    required this.mask,
    required this.totalArea,
    required this.bboxMinX,
    required this.bboxMinY,
    required this.bboxMaxX,
    required this.bboxMaxY,
  });

  final int width;
  final int height;

  /// width*height, true when alpha > threshold.
  final List<bool> mask;

  /// Count of non-transparent pixels.
  final int totalArea;

  /// Non-transparent bounding box in normalized [0,1] coords.
  final double bboxMinX;
  final double bboxMinY;
  final double bboxMaxX;
  final double bboxMaxY;

  bool get isEmpty => totalArea == 0;

  bool pixelInside(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return mask[y * width + x];
  }

  /// Convert normalized [0,1] coords to mask pixel coords.
  int toPixelX(double nx) => (nx * (width - 1)).round().clamp(0, width - 1);
  int toPixelY(double ny) => (ny * (height - 1)).round().clamp(0, height - 1);
}

class _MaskPayload {
  _MaskPayload(this.data);
  final Uint8List data;
}

class ImageMasker {
  static const int alphaThreshold = 128;
  static const int sampleCap = 256;

  /// Loads the asset, decodes the PNG on a background isolate, and builds the
  /// alpha mask + non-transparent bounding box at sample scale.
  static Future<ImageMask> build(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final data = bytes.buffer.asUint8List();
    return compute(_decodeAndBuild, _MaskPayload(data));
  }

  static ImageMask _decodeAndBuild(_MaskPayload p) {
    final src = img.decodeImage(p.data);
    if (src == null) {
      throw StateError('Failed to decode image');
    }
    final sw = src.width;
    final sh = src.height;
    final longEdge = sw > sh ? sw : sh;
    var scale = 1.0;
    if (longEdge > sampleCap) {
      scale = sampleCap / longEdge;
    }
    final mw = (sw * scale).round().clamp(1, 1 << 20);
    final mh = (sh * scale).round().clamp(1, 1 << 20);

    final resized = img.copyResize(src, width: mw, height: mh);

    final mask = List<bool>.filled(mw * mh, false);
    var area = 0;
    var minX = mw;
    var minY = mh;
    var maxX = -1;
    var maxY = -1;

    for (var y = 0; y < mh; y++) {
      for (var x = 0; x < mw; x++) {
        final px = resized.getPixel(x, y);
        final a = px.a.toInt();
        final inside = a > alphaThreshold;
        mask[y * mw + x] = inside;
        if (inside) {
          area++;
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    double nxMin, nyMin, nxMax, nyMax;
    if (area == 0) {
      nxMin = nyMin = 0.0;
      nxMax = nyMax = 0.0;
    } else {
      nxMin = minX / (mw - 1);
      nyMin = minY / (mh - 1);
      nxMax = maxX / (mw - 1);
      nyMax = maxY / (mh - 1);
    }

    return ImageMask(
      width: mw,
      height: mh,
      mask: mask,
      totalArea: area,
      bboxMinX: nxMin,
      bboxMinY: nyMin,
      bboxMaxX: nxMax,
      bboxMaxY: nyMax,
    );
  }
}
