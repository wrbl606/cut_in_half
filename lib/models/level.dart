import 'cut_line.dart';

class Level {
  Level({
    required this.id,
    required this.title,
    required this.image,
    required this.timeLimit,
    required this.targetPieces,
    required this.initialCuts,
    required this.unlockPoints,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    // Pre-placed initial cuts would let the player reach the target piece
    // count without performing the required cuts themselves. To force the
    // player to make every `targetPieces - 1` cut, the level model never
    // carries pre-placed cuts, regardless of what the JSON declares.
    return Level(
      id: json['id'] as String,
      title: json['title'] as String,
      image: json['image'] as String,
      timeLimit: (json['time_limit'] as num).toInt(),
      targetPieces: (json['target_pieces'] as num).toInt(),
      initialCuts: const <CutLine>[],
      unlockPoints: (json['unlock_points'] as num).toInt(),
    );
  }

  final String id;
  final String title;
  final String image;
  final int timeLimit;
  final int targetPieces;
  final List<CutLine> initialCuts;
  final int unlockPoints;

  int get requiredCuts => targetPieces - 1;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'image': image,
        'time_limit': timeLimit,
        'target_pieces': targetPieces,
        'initial_cuts': initialCuts
            .map((c) => {
                  'x1': c.x1,
                  'y1': c.y1,
                  'x2': c.x2,
                  'y2': c.y2,
                  'locked': c.locked,
                })
            .toList(),
        'unlock_points': unlockPoints,
      };
}
