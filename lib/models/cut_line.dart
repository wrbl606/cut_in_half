class CutLine {
  CutLine({
    required this.id,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.locked,
    required this.isInitial,
  });

  factory CutLine.fromJson(Map<String, dynamic> json) {
    return CutLine(
      id: json['id'] as String? ?? '',
      x1: (json['x1'] as num).toDouble(),
      y1: (json['y1'] as num).toDouble(),
      x2: (json['x2'] as num).toDouble(),
      y2: (json['y2'] as num).toDouble(),
      locked: json['locked'] as bool? ?? false,
      isInitial: json['isInitial'] as bool? ?? false,
    );
  }

  final String id;
  double x1;
  double y1;
  double x2;
  double y2;
  final bool locked;
  final bool isInitial;

  bool get isPlayerDrawn => !isInitial;

  Map<String, dynamic> toJson() => {
        'id': id,
        'x1': x1,
        'y1': y1,
        'x2': x2,
        'y2': y2,
        'locked': locked,
        'isInitial': isInitial,
      };

  CutLine copyWith({
    String? id,
    double? x1,
    double? y1,
    double? x2,
    double? y2,
    bool? locked,
    bool? isInitial,
  }) {
    return CutLine(
      id: id ?? this.id,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      x2: x2 ?? this.x2,
      y2: y2 ?? this.y2,
      locked: locked ?? this.locked,
      isInitial: isInitial ?? this.isInitial,
    );
  }

  @override
  String toString() =>
      'CutLine($id, ($x1,$y1)->($x2,$y2), locked=$locked, isInitial=$isInitial)';
}
