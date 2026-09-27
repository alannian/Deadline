class LifeItem {
  final String id;
  final String title;
  final DateTime createdAt;

  const LifeItem({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory LifeItem.fromMap(Map<String, dynamic> map) {
    return LifeItem(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  LifeItem copyWith({String? title}) {
    return LifeItem(id: id, title: title ?? this.title, createdAt: createdAt);
  }
}
