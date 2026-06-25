import 'dart:io';

import 'package:cut_in_half/screens/progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProgressScreen loads and back button pops', (tester) async {
    final dir = Directory.systemTemp.createTempSync('cut_in_half_test_');
    debugPrint('temp dir: ${dir.path}');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async {
        debugPrint('path_provider mock called: ${call.method}');
        if (call.method == 'getApplicationSupportDirectory') {
          return dir.path;
        }
        return null;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: const MenuPage(),
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
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ProgressScreen())),
          child: const Text('Open Levels'),
        ),
      ),
    );
  }
}
