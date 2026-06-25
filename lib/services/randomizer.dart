import 'dart:math';

import '../models/cut_line.dart';
import '../models/level.dart';

/// Generates a randomized level for multiplayer (same for all players).
class Randomizer {
  Randomizer({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const List<int> _targetPiecesChoices = [2, 3, 4, 5, 6];
  static const List<int> _timeLimitChoices = [15, 20, 25, 30];

  /// Picks a random [image] from [availableImages], random target_pieces in
  /// 2–6, random time_limit from the preset, and no initial cuts (per §8).
  Level generate({
    required List<String> availableImages,
    String? idPrefix,
  }) {
    if (availableImages.isEmpty) {
      throw ArgumentError('availableImages must not be empty');
    }
    final image = availableImages[_random.nextInt(availableImages.length)];
    final targetPieces =
        _targetPiecesChoices[_random.nextInt(_targetPiecesChoices.length)];
    final timeLimit =
        _timeLimitChoices[_random.nextInt(_timeLimitChoices.length)];
    final id = '${idPrefix ?? 'mp'}_${_random.nextInt(1 << 24)}';
    return Level(
      id: id,
      title: 'Random',
      image: image,
      timeLimit: timeLimit,
      targetPieces: targetPieces,
      initialCuts: const <CutLine>[],
      unlockPoints: 0,
    );
  }
}
