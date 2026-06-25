import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/cut_line.dart';

/// A small, static rendering of an image with cut lines drawn on top,
/// used to compare attempts side-by-side. Cuts are drawn unmasked across
/// the full image display rect (BoxFit.contain), matching the placed-cut
/// visual style at miniature scale.
class MiniatureCut extends StatefulWidget {
  const MiniatureCut({
    super.key,
    required this.assetPath,
    required this.cuts,
    this.backgroundColor = const Color(0xFFF6F6F6),
  });

  final String assetPath;
  final List<CutLine> cuts;
  final Color backgroundColor;

  @override
  State<MiniatureCut> createState() => _MiniatureCutState();
}

class _MiniatureCutState extends State<MiniatureCut> {
  ui.Image? _image;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stream =
          AssetImage(widget.assetPath).resolve(const ImageConfiguration());
      final completer = Completer<ui.Image>();
      late final ImageStreamListener listener;
      listener = ImageStreamListener((info, _) {
        completer.complete(info.image.clone());
        stream.removeListener(listener);
      });
      stream.addListener(listener);
      final img = await completer.future;
      if (!mounted) {
        img.dispose();
        return;
      }
      setState(() {
        _image = img;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeCap: StrokeCap.square),
        ),
      );
    } else if (_error != null) {
      content = const Center(child: Icon(Icons.broken_image_outlined, size: 20));
    } else {
      content = LayoutBuilder(
        builder: (context, constraints) {
          final box = Size(constraints.maxWidth, constraints.maxHeight);
          final rect = _computeDisplayRect(box, _image!);
          return CustomPaint(
            size: Size.infinite,
            painter: _MiniPainter(
              image: _image!,
              displayRect: rect,
              cuts: widget.cuts,
            ),
          );
        },
      );
    }
    return ColoredBox(
      color: widget.backgroundColor,
      child: content,
    );
  }

  Rect _computeDisplayRect(Size canvas, ui.Image image) {
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    final scale = math.min(canvas.width / iw, canvas.height / ih);
    final dw = iw * scale;
    final dh = ih * scale;
    final left = (canvas.width - dw) / 2;
    final top = (canvas.height - dh) / 2;
    return Rect.fromLTWH(left, top, dw, dh);
  }
}

class _MiniPainter extends CustomPainter {
  _MiniPainter({
    required this.image,
    required this.displayRect,
    required this.cuts,
  });

  final ui.Image image;
  final Rect displayRect;
  final List<CutLine> cuts;

  @override
  void paint(ui.Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: displayRect,
      image: image,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.low,
    );

    for (final c in cuts) {
      final a = Offset(
        displayRect.left + c.x1 * displayRect.width,
        displayRect.top + c.y1 * displayRect.height,
      );
      final b = Offset(
        displayRect.left + c.x2 * displayRect.width,
        displayRect.top + c.y2 * displayRect.height,
      );
      // Scale the dash/gap down for the miniature.
      const dashLen = 3.0;
      const gapLen = 4.0;
      _drawDashedLine(
        canvas,
        a,
        b,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFFFFFFF),
        dashLen: dashLen,
        gapLen: gapLen,
      );
      _drawDashedLine(
        canvas,
        a,
        b,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF000000),
        dashLen: dashLen,
        gapLen: gapLen,
      );
      for (final pos in [a, b]) {
        canvas.drawCircle(pos, 2, Paint()..color = const Color(0xFF000000));
        canvas.drawCircle(pos, 1, Paint()..color = const Color(0xFFFFFFFF));
      }
    }
  }

  void _drawDashedLine(ui.Canvas canvas, Offset a, Offset b, Paint paint,
      {required double dashLen, required double gapLen}) {
    final d = b - a;
    final len = d.distance;
    if (len == 0) return;
    final ux = d.dx / len;
    final uy = d.dy / len;
    var t = 0.0;
    while (t < len) {
      final e = (t + dashLen < len) ? t + dashLen : len;
      canvas.drawLine(Offset(a.dx + ux * t, a.dy + uy * t),
          Offset(a.dx + ux * e, a.dy + uy * e), paint);
      t = e + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPainter old) =>
      old.image != image ||
      old.displayRect != displayRect ||
      old.cuts.length != cuts.length;
}