import 'package:cut_in_half/app.dart';
import 'package:cut_in_half/models/player_progress.dart';
import 'package:cut_in_half/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory storage so widget tests never touch plugin prefs.
class _FakeStorage extends StorageService {
  PlayerProgress progress = PlayerProgress();

  @override
  Future<PlayerProgress> load() async => PlayerProgress.fromJson(progress.toJson());

  @override
  Future<void> save(PlayerProgress p) async => progress = p;
}

void main() {
  testWidgets('ProgressScreen back button returns to menu', (tester) async {
    // Mark onboarding as completed so the app boots straight to the menu
    // (this test exercises the menu -> progress -> back flow, not onboarding).
    final storage = _FakeStorage()..progress.onboardingCompleted = true;
    await tester.pumpWidget(CutInHalfApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap "Single Player" to push the ProgressScreen.
    expect(find.text('Single Player'), findsOneWidget);
    await tester.tap(find.text('Single Player'));

    // Pump several frames to let the async level/progress load complete.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Levels').evaluate().isNotEmpty) break;
    }

    debugPrint('On screen: ${tester.widgetList(find.byType(Text)).map((w) => (w as Text).data).toList()}');
    debugPrint('CircularProgressIndicator: ${tester.widgetList(find.byType(CircularProgressIndicator)).length}');

    // We should be on the Levels screen with an AppBar showing a back button.
    expect(find.text('Levels'), findsOneWidget,
        reason: 'ProgressScreen should have loaded its levels');
    final backButton = find.byType(BackButton);
    expect(backButton, findsOneWidget,
        reason: 'AppBar should imply a back button on ProgressScreen');

    // Tap the back button.
    await tester.tap(backButton);
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Single Player').evaluate().isNotEmpty &&
          find.text('Levels').evaluate().isEmpty) {
        break;
      }
    }

    // We should be back at the menu.
    expect(find.text('Levels'), findsNothing);
    expect(find.text('Single Player'), findsOneWidget);
  });
}