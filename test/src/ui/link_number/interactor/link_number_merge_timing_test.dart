import 'package:flutter_test/flutter_test.dart';

import 'package:flow_connection/src/ui/link_number/interactor/link_number_merge_timing.dart';

void main() {
  group('MergeTimingSpec.balanced', () {
    test('keeps commit delay in sync with resolve duration', () {
      final spec = MergeTimingSpec.balanced(
        pathLength: 4,
        hasAnimatedGif: true,
      );

      expect(spec.commitDelayMs, spec.resolveDurationMs);
      expect(spec.commitDelay, spec.resolveDuration);
    });

    test('extends path=2 timing for animated destroy preview', () {
      final nonAnimated = MergeTimingSpec.balanced(
        pathLength: 2,
        hasAnimatedGif: false,
      );
      final animated = MergeTimingSpec.balanced(
        pathLength: 2,
        hasAnimatedGif: true,
      );

      expect(
        animated.resolveDurationMs,
        greaterThan(nonAnimated.resolveDurationMs),
      );
      expect(animated.resolveDurationMs, 560);
      expect(animated.commitDelayMs, 560);
    });

    test('line fade and drop buffer stay in balanced range', () {
      final shortPath = MergeTimingSpec.balanced(
        pathLength: 2,
        hasAnimatedGif: false,
      );
      final longPath = MergeTimingSpec.balanced(
        pathLength: 6,
        hasAnimatedGif: false,
      );

      expect(shortPath.lineFadeDurationMs, inInclusiveRange(150, 260));
      expect(longPath.lineFadeDurationMs, inInclusiveRange(150, 260));
      expect(shortPath.dropStartBufferMs, 18);
      expect(longPath.dropStartBufferMs, 22);
    });
  });
}
