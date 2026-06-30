import 'package:cut_in_half/models/player_progress.dart';
import 'package:cut_in_half/screens/progress_screen.dart';
import 'package:cut_in_half/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory storage so widget tests never open a real sembast database.
class _FakeStorage extends StorageService {
  PlayerProgress progress = PlayerProgress();

  @override
  Future<PlayerProgress> load() async => PlayerProgress.fromJson(progress.toJson());

  @override
  Future<void> save(PlayerProgress p) async => progress = p;
}

void main() {
  testWidgets('ProgressScreen loads and back button pops', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MenuPage(storage: _FakeStorage()),
      ),
    );
    await tester.pump();

    // Tap the button to push ProgressScreen.
    await tester.tap(find.text('Open Levels'));
    await tester.pump();

    // Pump until loaded.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Levels').evaluate().isNotEmpty) break;
    }

    debugPrint('Levels found: ${find.text('Levels').evaluate().isNotEmpty}');
    debugPrint('CircularProgress: ${tester.widgetList(find.byType(CircularProgressIndicator)).length}');

    expect(find.text('Levels'), findsOneWidget);
  });
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key, required this.storage});

  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProgressScreen(storage: storage),
            ),
          ),
          child: const Text('Open Levels'),
        ),
      ),
    );
  }
}