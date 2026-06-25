// Generates stub placeholder PNG images (~12 simple geometric shapes)
// into assets/images/. Run with: dart run tool/generate_images.dart
//
// Shapes are filled with a per-shape multicolor gradient ("sticker" look)
// outlined with a dark edge, on transparent padding. The transparent padding
// guarantees cut endpoints can sit outside the non-transparent region but
// inside the image display rect (per spec §2 validity rules). Only the alpha
// channel matters to the game logic — RGB is purely cosmetic.

// ignore_for_file: avoid_print, prefer_function_declarations_over_variables

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const int size = 400;
const int fillA = 255;

// Dark outline drawn just inside the shape edge, for the sticker look.
const int edgeR = 30;
const int edgeG = 28;
const int edgeB = 46;
const double edgeWidth = 1.5; // in normalized units of the image

typedef ShapeTest = bool Function(double nx, double ny);

// An (r,g,b) color.
class _Color {
  const _Color(this.r, this.g, this.b);
  final int r, g, b;
}

// Per-shape gradient stops. Each entry is a list of colors; pixels are
// filled along a diagonal (top-left → bottom-right) multi-stop gradient.
const Map<String, List<_Color>> palettes = <String, List<_Color>>{
  'circle':   [_Color(255, 99, 132),  _Color(255, 180, 92),  _Color(255, 233, 138)],
  'square':   [_Color(64, 123, 255),  _Color(129, 96, 240), _Color(206, 116, 224)],
  'triangle': [_Color(255, 154, 60),  _Color(255, 206, 86), _Color(255, 124, 86)],
  'star':     [_Color(255, 215, 0),   _Color(255, 132, 60), _Color(255, 86, 110)],
  'heart':    [_Color(255, 92, 138),  _Color(255, 158, 92), _Color(255, 110, 199)],
  'hexagon':  [_Color(46, 196, 182),  _Color(82, 183, 255), _Color(146, 122, 255)],
  'diamond':  [_Color(126, 232, 180),_Color(82, 183, 255),  _Color(255, 138, 222)],
  'cross':    [_Color(255, 86, 110),  _Color(255, 154, 60), _Color(255, 215, 0)],
  'crescent': [_Color(120, 134, 255), _Color(176, 122, 255),_Color(255, 138, 222)],
  'arrow':    [_Color(255, 92, 138),  _Color(255, 154, 60), _Color(255, 215, 0)],
  'pentagon': [_Color(46, 196, 182),  _Color(129, 222, 128),_Color(255, 215, 0)],
  'octagon':  [_Color(82, 183, 255),  _Color(129, 96, 240), _Color(255, 124, 180)],
};

void main() {
  final out = Directory('assets/images');
  if (!out.existsSync()) out.createSync(recursive: true);

  final shapes = <String, ShapeTest>{
    'circle': (nx, ny) {
      final dx = nx - 0.5, dy = ny - 0.5;
      return dx * dx + dy * dy <= 0.35 * 0.35;
    },
    'square': (nx, ny) {
      return (nx - 0.5).abs() <= 0.32 && (ny - 0.5).abs() <= 0.32;
    },
    'triangle': _triangle(),
    'star': _star(),
    'heart': _heart(),
    'hexagon': _regularPolygon(6, 0.36, -math.pi / 2),
    'diamond': (nx, ny) {
      return (nx - 0.5).abs() + (ny - 0.5).abs() <= 0.35;
    },
    'cross': (nx, ny) {
      final dx = (nx - 0.5).abs(), dy = (ny - 0.5).abs();
      return (dx <= 0.15 && dy <= 0.33) || (dx <= 0.33 && dy <= 0.15);
    },
    'crescent': _crescent(),
    'arrow': _arrow(),
    'pentagon': _regularPolygon(5, 0.36, -math.pi / 2),
    'octagon': _regularPolygon(8, 0.36, math.pi / 8),
  };

  for (final entry in shapes.entries) {
    final shape = entry.value;
    final palette = palettes[entry.key] ?? const [_Color(120, 120, 120)];
    final image = img.Image(width: size, height: size, numChannels: 4);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final nx = x / (size - 1);
        final ny = y / (size - 1);
        if (!shape(nx, ny)) continue;
        // Outline: if any neighbor just outside the shape is transparent,
        // this pixel is on the edge -> draw the dark outline color.
        final isEdge = _isEdgePixel(shape, nx, ny);
        late int r, g, b;
        if (isEdge) {
          r = edgeR; g = edgeG; b = edgeB;
        } else {
          final c = _gradient(palette, nx, ny);
          r = c.r; g = c.g; b = c.b;
        }
        image.setPixelRgba(x, y, r, g, b, fillA);
      }
    }
    final bytes = img.encodePng(image);
    final file = File('${out.path}/${entry.key}.png');
    file.writeAsBytesSync(bytes);
    print('Wrote ${file.path}');
  }
  print('Done: ${shapes.length} images.');
}

/// Top-left → bottom-right multi-stop gradient sampled at normalized (nx, ny).
_Color _gradient(List<_Color> stops, double nx, double ny) {
  if (stops.length == 1) return stops.first;
  final t = (nx + ny) / 2; // diagonal
  final seg = (t * (stops.length - 1)).clamp(0.0, (stops.length - 1).toDouble());
  final i = seg.floor();
  final f = seg - i;
  final a = stops[i];
  final b = stops[(i + 1).clamp(0, stops.length - 1)];
  return _Color(
    (a.r + (b.r - a.r) * f).round(),
    (a.g + (b.g - a.g) * f).round(),
    (a.b + (b.b - a.b) * f).round(),
  );
}

/// A pixel is on the outline if any of its 4-neighbors (at a
/// sub-pixel step of ~edgeWidth) falls outside the shape. This yields a
/// dark rim just inside the boundary — the classic sticker edge.
bool _isEdgePixel(ShapeTest shape, double nx, double ny) {
  const eps = edgeWidth / 400; // edgeWidth normalized units → [0,1]
  final around = <bool>[
    shape(nx - eps, ny),
    shape(nx + eps, ny),
    shape(nx, ny - eps),
    shape(nx, ny + eps),
  ];
  return around.any((v) => !v);
}

ShapeTest _triangle() {
  // Equilateral pointing up, centered at (0.5, 0.54).
  final verts = <_Pt>[
    _pt(0.5, 0.20),
    _pt(0.80, 0.76),
    _pt(0.20, 0.76),
  ];
  return (nx, ny) => _pointInPolygon(_pt(nx, ny), verts);
}

ShapeTest _star() {
  // 5-point star, outer radius 0.38, inner radius 0.16, centered.
  final verts = <_Pt>[];
  for (var i = 0; i < 10; i++) {
    final r = i.isEven ? 0.38 : 0.16;
    final a = -math.pi / 2 + i * math.pi / 5;
    verts.add(_pt(0.5 + r * math.cos(a), 0.5 + r * math.sin(a)));
  }
  return (nx, ny) => _pointInPolygon(_pt(nx, ny), verts);
}

ShapeTest _heart() {
  // Heart outline as a polygon (sampled parametrically).
  final verts = <_Pt>[];
  for (var t = 0.0; t < 2 * math.pi; t += 0.05) {
    final x = 16 * math.pow(math.sin(t), 3);
    final y = 13 * math.cos(t) -
        5 * math.cos(2 * t) -
        2 * math.cos(3 * t) -
        math.cos(4 * t);
    // Normalize: x ∈ [-16, 16], y ∈ [-17, 12] approx.
    final nx = 0.5 + (x / 40);
    final ny = 0.52 - (y / 40);
    verts.add(_pt(nx, ny));
  }
  return (nx, ny) => _pointInPolygon(_pt(nx, ny), verts);
}

ShapeTest _crescent() {
  // Moon: inside circle1 but outside circle2 (offset).
  final c1 = (nx, ny) {
    final dx = nx - 0.42, dy = ny - 0.5;
    return dx * dx + dy * dy <= 0.36 * 0.36;
  };
  final c2 = (nx, ny) {
    final dx = nx - 0.58, dy = ny - 0.5;
    return dx * dx + dy * dy <= 0.32 * 0.32;
  };
  return (nx, ny) => c1(nx, ny) && !c2(nx, ny);
}

ShapeTest _arrow() {
  // Right-pointing arrow.
  final verts = <_Pt>[
    _pt(0.18, 0.40),
    _pt(0.55, 0.40),
    _pt(0.55, 0.24),
    _pt(0.82, 0.50),
    _pt(0.55, 0.76),
    _pt(0.55, 0.60),
    _pt(0.18, 0.60),
  ];
  return (nx, ny) => _pointInPolygon(_pt(nx, ny), verts);
}

ShapeTest _regularPolygon(int n, double r, double rot) {
  final verts = <_Pt>[];
  for (var i = 0; i < n; i++) {
    final a = rot + i * 2 * math.pi / n;
    verts.add(_pt(0.5 + r * math.cos(a), 0.5 + r * math.sin(a)));
  }
  return (nx, ny) => _pointInPolygon(_pt(nx, ny), verts);
}

class _Pt {
  _Pt(this.x, this.y);
  final double x;
  final double y;
}

_Pt _pt(double x, double y) => _Pt(x, y);

bool _pointInPolygon(_Pt p, List<_Pt> verts) {
  var inside = false;
  for (var i = 0, j = verts.length - 1; i < verts.length; j = i++) {
    final xi = verts[i].x, yi = verts[i].y;
    final xj = verts[j].x, yj = verts[j].y;
    final intersect = ((yi > p.y) != (yj > p.y)) &&
        (p.x < (xj - xi) * (p.y - yi) / (yj - yi) + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}
