import 'dart:math' as math;

class MergeTimingSpec {
  const MergeTimingSpec({
    required this.resolveDurationMs,
    required this.commitDelayMs,
    required this.lineFadeDurationMs,
    required this.dropStartBufferMs,
  });

  static const int resolveCellStaggerMs = 65;

  static const int _resolveBaseMs = 220;
  static const int _resolveMaxMs = 920;
  static const int _animatedPathTwoMinResolveMs = 560;
  static const int _lineFadeMinMs = 150;
  static const int _lineFadeMaxMs = 260;
  static const int _dropStartBufferBaseMs = 18;

  final int resolveDurationMs;
  final int commitDelayMs;
  final int lineFadeDurationMs;
  final int dropStartBufferMs;

  Duration get resolveDuration => Duration(milliseconds: resolveDurationMs);
  Duration get commitDelay => Duration(milliseconds: commitDelayMs);
  Duration get lineFadeDuration => Duration(milliseconds: lineFadeDurationMs);
  Duration get dropStartBuffer => Duration(milliseconds: dropStartBufferMs);

  factory MergeTimingSpec.balanced({
    required int pathLength,
    required bool hasAnimatedGif,
  }) {
    final normalizedLength = math.max(2, pathLength);
    final rawResolveMs =
        _resolveBaseMs + ((normalizedLength - 1) * resolveCellStaggerMs);
    var resolvedDurationMs = math.min(rawResolveMs, _resolveMaxMs);
    if (hasAnimatedGif &&
        pathLength == 2 &&
        resolvedDurationMs < _animatedPathTwoMinResolveMs) {
      resolvedDurationMs = _animatedPathTwoMinResolveMs;
    }

    final lineFadeMs = (resolvedDurationMs * 0.36).round().clamp(
      _lineFadeMinMs,
      _lineFadeMaxMs,
    );
    final dropStartBufferMs = pathLength >= 5
        ? _dropStartBufferBaseMs + 4
        : _dropStartBufferBaseMs;

    return MergeTimingSpec(
      resolveDurationMs: resolvedDurationMs,
      commitDelayMs: resolvedDurationMs,
      lineFadeDurationMs: lineFadeMs,
      dropStartBufferMs: dropStartBufferMs,
    );
  }
}
