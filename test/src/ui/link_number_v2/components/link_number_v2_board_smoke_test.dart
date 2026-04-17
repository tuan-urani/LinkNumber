import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif/gif.dart';

import 'package:flow_connection/src/ui/link_number_v2/components/link_number_board.dart';
import 'package:flow_connection/src/ui/link_number_v2/components/link_number_v2_ball.dart';
import 'package:flow_connection/src/ui/link_number_v2/interactor/link_number_snapshot.dart';

LinkNumberSnapshot _buildSnapshot() {
  return const LinkNumberSnapshot(
    board: <List<int>>[
      <int>[2, 4, 8, 16],
      <int>[4, 8, 16, 32],
      <int>[8, 16, 32, 64],
      <int>[16, 32, 64, 128],
    ],
    currentLevel: 1,
    goalMode: LinkNumberGoalMode.goalCount,
    goalTargets: <LinkNumberGoalTarget>[
      LinkNumberGoalTarget(value: 8, required: 8, remaining: 8),
    ],
    score: 0,
    scoreTarget: 100,
    movesLeft: 12,
    coins: 500,
    stars: 0,
    breakTileCost: 200,
    swapCharges: 2,
    activePath: <LinkNumberCell>[],
    activeValue: null,
    selectedSkill: null,
    pendingSwapCell: null,
    hasWon: false,
    hasLost: false,
  );
}

void main() {
  testWidgets('board v2 renders Flutter balls and no visible Gif', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 420,
            child: LinkNumberBoard(
              snapshot: _buildSnapshot(),
              onPanStart: (_, _) {},
              onPanUpdate: (_, _) {},
              onPanEnd: () async {},
              onCellTap: (_, _) {},
              onRetry: () {},
              onNextLevel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LinkNumberV2Ball), findsWidgets);
    expect(find.byType(Gif), findsNothing);
  });
}
