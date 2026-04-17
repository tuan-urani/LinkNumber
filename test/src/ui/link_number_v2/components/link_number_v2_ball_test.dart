import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flow_connection/src/ui/link_number_v2/components/link_number_v2_ball.dart';

void main() {
  Future<void> pumpBall(
    WidgetTester tester, {
    required LinkNumberV2BallState state,
    required double destroyProgress,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 72,
              height: 72,
              child: LinkNumberV2Ball(
                key: ValueKey<String>('ball_$state'),
                value: 8,
                state: state,
                destroyProgress: destroyProgress,
                selectionPulse: state == LinkNumberV2BallState.selected
                    ? 0.7
                    : 0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders idle state', (tester) async {
    await pumpBall(
      tester,
      state: LinkNumberV2BallState.idle,
      destroyProgress: 0,
    );

    expect(
      find.byKey(const ValueKey<String>('ball_LinkNumberV2BallState.idle')),
      findsOneWidget,
    );
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('renders selected state', (tester) async {
    await pumpBall(
      tester,
      state: LinkNumberV2BallState.selected,
      destroyProgress: 0,
    );

    expect(
      find.byKey(const ValueKey<String>('ball_LinkNumberV2BallState.selected')),
      findsOneWidget,
    );
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('renders destroy state', (tester) async {
    await pumpBall(
      tester,
      state: LinkNumberV2BallState.destroy,
      destroyProgress: 0.65,
    );

    expect(
      find.byKey(const ValueKey<String>('ball_LinkNumberV2BallState.destroy')),
      findsOneWidget,
    );
    expect(find.text('8'), findsOneWidget);
  });
}
