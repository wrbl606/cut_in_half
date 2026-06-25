import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

import '../models/level_result.dart';

/// Renders the resulting pieces in a grid, each labeled with its percentage.
///
/// Each piece is cropped from the original asset's bounding box with alpha
/// zeroed outside the region mask, preserving art fidelity for arbitrary
/// shapes (including negative-space pieces).
class PieceGallery extends StatefulWidget {
  const PieceGallery({
    super.key,
    required this.assetPath,
    required this.pieces,
  });

  final String assetPath;
  final List<PieceInfo> pieces;

  @override
  State<PieceGallery> createState() => _PieceGalleryState();
}

class _PieceGalleryState extends State<PieceGallery> {
  List<_RenderedPiece>? _rendered;
  String? _error;

  @override
  void initState() {
    super.initState();
    _renderAll();
  }

  Future<void> _renderAll() async {
    try {
      final bytes =
          (await rootBundle.load(widget.assetPath)).buffer.asUint8List();
      final specs = widget.pieces
          .map((p) => _PieceSpec(
                bboxMinX: p.bboxMinX,
                bboxMinY: p.bboxMinY,
                bboxMaxX: p.bboxMaxX,
                bboxMaxY: p.bboxMaxY,
                maskWidth: p.maskWidth,
                maskHeight: p.maskHeight,
                mask: p.mask,
                percent: p.percent,
                regionId: p.regionId,
              ))
          .toList();
      final result = await compute(_renderPieces, _Payload(bytes, specs));
      if (!mounted) return;
      setState(() => _rendered = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Failed to render pieces:\n$_error'));
    }
    final rendered = _rendered;
    if (rendered == null) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeCap: StrokeCap.square),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = rendered.length <= 2
            ? rendered.length
            : rendered.length <= 4
                ? 2
                : 3;
        final clampedCount = crossAxisCount.clamp(1, 3);
        final rowCount =
            (rendered.length + clampedCount - 1) ~/ clampedCount;
        const border = BorderSide(color: Color(0xFF000000), width: 1);
        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: clampedCount,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
            childAspectRatio: 0.95,
          ),
          itemCount: rendered.length,
          itemBuilder: (context, i) {
            final r = rendered[i];
            final colIndex = i % clampedCount;
            final rowIndex = i ~/ clampedCount;
            final isLastCol = colIndex == clampedCount - 1;
            final isLastRow = rowIndex == rowCount - 1;
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  right: isLastCol ? BorderSide.none : border,
                  bottom: isLastRow ? BorderSide.none : border,
                ),
              ),
              child: _PieceTile(piece: r),
            );
          },
        );
      },
    );
  }
}

class _PieceTile extends StatelessWidget {
  const _PieceTile({required this.piece});
  final _RenderedPiece piece;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Image.memory(
                piece.pngBytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${piece.percent.toStringAsFixed(2)}%',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF000000),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Isolate payload / functions -------------------------------------------

class _Payload {
  _Payload(this.assetBytes, this.specs);
  final Uint8List assetBytes;
  final List<_PieceSpec> specs;
}

class _PieceSpec {
  _PieceSpec({
    required this.bboxMinX,
    required this.bboxMinY,
    required this.bboxMaxX,
    required this.bboxMaxY,
    required this.maskWidth,
    required this.maskHeight,
    required this.mask,
    required this.percent,
    required this.regionId,
  });
  final double bboxMinX;
  final double bboxMinY;
  final double bboxMaxX;
  final double bboxMaxY;
  final int maskWidth;
  final int maskHeight;
  final List<bool> mask;
  final double percent;
  final int regionId;
}

class _RenderedPiece {
  _RenderedPiece({
    required this.pngBytes,
    required this.percent,
    required this.regionId,
  });
  final Uint8List pngBytes;
  final double percent;
  final int regionId;
}

List<_RenderedPiece> _renderPieces(_Payload p) {
  final src = img.decodeImage(p.assetBytes);
  if (src == null) {
    throw StateError('Failed to decode source image for piece rendering');
  }
  final sw = src.width;
  final sh = src.height;
  final out = <_RenderedPiece>[];
  for (final spec in p.specs) {
    final cropX = (spec.bboxMinX * (sw - 1)).round().clamp(0, sw - 1);
    final cropY = (spec.bboxMinY * (sh - 1)).round().clamp(0, sh - 1);
    final cropX2 = (spec.bboxMaxX * (sw - 1)).round().clamp(0, sw - 1);
    final cropY2 = (spec.bboxMaxY * (sh - 1)).round().clamp(0, sh - 1);
    final cw = (cropX2 - cropX + 1).clamp(1, sw - cropX);
    final ch = (cropY2 - cropY + 1).clamp(1, sh - cropY);
    final cropped = img.copyCrop(src, x: cropX, y: cropY, width: cw, height: ch);
    // Apply the region mask by zeroing alpha where the mask is false.
    // Scale mask (maskWidth x maskHeight) up to (cw x ch) via nearest-neighbor.
    for (var y = 0; y < ch; y++) {
      final my = spec.maskHeight == 1
          ? 0
          : ((y * (spec.maskHeight - 1)) / (ch - 1)).round();
      for (var x = 0; x < cw; x++) {
        final mx = spec.maskWidth == 1
            ? 0
            : ((x * (spec.maskWidth - 1)) / (cw - 1)).round();
        if (!spec.mask[my * spec.maskWidth + mx]) {
          final px = cropped.getPixel(x, y);
          px..r = 0..g = 0..b = 0..a = 0;
        }
      }
    }
    final png = img.encodePng(cropped);
    out.add(_RenderedPiece(
      pngBytes: Uint8List.fromList(png),
      percent: spec.percent,
      regionId: spec.regionId,
    ));
  }
  return out;
}
