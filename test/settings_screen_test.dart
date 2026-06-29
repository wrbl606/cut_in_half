import 'package:cut_in_half/models/player_progress.dart';
import 'package:cut_in_half/screens/menu_screen.dart';
import 'package:cut_in_half/screens/settings_screen.dart';
import 'package:cut_in_half/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory storage so widget tests never touch `dart:io`.
class _FakeStorage extends StorageService {
  PlayerProgress progress = PlayerProgress();

  @override
  Future<PlayerProgress> load() async =>
      PlayerProgress.fromJson(progress.toJson());

  @override
  Future<void> save(PlayerProgress p) async => progress = p;
}

void main() {
  Future<void> pumpMenu(
      WidgetTester tester, _FakeStorage storage) async {
    await tester.pumpWidget(
      MaterialApp(home: MenuScreen(storage: storage)),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('Settings screen opens from menu without errors', (tester) async {
    final storage = _FakeStorage();
    await pumpMenu(tester, storage);

    await tester.tap(find.text('Settings'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Settings').evaluate().length >= 2) break;
    }

    // AppBar title plus the original menu button both say 'Settings'.
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
  });

  testWidgets('Settings and menu share the persisted sound preference',
      (tester) async {
    final storage = _FakeStorage();
    await pumpMenu(tester, storage);

    // Mute from the menu.
    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pump();
    expect(storage.progress.soundEnabled, isFalse);

    // Open Settings; its switch should reflect the muted state.
    await tester.tap(find.text('Settings'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(SettingsScreen).evaluate().isNotEmpty) break;
    }
    final settingsSwitch = tester.widget<Switch>(find.byType(Switch));
    expect(settingsSwitch.value, isFalse,
        reason: 'Settings switch should mirror the menu-toggle source of truth');
  });
}
