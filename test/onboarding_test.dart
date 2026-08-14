import 'package:cut_in_half/app.dart';
import 'package:cut_in_half/models/attempt.dart';
import 'package:cut_in_half/models/cut_line.dart';
import 'package:cut_in_half/models/player_progress.dart';
import 'package:cut_in_half/services/attempt_store.dart';
import 'package:cut_in_half/services/storage_service.dart';
import 'package:cut_in_half/widgets/cut_canvas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // AttemptStore (used by the onboarding cut) backs onto SharedPreferences,
  // so give it an in-memory store for every test.
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

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
  // the Apple asset. In this test environment that decode does not
  // resolve, so we avoid waiting on it and we keep this test last to
  // prevent its pending image load from polluting other tests. It
  // consolidates the onboarding-shown + level_01 + hint-config + first-cut
  // completion + congrats dialog + attempt-recording checks.
  testWidgets(
      'onboarding shows level_01 (Apple) with a 2s diagonal guide, shows a '
      'congrats message, stores the cut, then reaches the menu', (tester) async {
    final storage = _FakeStorage();
    await tester.pumpWidget(CutInHalfApp(storage: storage));

    // AC #1: first launch shows the onboarding screen, not the menu, and
    // refers to the level as Apple (not Sparrow).
    await pumpUntil(tester, find.text('Learn to Cut'));
    expect(find.text('Learn to Cut'), findsOneWidget);
    expect(find.text('Single Player'), findsNothing);
    expect(find.textContaining('Sparrow'), findsNothing);
    expect(find.textContaining('Apple'), findsOneWidget);
    expect(storage.progress.onboardingCompleted, isFalse);

    // AC #2: reuses level_01 (Apple).
    final canvas = tester.widget<CutCanvas>(find.byType(CutCanvas));
    expect(canvas.assetPath, 'assets/images/apple_1.png',
        reason: 'Onboarding should use the Apple (level_01) asset');
    expect(canvas.targetPieces, 2);
    expect(canvas.hintDelay, const Duration(seconds: 2),
        reason: 'The gesture guide should fire after a 2s delay');
    expect(canvas.hintDiagonal, isTrue,
        reason: 'The guide should sweep diagonally bottom-left to top-right');

    // AC #3: the player's first committed cut ends onboarding. Drive the
    // canvas's cut callback directly (the same path a real drag takes) so
    // the test does not depend on image decoding.
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

    // AC #4: a congrats message appears before the menu; the menu must not
    // be reachable until it is dismissed.
    await pumpUntil(tester, find.text('Nice cut!'));
    expect(find.text('Nice cut!'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Single Player'), findsNothing,
        reason: 'The menu must not appear before the congrats dialog is '
            'dismissed');

    // AC #5: the onboarding cut is stored as the first single-player
    // attempt for level_01 (Apple) and appears in the attempt history.
    final attempts = await AttemptStore().loadAll();
    expect(attempts, hasLength(1));
    expect(attempts.first.mode, AttemptMode.single);
    expect(attempts.first.levelId, 'level_01');
    expect(attempts.first.title, 'Apple');
    expect(attempts.first.assetPath, 'assets/images/apple_1.png');
    expect(attempts.first.cuts, hasLength(1));

    // Dismiss the congrats message → hand off to the menu.
    await tester.tap(find.text('Play'));
    await pumpUntil(tester, find.text('Single Player'));
    expect(find.text('Single Player'), findsOneWidget,
        reason: 'Onboarding should hand off to the menu after the dialog is '
            'dismissed');
    expect(find.text('Learn to Cut'), findsNothing);
    expect(find.text('Nice cut!'), findsNothing);
    expect(find.text('Play'), findsNothing);

    // AC #6: completion is persisted so onboarding is not shown again.
    expect(storage.progress.onboardingCompleted, isTrue);
  });
}
