import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/cut_line.dart';
import '../services/cut_validity.dart';
import '../services/image_masker.dart';

/// The interactive surface where the player draws and edits cuts.
///
/// Cuts are stored in normalized [0,1] coordinates against the image's
/// on-screen display rect (the rect produced by `BoxFit.contain`).
class CutCanvas extends StatefulWidget {
  const CutCanvas({
    super.key,
    required this.assetPath,
    required this.initialCuts,
    required this.targetPieces,
    required this.onCutsChanged,
    required this.onReady,
    this.onDragChanged,
    this.gameplayActive = false,
    this.hintDelay = const Duration(seconds: 15),
    this.hintDiagonal = false,
  });

  final String assetPath;
  final List<CutLine> initialCuts;
  final int targetPieces;
  final ValueChanged<List<CutLine>> onCutsChanged;
  final ValueChanged<ImageMask> onReady;

  /// Notified with `true` when the user starts dragging (a new cut or a
  /// handle move) and `false` when the drag ends. Used by hosts to suppress
  /// accidental back navigation while drawing.
  final ValueChanged<bool>? onDragChanged;

  /// Whether the player currently has control of the canvas (i.e. the
  /// pre-round countdown has finished). While inactive the inactivity hint
  /// is suppressed and its idle timer does not run.
  final bool gameplayActive;

  /// How long the canvas must be idle before the gesture guide animates.
  /// Defaults to the inactivity hint delay; the onboarding screen uses a
  /// shorter delay for its deliberate tutorial sweep.
  final Duration hintDelay;

  /// Whether the gesture guide sweeps diagonally from the bottom-left of
  /// the shape to the top-right (onboarding tutorial) instead of the
  /// default horizontal sweep.
  final bool hintDiagonal;

  @override
  State<CutCanvas> createState() => _CutCanvasState();
}

class _CutCanvasState extends State<CutCanvas>
    with TickerProviderStateMixin {
  late final AnimationController _shake;
  late final AnimationController _hint;
  ui.Image? _image;
  ImageMask? _mask;
  bool _loading = true;
  String? _error;

  final List<CutLine> _cuts = <CutLine>[];
  String? _selectedId;
  int _nextId = 0;

  _DragKind _dragKind = _DragKind.none;
  String? _dragCutId;
  _HandleKind _dragHandle = _HandleKind.none;
  Offset? _dragStart;
  Offset? _dragCurrent;
  CutLine? _dragOriginal;
  bool _liveInvalid = false;

  Rect? _displayRect;

  // --- Inactivity hint ------------------------------------------------------
  // After [widget.hintDelay] with no interaction (and no player-drawn cut
  // yet), an instructional swipe gesture is animated across the shape to
  // teach the core action. It loops until the player touches the canvas.
  bool _gameplayActive = false;
  bool _showHint = false;
  bool _hintConsumed = false;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _hint = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _gameplayActive = widget.gameplayActive;
    for (final c in widget.initialCuts) {
      _cuts.add(c.copyWith());
    }
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant CutCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gameplayActive != oldWidget.gameplayActive) {
      _gameplayActive = widget.gameplayActive;
      _updateIdleTimer();
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _shake.dispose();
    _hint.dispose();
    _image?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final maskFuture = ImageMasker.build(widget.assetPath);
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
      final mask = await maskFuture;
      if (!mounted) {
        img.dispose();
        return;
      }
      setState(() {
        _image = img;
        _mask = mask;
        _loading = false;
      });
      _notifyCuts();
      widget.onReady(mask);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _notifyCuts() => widget.onCutsChanged(List<CutLine>.of(_cuts));

  void _notifyDrag(bool active) => widget.onDragChanged?.call(active);

  // --- Inactivity hint ------------------------------------------------------

  bool get _hintEligible =>
      _gameplayActive && !_hintConsumed && _requiredCuts > 0;

  /// (Re)arms the idle timer when eligible, otherwise cancels it.
  void _updateIdleTimer() {
    if (_hintEligible && !_showHint) {
      _idleTimer ??= Timer(widget.hintDelay, _onIdle);
    } else {
      _idleTimer?.cancel();
      _idleTimer = null;
    }
  }

  void _onIdle() {
    _idleTimer = null;
    if (!mounted || !_hintEligible) return;
    setState(() => _showHint = true);
    _hint.reset();
    _hint.repeat();
  }

  /// Called on any user gesture: hides a playing hint and restarts the
  /// idle countdown.
  void _resetIdle() {
    if (_showHint) {
      _hint.stop();
      setState(() => _showHint = false);
    }
    _idleTimer?.cancel();
    _idleTimer = null;
    _updateIdleTimer();
  }

  /// Permanently disables the hint once the player has drawn a cut.
  void _consumeHint() {
    _hintConsumed = true;
    _idleTimer?.cancel();
    _idleTimer = null;
    if (_showHint) {
      _hint.stop();
      _showHint = false;
    }
  }

  int get _requiredCuts => widget.targetPieces - 1;

  CutLine? _findCut(String? id) {
    if (id == null) return null;
    for (final c in _cuts) {
      if (c.id == id) return c;
    }
    return null;
  }

  bool _isDeletable(CutLine? c) => c != null && c.isPlayerDrawn;

  String _newId() => 'player_${_nextId++}';

  double _toNormX(double px) {
    final r = _displayRect!;
    if (r.width == 0) return 0;
    return ((px - r.left) / r.width).clamp(0.0, 1.0);
  }

  double _toNormY(double py) {
    final r = _displayRect!;
    if (r.height == 0) return 0;
    return ((py - r.top) / r.height).clamp(0.0, 1.0);
  }

  Offset _toCanvas(Offset norm) {
    final r = _displayRect!;
    return Offset(r.left + norm.dx * r.width, r.top + norm.dy * r.height);
  }

  static const double _handleRadius = 22.0;
  static const double _deleteHandleRadius = 16.0;
  static const double _bodyHitRadius = 24.0;
  static const double _deleteOffset = 40.0;
  static const double _tapSlop = 8.0;

  Offset _deleteHandlePos(CutLine c) {
    final a = _toCanvas(Offset(c.x1, c.y1));
    final b = _toCanvas(Offset(c.x2, c.y2));
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return Offset(mid.dx, mid.dy - _deleteOffset);
    final px = -dy / len;
    final py = dx / len;
    return Offset(mid.dx + px * _deleteOffset, mid.dy + py * _deleteOffset);
  }

  _HitTest _hitTest(Offset pos) {
    if (_displayRect == null) return _HitTest.empty();
    final sel = _findCut(_selectedId);
    if (sel != null && _isDeletable(sel)) {
      final dp = _deleteHandlePos(sel);
      if ((pos - dp).distance <= _deleteHandleRadius) {
        return _HitTest.delete(sel.id);
      }
    }
    if (sel != null && !sel.locked) {
      final a = _toCanvas(Offset(sel.x1, sel.y1));
      final b = _toCanvas(Offset(sel.x2, sel.y2));
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      if ((pos - a).distance <= _handleRadius) {
        return _HitTest.cut(sel.id, _HandleKind.endpoint1);
      }
      if ((pos - b).distance <= _handleRadius) {
        return _HitTest.cut(sel.id, _HandleKind.endpoint2);
      }
      if ((pos - mid).distance <= _handleRadius) {
        return _HitTest.cut(sel.id, _HandleKind.body);
      }
    }
    // Check ALL non-locked cuts for endpoint hits and body hits.
    // This lets the user grab an endpoint of any cut directly — the cut
    // auto-selects on drag start.
    for (var i = _cuts.length - 1; i >= 0; i--) {
      final c = _cuts[i];
      if (c.locked) continue;
      final a = _toCanvas(Offset(c.x1, c.y1));
      final b = _toCanvas(Offset(c.x2, c.y2));
      // Endpoint hit (larger radius for easier grabbing).
      if ((pos - a).distance <= _handleRadius) {
        return _HitTest.cut(c.id, _HandleKind.endpoint1);
      }
      if ((pos - b).distance <= _handleRadius) {
        return _HitTest.cut(c.id, _HandleKind.endpoint2);
      }
      // Body hit.
      if (_distancePointToSegment(pos, a, b) <= _bodyHitRadius) {
        return _HitTest.cut(c.id, _HandleKind.body);
      }
    }
    return _HitTest.empty();
  }

  double _distancePointToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final abLen2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLen2 == 0) return (p - a).distance;
    final t = (ap.dx * ab.dx + ap.dy * ab.dy) / abLen2;
    final tc = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + tc * ab.dx, a.dy + tc * ab.dy);
    return (p - proj).distance;
  }

  Offset _localize(Offset global) {
    final box = context.findRenderObject() as RenderBox;
    return box.globalToLocal(global);
  }

  void _onTapDown(Offset globalPos) {
    _resetIdle();
    _dragStart = _localize(globalPos);
    _dragCurrent = _dragStart;
  }

  void _onTapUp(Offset globalPos) {
    final pos = _localize(globalPos);
    final start = _dragStart;
    _dragStart = null;
    _dragCurrent = null;
    if (start == null) return;
    if ((pos - start).distance > _tapSlop) return;
    final hit = _hitTest(pos);
    if (hit.kind == _HitKind.delete) {
      _deleteCut(hit.cutId);
      return;
    }
    if (hit.kind == _HitKind.cut && hit.cutId != _selectedId) {
      setState(() => _selectedId = hit.cutId);
      return;
    }
    if (_selectedId != null) {
      setState(() => _selectedId = null);
    }
  }

  void _onPanStart(Offset globalPos) {
    _resetIdle();
    final start = _dragStart;
    if (start == null) {
      _dragStart = _localize(globalPos);
      _dragCurrent = _dragStart;
    } else {
      _dragCurrent = start;
    }
    final hit = _hitTest(start ?? _dragCurrent!);
    if (hit.kind == _HitKind.cut && hit.handle != _HandleKind.none) {
      _dragKind = _DragKind.moveHandle;
      _dragCutId = hit.cutId;
      _dragHandle = hit.handle;
      _dragOriginal = _findCut(hit.cutId)?.copyWith();
      _selectedId = hit.cutId;
    } else {
      _dragKind = _DragKind.newCut;
    }
    _notifyDrag(true);
  }

  void _onPanUpdate(Offset globalPos) {
    _dragCurrent = _localize(globalPos);
    if (_dragKind == _DragKind.moveHandle) {
      _applyDragToCut();
    }
    setState(() {});
  }

  void _onPanEnd() {
    if (_dragKind == _DragKind.moveHandle) {
      _commitMove();
    } else if (_dragKind == _DragKind.newCut) {
      final start = _dragStart;
      final end = _dragCurrent;
      if (start != null && end != null) {
        _commitNewCut(start, end);
      }
    }
    _resetDrag();
  }

  void _applyDragToCut() {
    final cut = _findCut(_dragCutId);
    final original = _dragOriginal;
    final start = _dragStart;
    final current = _dragCurrent;
    if (cut == null || original == null || start == null || current == null) {
      return;
    }
    final rect = _displayRect!;
    final dxNorm = (current.dx - start.dx) / rect.width;
    final dyNorm = (current.dy - start.dy) / rect.height;
    if (_dragHandle == _HandleKind.body) {
      cut.x1 = original.x1 + dxNorm;
      cut.y1 = original.y1 + dyNorm;
      cut.x2 = original.x2 + dxNorm;
      cut.y2 = original.y2 + dyNorm;
    } else if (_dragHandle == _HandleKind.endpoint1) {
      cut.x1 = original.x1 + dxNorm;
      cut.y1 = original.y1 + dyNorm;
    } else if (_dragHandle == _HandleKind.endpoint2) {
      cut.x2 = original.x2 + dxNorm;
      cut.y2 = original.y2 + dyNorm;
    }
    final mask = _mask;
    _liveInvalid = mask == null ? true : !CutValidity.check(cut, mask);
  }

  void _commitNewCut(Offset start, Offset end) {
    final mask = _mask;
    if (mask == null) return;
    if (_cuts.length >= _requiredCuts) {
      _triggerShake();
      return;
    }
    final line = CutLine(
      id: _newId(),
      x1: _toNormX(start.dx),
      y1: _toNormY(start.dy),
      x2: _toNormX(end.dx),
      y2: _toNormY(end.dy),
      locked: false,
      isInitial: false,
    );
    if (!CutValidity.check(line, mask)) {
      _triggerShake();
      return;
    }
    setState(() {
      _cuts.add(line);
      _selectedId = line.id;
    });
    _consumeHint();
    _notifyCuts();
  }

  void _commitMove() {
    final mask = _mask;
    final cut = _findCut(_dragCutId);
    final original = _dragOriginal;
    if (mask == null || cut == null || original == null) return;
    if (!CutValidity.check(cut, mask)) {
      cut.x1 = original.x1;
      cut.y1 = original.y1;
      cut.x2 = original.x2;
      cut.y2 = original.y2;
      _triggerShake();
    }
    setState(() {});
    _notifyCuts();
  }

  void _deleteCut(String? id) {
    if (id == null) return;
    final cut = _findCut(id);
    if (cut == null || !_isDeletable(cut)) return;
    setState(() {
      _cuts.removeWhere((c) => c.id == id);
      _selectedId = null;
    });
    _notifyCuts();
  }

  void _resetDrag() {
    _dragKind = _DragKind.none;
    _dragCutId = null;
    _dragHandle = _HandleKind.none;
    _dragStart = null;
    _dragCurrent = null;
    _dragOriginal = null;
    _liveInvalid = false;
    _notifyDrag(false);
    setState(() {});
  }

  void _triggerShake() => _shake.forward(from: 0.0);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeCap: StrokeCap.square),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Failed to load image:\n$_error',
              textAlign: TextAlign.center),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        _displayRect = _computeDisplayRect(
          Size(constraints.maxWidth, constraints.maxHeight),
          _image!,
        );
        final sel = _findCut(_selectedId);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _onTapDown(d.globalPosition),
          onTapUp: (d) => _onTapUp(d.globalPosition),
          onPanStart: (d) => _onPanStart(d.globalPosition),
          onPanUpdate: (d) => _onPanUpdate(d.globalPosition),
          onPanEnd: (_) => _onPanEnd(),
          child: AnimatedBuilder(
            animation: Listenable.merge([_shake, _hint]),
            builder: (context, _) {
              final t = _shake.value;
              final dx =
                  t == 0 ? 0.0 : math.sin(t * math.pi * 6) * 8 * (1 - t);
              return Transform.translate(
                offset: Offset(dx, 0),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _CutPainter(
                      image: _image!,
                      mask: _mask!,
                      cuts: _cuts,
                      selectedId: _selectedId,
                      displayRect: _displayRect!,
                      dragKind: _dragKind,
                      dragStart: _dragStart,
                      dragCurrent: _dragCurrent,
                      liveInvalid: _liveInvalid,
                      deleteHandlePos: sel != null && _isDeletable(sel)
                          ? _deleteHandlePos(sel)
                          : null,
                      showHint: _showHint,
                      hintValue: _hint.value,
                      hintDiagonal: widget.hintDiagonal,
                    ),
                  ),
              );
            },
          ),
        );
      },
    );
  }

  /// Computes the image display rect using BoxFit.contain within the canvas.
  /// No extra margin — the PNGs already have transparent padding around the
  /// shape, so the transparent image corners provide space for endpoints.
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

// --- Painter ----------------------------------------------------------------

class _CutPainter extends CustomPainter {
  _CutPainter({
    required this.image,
    required this.mask,
    required this.cuts,
    required this.selectedId,
    required this.displayRect,
    required this.dragKind,
    required this.dragStart,
    required this.dragCurrent,
    required this.liveInvalid,
    required this.deleteHandlePos,
    required this.showHint,
    required this.hintValue,
    this.hintDiagonal = false,
  });

  final ui.Image image;
  final ImageMask mask;
  final List<CutLine> cuts;
  final String? selectedId;
  final Rect displayRect;
  final _DragKind dragKind;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final bool liveInvalid;
  final Offset? deleteHandlePos;
  final bool showHint;
  final double hintValue;
  final bool hintDiagonal;

  Rect get bbox => Rect.fromLTRB(
        displayRect.left + mask.bboxMinX * displayRect.width,
        displayRect.top + mask.bboxMinY * displayRect.height,
        displayRect.left + mask.bboxMaxX * displayRect.width,
        displayRect.top + mask.bboxMaxY * displayRect.height,
      );

  @override
  void paint(ui.Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
        0, 0, image.width.toDouble(), image.height.toDouble());

    // 1. Paint the image directly — transparent areas are truly transparent,
    //    showing the white canvas behind. No background fill, no border.
    //    The shape floats on white and is the clear center of attention.
    paintImage(
      canvas: canvas,
      rect: displayRect,
      image: image,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
    );

    // 2. Draw all cut lines and the live drag preview in a separate layer,
    //    then mask that layer with the image's alpha channel. This makes cut
    //    lines appear ONLY on the non-transparent shape — not in transparent
    //    corners of the bounding box, not on the white canvas around it.
    canvas.saveLayer(displayRect, Paint());
    for (final c in cuts) {
      final a = Offset(
        displayRect.left + c.x1 * displayRect.width,
        displayRect.top + c.y1 * displayRect.height,
      );
      final b = Offset(
        displayRect.left + c.x2 * displayRect.width,
        displayRect.top + c.y2 * displayRect.height,
      );
      // All cuts: dashed white border + black interior per dash, so each
      // dash reads as a white capsule with a black core and stays visible
      // against both the shape and the white app background.
      _drawDashedLine(
        canvas,
        a,
        b,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12.0
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFFFFFFF),
      );
      _drawDashedLine(
        canvas,
        a,
        b,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF000000),
      );
    }

    // Live drag preview is drawn below in the unmasked section so it stays
    // visible across the full span (including off-shape areas), matching the
    // appearance of a placed cut.

    // Mask the entire layer with the image's alpha: only keep pixels where
    // the image is non-transparent. Cut lines now appear only on the shape.
    canvas.drawImageRect(
      image,
      src,
      displayRect,
      Paint()..blendMode = BlendMode.dstIn,
    );
    canvas.restore();

    // 3. Draw faint guide lines across the full cut span (visible in the
    //    transparent areas outside the shape) and endpoint markers. These
    //    are NOT masked — they need to be visible in the white space.
    for (final c in cuts) {
      final a = Offset(
        displayRect.left + c.x1 * displayRect.width,
        displayRect.top + c.y1 * displayRect.height,
      );
      final b = Offset(
        displayRect.left + c.x2 * displayRect.width,
        displayRect.top + c.y2 * displayRect.height,
      );
      // Full-span guide line with the same dashed white border + black
      // interior as the on-shape cut, so the line looks identical whether
      // or not it's drawn over the image.
      _drawDashedLine(
        canvas,
        a,
        b,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12.0
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFFFFFFF),
      );
      _drawDashedLine(
        canvas,
        a,
        b,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF000000),
      );
      // Endpoint dots — visible markers at each cut endpoint.
      for (final pos in [a, b]) {
        canvas.drawCircle(pos, 6, Paint()..color = const Color(0xFF000000));
        canvas.drawCircle(pos, 3, Paint()..color = const Color(0xFFFFFFFF));
      }
    }

    // Live drag preview — drawn unmasked so it stays visible across the full
    // span (including off-shape areas), matching the placed-cut appearance.
    if (dragKind == _DragKind.newCut &&
        dragStart != null &&
        dragCurrent != null) {
      final outlineColor = liveInvalid
          ? const Color(0x88FFFFFF)
          : const Color(0xFFFFFFFF);
      final centerColor = liveInvalid
          ? const Color(0x88000000)
          : const Color(0xFF000000);
      _drawDashedLine(
        canvas,
        dragStart!,
        dragCurrent!,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12.0
          ..strokeCap = StrokeCap.round
          ..color = outlineColor,
      );
      _drawDashedLine(
        canvas,
        dragStart!,
        dragCurrent!,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..color = centerColor,
      );
    }

    // 4. Selection handles and delete button — drawn outside the mask so
    //    they're always visible and interactive.
    for (final c in cuts) {
      if (c.id != selectedId || c.locked) continue;
      final a = Offset(
        displayRect.left + c.x1 * displayRect.width,
        displayRect.top + c.y1 * displayRect.height,
      );
      final b = Offset(
        displayRect.left + c.x2 * displayRect.width,
        displayRect.top + c.y2 * displayRect.height,
      );
      _drawHandles(canvas, a, b);
    }

    if (deleteHandlePos != null) {
      _drawDeleteHandle(canvas, deleteHandlePos!);
    }

    // 5. Inactivity hint — an animated single swipe gesture with a
    //    half-transparent line, drawn last so it floats above everything.
    if (showHint) {
      _drawHintOverlay(canvas, hintValue);
    }
  }

  /// Draws the instructional swipe: a fingertip indicator travels across
  /// the shape, leaving a half-transparent line behind. The animation
  /// cycles swipe → hold → fade → pause. By default the sweep is
  /// horizontal across the shape's vertical center; when [hintDiagonal] is
  /// set it sweeps from the bottom-left of the shape to the top-right, as
  /// used by the onboarding tutorial.
  void _drawHintOverlay(ui.Canvas canvas, double t) {
    final b = bbox;
    if (b.width <= 0 || b.height <= 0) return;

    final margin = (b.width * 0.1).clamp(16.0, 48.0);
    final Offset start;
    final Offset end;
    if (hintDiagonal) {
      // Bottom-left of the shape area -> top-right, with a small outward
      // margin on each axis and clamped to the on-screen display rect.
      start = Offset(
        (b.left - margin).clamp(displayRect.left, displayRect.right),
        (b.bottom + margin).clamp(displayRect.top, displayRect.bottom),
      );
      end = Offset(
        (b.right + margin).clamp(displayRect.left, displayRect.right),
        (b.top - margin).clamp(displayRect.top, displayRect.bottom),
      );
    } else {
      final startX =
          (b.left - margin).clamp(displayRect.left, displayRect.right);
      final endX =
          (b.right + margin).clamp(displayRect.left, displayRect.right);
      start = Offset(startX, b.center.dy);
      end = Offset(endX, b.center.dy);
    }

    const swipeEnd = 0.4;
    const holdEnd = 0.7;
    const fadeEnd = 0.85;
    // [fadeEnd, 1.0] is a pause with nothing drawn.

    double opacity;
    double swipeProgress;
    if (t < swipeEnd) {
      swipeProgress = t / swipeEnd;
      opacity = 1.0;
    } else if (t < holdEnd) {
      swipeProgress = 1.0;
      opacity = 1.0;
    } else if (t < fadeEnd) {
      swipeProgress = 1.0;
      opacity = 1.0 - (t - holdEnd) / (fadeEnd - holdEnd);
    } else {
      return;
    }
    opacity = opacity.clamp(0.0, 1.0);
    final cur = Offset.lerp(start, end, swipeProgress)!;

    // Half-transparent line: white underlay for contrast on any shape,
    // then a black core. Solid (not dashed) so it reads as a gesture
    // guide rather than a placed cut.
    canvas.drawLine(
      start,
      cur,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.45 * opacity),
    );
    canvas.drawLine(
      start,
      cur,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF000000).withValues(alpha: 0.55 * opacity),
    );

    // Fingertip indicator at the leading edge of the swipe.
    canvas.drawCircle(
      cur,
      20,
      Paint()..color = const Color(0xFF000000).withValues(alpha: 0.18 * opacity),
    );
    canvas.drawCircle(
      cur,
      10,
      Paint()..color = const Color(0xFF000000).withValues(alpha: 0.55 * opacity),
    );
    canvas.drawCircle(
      cur,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.75 * opacity),
    );
  }

  void _drawHandles(ui.Canvas canvas, Offset a, Offset b) {
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    for (final pos in [a, b, mid]) {
      canvas.drawCircle(pos, 10, Paint()..color = const Color(0xFFFFFFFF));
      canvas.drawCircle(
        pos,
        10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFF000000),
      );
    }
  }

  void _drawDeleteHandle(ui.Canvas canvas, Offset pos) {
    canvas.drawCircle(pos, 16, Paint()..color = const Color(0xFF000000));
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFFFFF);
    const r = 6.0;
    canvas.drawLine(Offset(pos.dx - r, pos.dy - r), Offset(pos.dx + r, pos.dy + r), p);
    canvas.drawLine(Offset(pos.dx - r, pos.dy + r), Offset(pos.dx + r, pos.dy - r), p);
  }

  void _drawDashedLine(ui.Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashLen = 6.0;
    const gapLen = 12.0;
    final d = b - a;
    final len = d.distance;
    if (len == 0) return;
    final ux = d.dx / len;
    final uy = d.dy / len;
    var t = 0.0;
    while (t < len) {
      final e = math.min(t + dashLen, len);
      canvas.drawLine(
        Offset(a.dx + ux * t, a.dy + uy * t),
        Offset(a.dx + ux * e, a.dy + uy * e),
        paint,
      );
      t = e + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _CutPainter old) =>
      old.image != image ||
      old.cuts != cuts ||
      old.selectedId != selectedId ||
      old.displayRect != displayRect ||
      old.dragKind != dragKind ||
      old.dragStart != dragStart ||
      old.dragCurrent != dragCurrent ||
      old.liveInvalid != liveInvalid ||
      old.deleteHandlePos != deleteHandlePos ||
      old.showHint != showHint ||
      old.hintValue != hintValue ||
      old.hintDiagonal != hintDiagonal;
}

// --- Drag / hit-test enums --------------------------------------------------

enum _DragKind { none, newCut, moveHandle }

enum _HandleKind { none, endpoint1, endpoint2, body }

enum _HitKind { none, cut, delete }

class _HitTest {
  _HitTest._(this.kind, this.cutId, this.handle);
  factory _HitTest.cut(String id, _HandleKind h) => _HitTest._(_HitKind.cut, id, h);
  factory _HitTest.delete(String id) => _HitTest._(_HitKind.delete, id, _HandleKind.none);
  factory _HitTest.empty() => _HitTest._(_HitKind.none, null, _HandleKind.none);
  final _HitKind kind;
  final String? cutId;
  final _HandleKind handle;
}
