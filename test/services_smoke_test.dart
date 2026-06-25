import 'package:cut_in_half/services/level_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LevelLoader.loadAll works in testWidgets', (tester) async {
    List<dynamic>? levels;
    Object? error;
    try {
      levels = await LevelLoader.loadAll();
    } catch (e, st) {
      error = e;
      debugPrint('LevelLoader error: $e\n$st');
    }
    debugPrint('levels: ${levels?.length}, error: $error');
    if (levels != null) {
      debugPrint('first: ${levels.first}');
    }
  });
}
