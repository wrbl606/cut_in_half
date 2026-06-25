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
    final rawInitial =
        (json['initial_cuts'] as List<dynamic>?) ?? const <dynamic>[];
    final maxAllowed = (json['target_pieces'] as num).toInt() - 1;
    final trimmed = rawInitial.length > maxAllowed
        ? rawInitial.sublist(0, maxAllowed)
        : rawInitial;
    final initialCuts = <CutLine>[];
    for (var i = 0; i < trimmed.length; i++) {
      final c = trimmed[i] as Map<String, dynamic>;
      initialCuts.add(CutLine(
        id: 'initial_${json['id']}_$i',
        x1: (c['x1'] as num).toDouble(),
        y1: (c['y1'] as num).toDouble(),
        x2: (c['x2'] as num).toDouble(),
        y2: (c['y2'] as num).toDouble(),
        locked: c['locked'] as bool? ?? true,
        isInitial: true,
      ));
    }
    return Level(
      id: json['id'] as String,
      title: json['title'] as String,
      image: json['image'] as String,
      timeLimit: (json['time_limit'] as num).toInt(),
      targetPieces: (json['target_pieces'] as num).toInt(),
      initialCuts: initialCuts,
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
