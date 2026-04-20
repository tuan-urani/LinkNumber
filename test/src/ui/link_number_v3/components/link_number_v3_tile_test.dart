import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flow_connection/src/ui/link_number_v3/components/link_number_v3_tile.dart';

void main() {
  Future<void> pumpTile(
    WidgetTester tester, {
    required LinkNumberV3TileState state,
    required double destroyProgress,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 72,
              height: 72,
              child: LinkNumberV3Tile(
                key: ValueKey<String>('tile_$state'),
                value: 8,
                state: state,
                destroyProgress: destroyProgress,
                selectionPulse: state == LinkNumberV3TileState.selected
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
    await pumpTile(
      tester,
      state: LinkNumberV3TileState.idle,
      destroyProgress: 0,
    );

    expect(
      find.byKey(const ValueKey<String>('tile_LinkNumberV3TileState.idle')),
      findsOneWidget,
    );
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('renders selected state', (tester) async {
    await pumpTile(
      tester,
      state: LinkNumberV3TileState.selected,
      destroyProgress: 0,
    );

    expect(
      find.byKey(const ValueKey<String>('tile_LinkNumberV3TileState.selected')),
      findsOneWidget,
    );
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('renders destroy state', (tester) async {
    await pumpTile(
      tester,
      state: LinkNumberV3TileState.destroy,
      destroyProgress: 0.65,
    );

    expect(
      find.byKey(const ValueKey<String>('tile_LinkNumberV3TileState.destroy')),
      findsOneWidget,
    );
    expect(find.text('8'), findsOneWidget);
  });
}
