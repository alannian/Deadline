class Habit {
  final String id;
  final String name;
  final DateTime createdAt;

  Habit({required this.id, required this.name, required this.createdAt});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Habit.fromMap(Map<String, dynamic> m) => Habit(
        id: m['id'] as String,
        name: m['name'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );

  Habit copyWith({String? name}) => Habit(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
      );
}

class HabitCompletion {
  final String id;
  final String habitId;
  final String date; // yyyy-MM-dd

  HabitCompletion({
    required this.id,
    required this.habitId,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'habitId': habitId,
        'date': date,
      };

  factory HabitCompletion.fromMap(Map<String, dynamic> m) => HabitCompletion(
        id: m['id'] as String,
        habitId: m['habitId'] as String,
        date: m['date'] as String,
      );
}
