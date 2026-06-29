import 'package:cut_in_half/models/player_progress.dart';
import 'package:cut_in_half/screens/menu_screen.dart';
import 'package:cut_in_half/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory storage so widget tests never touch `dart:io` (whose async
/// completion isn't driven by the test FakeAsync clock).
class _FakeStorage extends StorageService {
  PlayerProgress progress = PlayerProgress();

  @override
  Future<PlayerProgress> load() async =>
      PlayerProgress.fromJson(progress.toJson());

  @override
  Future<void> save(PlayerProgress p) async => progress = p;
}

void main() {
  Future<void> pumpMenu(WidgetTester tester, _FakeStorage storage) async {
    await tester.pumpWidget(
      MaterialApp(home: MenuScreen(storage: storage)),
    );
    // Let the async preference load settle.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('menu shows a sound toggle without opening another screen',
      (tester) async {
    await pumpMenu(tester, _FakeStorage());

    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('toggling the menu sound control updates state and persists',
      (tester) async {
    final storage = _FakeStorage();
    await pumpMenu(tester, storage);

    expect(find.byIcon(Icons.volume_up), findsOneWidget);

    // Tap to mute.
    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pump();

    expect(find.byIcon(Icons.volume_off), findsOneWidget,
        reason: 'Icon should switch to muted immediately');
    expect(storage.progress.soundEnabled, isFalse,
        reason: 'Muted preference should be persisted to storage');

    // Tap again to unmute.
    await tester.tap(find.byIcon(Icons.volume_off));
    await tester.pump();

    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    expect(storage.progress.soundEnabled, isTrue);
  });

  testWidgets('menu reflects the persisted sound preference on load',
      (tester) async {
    final storage = _FakeStorage()..progress.soundEnabled = false;
    await pumpMenu(tester, storage);

    expect(find.byIcon(Icons.volume_off), findsOneWidget,
        reason: 'A persisted muted preference should render muted on launch');
  });
}
