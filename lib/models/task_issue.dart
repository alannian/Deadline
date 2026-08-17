class TaskIssue {
  final String id;
  final String title;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskIssue({
    required this.id,
    required this.title,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'note': note,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory TaskIssue.fromMap(Map<String, dynamic> map) {
    return TaskIssue(
      id: map['id'] as String,
      title: map['title'] as String,
      note: (map['note'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  TaskIssue copyWith({String? title, String? note, DateTime? updatedAt}) {
    return TaskIssue(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
