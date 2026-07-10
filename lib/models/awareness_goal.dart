class AwarenessGoal {
  final String id;
  final String title;
  final DateTime createdAt;

  AwarenessGoal({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory AwarenessGoal.fromMap(Map<String, dynamic> map) {
    return AwarenessGoal(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  AwarenessGoal copyWith({String? title}) {
    return AwarenessGoal(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
    );
  }
}
