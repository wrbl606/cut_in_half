import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Animates transitions between consecutive string values.
///
/// Whenever [value] changes, the widget finds the longest common prefix
/// shared with the previous value, keeps it static, and cross-fades the
/// differing suffix. Each character of the changing suffix gets its own
/// random spatial offset and its own time offset (stagger). The old
/// suffix's characters drift up and blur out while the new suffix's
/// characters settle in from below, one after another.
class AnimatedText extends StatefulWidget {
  const AnimatedText({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    this.slideDistance = 12,
    this.blurSigma = 2,
    this.jitter = 4,
    this.stagger = const Duration(milliseconds: 50),
    this.seed = 0,
  });

  final String value;

  /// Style applied to every text segment. Inherited defaults are filled in
  /// from the surrounding [DefaultTextStyle] at build time.
  final TextStyle? style;

  final Duration duration;
  final Curve curve;

  /// Vertical travel (logical pixels) of the sliding tails.
  final double slideDistance;

  /// Blur sigma reached by the exiting tail at t = 1.
  final double blurSigma;

  /// Maximum random offset (in each axis, in logical pixels) applied per
  /// character of the changing suffix. Set to 0 for a plain slide.
  final double jitter;

  /// Maximum additional time the last character of the changing suffix lags
  /// behind the first. The first character always has a 0s time offset;
  /// intermediate characters are spread linearly up to [stagger] (clamped to
  /// a maximum of 50ms).
  final Duration stagger;

  /// Optional seed for the per-character random offsets. Bumping it
  /// reshuffles the jitter without changing [value].
  final int seed;

  @override
  State<AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText> {
  late String _previousValue;
  late List<Offset> _oldJitter;
  late List<Offset> _newJitter;

  @override
  void initState() {
    super.initState();
    _previousValue = '';
    final rng = math.Random(widget.seed);
    _oldJitter = _jitterFor(_previousValue, 0, rng);
    _newJitter = _jitterFor(widget.value, 0, rng);
  }

  @override
  void didUpdateWidget(covariant AnimatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.seed != widget.seed) {
      _previousValue = oldWidget.value;
      final rng = math.Random(widget.seed);
      _oldJitter = _jitterFor(
        _previousValue,
        _commonPrefixLength(_previousValue, widget.value),
        rng,
      );
      _newJitter = _jitterFor(
        widget.value,
        _commonPrefixLength(_previousValue, widget.value),
        rng,
      );
    }
  }

  List<Offset> _jitterFor(String s, int prefixLen, math.Random rng) {
    final suffix = s.substring(prefixLen);
    final out = <Offset>[];
    for (var i = 0; i < suffix.length; i++) {
      out.add(Offset(
        (rng.nextDouble() * 2 - 1) * widget.jitter,
        (rng.nextDouble() * 2 - 1) * widget.jitter,
      ));
    }
    return out;
  }

  /// Returns the common prefix length of [a] and [b].
  static int _commonPrefixLength(String a, String b) {
    int i = 0;
    while (i < a.length && i < b.length && a[i] == b[i]) {
      i++;
    }
    return i;
  }

  TextStyle get _resolvedStyle =>
      widget.style ?? DefaultTextStyle.of(context).style;

  @override
  Widget build(BuildContext context) {
    final prevStr = _previousValue;
    final newStr = widget.value;
    final prefixLen = _commonPrefixLength(prevStr, newStr);
    final prefix = newStr.substring(0, prefixLen);
    final oldSuffix = prevStr.substring(prefixLen);
    final newSuffix = newStr.substring(prefixLen);
    final style = _resolvedStyle;

    final staggerMicros = widget.stagger.inMicroseconds < 50000
        ? widget.stagger.inMicroseconds
        : 50000;
    final totalMicros = widget.duration.inMicroseconds <= 0
        ? 1
        : widget.duration.inMicroseconds;

    return TweenAnimationBuilder<double>(
      key: ValueKey('${widget.value}_${_previousValue}_${widget.seed}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, t, _) {
        if (oldSuffix.isEmpty && newSuffix.isEmpty) {
          return Text(prefix, style: style);
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (prefix.isNotEmpty) Text(prefix, style: style),
            Stack(
              clipBehavior: Clip.hardEdge,
              alignment: Alignment.centerLeft,
              children: [
                if (oldSuffix.isNotEmpty)
                  _ScatteredSuffix(
                    text: oldSuffix,
                    style: style,
                    jitter: _oldJitter,
                    progress: -t,
                    slideDistance: widget.slideDistance,
                    opacity: 1 - t,
                    blurSigma: widget.blurSigma,
                    staggerMicros: staggerMicros,
                    totalMicros: totalMicros,
                  ),
                if (newSuffix.isNotEmpty)
                  _ScatteredSuffix(
                    text: newSuffix,
                    style: style,
                    jitter: _newJitter,
                    progress: 1 - t,
                    slideDistance: widget.slideDistance * 0.5,
                    opacity: t,
                    blurSigma: widget.blurSigma,
                    staggerMicros: staggerMicros,
                    totalMicros: totalMicros,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Renders a suffix string as one [Text] per character. Each character is
/// nudged by its own random offset and is delayed in time by [stagger],
/// so the suffix animates in a small ripple rather than as a monolithic
/// block. [progress] is the master progress (0 = settled, ±1 = displaced);
/// the sign controls direction.
class _ScatteredSuffix extends StatelessWidget {
  const _ScatteredSuffix({
    required this.text,
    required this.style,
    required this.jitter,
    required this.progress,
    required this.slideDistance,
    required this.opacity,
    required this.blurSigma,
    required this.staggerMicros,
    required this.totalMicros,
  });

  final String text;
  final TextStyle style;
  final List<Offset> jitter;
  final double progress;
  final double slideDistance;
  final double opacity;
  final double blurSigma;
  final int staggerMicros;
  final int totalMicros;

  /// Per-character local progress in [0,1]. The first character has a 0s
  /// time offset; the last character lags by [staggerMicros] (≤ 50ms). Each
  /// character's offset, expressed as a fraction of [totalMicros], is the
  /// master-progress point at which it begins animating. The remaining
  /// window animates it to its final state.
  double _localProgress(int i, int count) {
    final master = progress.abs();
    if (count <= 1 || staggerMicros <= 0) return master.clamp(0.0, 1.0);
    final perCharStart = staggerMicros / (count - 1);
    final startFraction = (i * perCharStart) / totalMicros;
    final spanFraction = staggerMicros / totalMicros;
    final window = (1 - spanFraction).clamp(1e-6, 1.0);
    return ((master - startFraction) / window).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final count = text.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          _Char(
            char: text[i],
            style: style,
            jitter: jitter[i],
            local: _localProgress(i, count),
            sign: progress.sign,
            slideDistance: slideDistance,
            opacity: opacity,
            blurSigma: blurSigma,
          ),
      ],
    );
  }
}

class _Char extends StatelessWidget {
  const _Char({
    required this.char,
    required this.style,
    required this.jitter,
    required this.local,
    required this.sign,
    required this.slideDistance,
    required this.opacity,
    required this.blurSigma,
  });

  final String char;
  final TextStyle style;
  final Offset jitter;
  final double local;
  final double sign;
  final double slideDistance;
  final double opacity;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final dx = jitter.dx * local;
    final dy = jitter.dy * local - slideDistance * sign * local;
    final op = (opacity * (1 - local)).clamp(0.0, 1.0);
    final blur = blurSigma * local;

    final text = Transform.translate(
      offset: Offset(dx, dy),
      child: Text(char, style: style),
    );
    final faded = Opacity(opacity: op, child: text);
    if (blur <= 0) return faded;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: faded,
    );
  }
}