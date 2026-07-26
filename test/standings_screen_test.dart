import 'package:cut_in_half/models/cut_line.dart';
import 'package:cut_in_half/models/level_result.dart';
import 'package:cut_in_half/screens/standings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

LevelResult _result(String id, double acc, int pts, int remaining) {
  return LevelResult(
    levelId: id,
    cuts: [
      CutLine(id: 'c1', x1: 0.3, y1: 0, x2: 0.3, y2: 1, locked: false, isInitial: false),
    ],
    pieces: [
      PieceInfo(
        regionId: 0,
        area: 500,
        percent: 50.0,
        bboxMinX: 0,
        bboxMinY: 0,
        bboxMaxX: 0.3,
        bboxMaxY: 1,
        maskWidth: 10,
        maskHeight: 10,
        mask: List.filled(50, true),
      ),
      PieceInfo(
        regionId: 1,
        area: 500,
        percent: 50.0,
        bboxMinX: 0.3,
        bboxMinY: 0,
        bboxMaxX: 1,
        bboxMaxY: 1,
        maskWidth: 10,
        maskHeight: 10,
        mask: List.filled(50, true),
      ),
    ],
    accuracy: acc,
    points: pts,
    remainingSeconds: remaining,
  );
}

void main() {
  testWidgets('renders leaderboard and attempts with results', (tester) async {
    final results = [
      PlayerResult(name: 'Alice', result: _result('a', 90.0, 90, 5)),
      PlayerResult(name: 'Bob', result: _result('b', 70.0, 70, 3)),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: StandingsScreen(
          results: results,
          assetPath: 'assets/images/apple_1.png',
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('Bob'), findsWidgets);
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('Attempts'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('shows empty state when no results', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StandingsScreen(
          results: [],
          assetPath: 'assets/images/apple_1.png',
        ),
      ),
    );
    await tester.pump();
    expect(find.text('No results'), findsOneWidget);
  });
}