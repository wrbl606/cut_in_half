import 'package:cut_in_half/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async {
        if (call.method == 'getApplicationSupportDirectory') {
          return '/tmp/cut_in_half_test_support';
        }
        return null;
      },
    );
  });

  testWidgets('ProgressScreen back button returns to menu', (tester) async {
    await tester.pumpWidget(const CutInHalfApp());
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
