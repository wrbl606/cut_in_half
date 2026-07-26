import 'package:cut_in_half/app.dart';
import 'package:cut_in_half/models/cut_line.dart';
import 'package:cut_in_half/models/player_progress.dart';
import 'package:cut_in_half/services/storage_service.dart';
import 'package:cut_in_half/widgets/cut_canvas.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory storage so widget tests never touch plugin prefs.
class _FakeStorage extends StorageService {
  PlayerProgress progress = PlayerProgress();

  @override
  Future<PlayerProgress> load() async =>
      PlayerProgress.fromJson(progress.toJson());

  @override
  Future<void> save(PlayerProgress p) async => progress = p;
}

void main() {
  group('CutInHalfApp.shouldShowOnboarding', () {
    test('true for a brand-new player (empty progress, flag unset)', () {
      expect(CutInHalfApp.shouldShowOnboarding(PlayerProgress()), isTrue);
    });

    test('false once the onboarding flag has been persisted', () {
      final p = PlayerProgress()..onboardingCompleted = true;
      expect(CutInHalfApp.shouldShowOnboarding(p), isFalse);
    });

    test('false for an existing player with recorded level progress', () {
      final p = PlayerProgress()..recordResult('level_01', 80, 80.0);
      expect(p.onboardingCompleted, isFalse,
          reason: 'guard: the flag is unset for an upgrading player');
      expect(CutInHalfApp.shouldShowOnboarding(p), isFalse,
          reason: 'Existing players should skip the tutorial');
    });
  });

  // Pump helper that advances frames until [finder] matches, with a bounded
  // frame budget so a missing widget fails fast instead of hanging.
  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int maxFrames = 40,
  }) async {
    for (var i = 0; i < maxFrames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(finder)) break;
    }
  }

  testWidgets('app routes straight to the menu when onboarding is complete',
      (tester) async {
    final storage = _FakeStorage()..progress.onboardingCompleted = true;
    await tester.pumpWidget(CutInHalfApp(storage: storage));

    await pumpUntil(tester, find.text('Single Player'));

    expect(find.text('Single Player'), findsOneWidget);
    expect(find.text('Learn to Cut'), findsNothing);
  });

  testWidgets('app routes straight to the menu for an existing player',
      (tester) async {
    final storage = _FakeStorage()
      ..progress.recordResult('level_01', 80, 80.0);
    await tester.pumpWidget(CutInHalfApp(storage: storage));

    await pumpUntil(tester, find.text('Single Player'));

    expect(find.text('Single Player'), findsOneWidget);
    expect(find.text('Learn to Cut'), findsNothing);
  });

  // NOTE: This is the only test in the suite that pumps the app into the
  // onboarding state, which builds the real CutCanvas and starts decoding
  // the Sparrow asset. In this test environment that decode does not
  // resolve, so we avoid waiting on it and we keep this test last to
  // prevent its pending image load from polluting other tests. It
  // consolidates the onboarding-shown + level_01 + hint-config + first-cut
  // completion checks.
  testWidgets(
      'onboarding shows level_01 with a 2s diagonal guide and completes on '
      'the first cut', (tester) async {
    final storage = _FakeStorage();
    await tester.pumpWidget(CutInHalfApp(storage: storage));

    // AC #1: first launch shows the onboarding screen, not the menu.
    await pumpUntil(tester, find.text('Learn to Cut'));
    expect(find.text('Learn to Cut'), findsOneWidget);
    expect(find.text('Single Player'), findsNothing);
    expect(storage.progress.onboardingCompleted, isFalse);

    // AC #2: reuses level_01 (Sparrow).
    expect(find.textContaining('Sparrow'), findsOneWidget);

    // AC #3 & #4: the canvas is configured for a 2s diagonal gesture guide.
    await pumpUntil(tester, find.byType(CutCanvas));
    final canvas = tester.widget<CutCanvas>(find.byType(CutCanvas));
    expect(canvas.assetPath, 'assets/images/apple_1.png',
        reason: 'Onboarding should use the Sparrow (level_01) asset');
    expect(canvas.targetPieces, 2);
    expect(canvas.hintDelay, const Duration(seconds: 2),
        reason: 'The gesture guide should fire after a 2s delay');
    expect(canvas.hintDiagonal, isTrue,
        reason: 'The guide should sweep diagonally bottom-left to top-right');

    // AC #5: the player's first committed cut ends onboarding and hands off
    // to the menu. Drive the canvas's cut callback directly (the same path
    // a real drag takes) so the test does not depend on image decoding.
    canvas.onCutsChanged([
      CutLine(
        id: 'p1',
        x1: 0.1,
        y1: 0.9,
        x2: 0.9,
        y2: 0.1,
        locked: false,
        isInitial: false,
      ),
    ]);

    await pumpUntil(tester, find.text('Single Player'));
    expect(find.text('Single Player'), findsOneWidget,
        reason: 'Onboarding should hand off to the menu after the first cut');
    expect(find.text('Learn to Cut'), findsNothing);

    // AC #6: completion is persisted so onboarding is not shown again.
    expect(storage.progress.onboardingCompleted, isTrue);
  });
}
