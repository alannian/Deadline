class Schedule {
  final String id;
  final String? taskId; // 关联任务ID，null表示独立事项
  final String title;
  final String? description;
  final DateTime date;
  final int startMinutes; // 开始时间（分钟数，如 480 = 8:00）
  final int endMinutes; // 结束时间
  final int colorValue;
  final double? plannedAmount; // 计划完成量（仅任务关联时）
  final double? completedAmount; // 实际完成量
  final bool isCompleted;

  Schedule({
    required this.id,
    this.taskId,
    required this.title,
    this.description,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
    this.colorValue = 0xFF42A5F5,
    this.plannedAmount,
    this.completedAmount,
    this.isCompleted = false,
  });

  String get startTimeStr {
    final h = startMinutes ~/ 60;
    final m = startMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String get endTimeStr {
    final h = endMinutes ~/ 60;
    final m = endMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  int get durationMinutes => endMinutes - startMinutes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'title': title,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'colorValue': colorValue,
      'plannedAmount': plannedAmount,
      'completedAmount': completedAmount,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      taskId: map['taskId'],
      title: map['title'],
      description: map['description'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      startMinutes: map['startMinutes'],
      endMinutes: map['endMinutes'],
      colorValue: map['colorValue'] ?? 0xFF42A5F5,
      plannedAmount: (map['plannedAmount'] as num?)?.toDouble(),
      completedAmount: (map['completedAmount'] as num?)?.toDouble(),
      isCompleted: map['isCompleted'] == 1,
    );
  }

  Schedule copyWith({
    String? taskId,
    String? title,
    String? description,
    DateTime? date,
    int? startMinutes,
    int? endMinutes,
    int? colorValue,
    double? plannedAmount,
    double? completedAmount,
    bool? isCompleted,
  }) {
    return Schedule(
      id: id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      colorValue: colorValue ?? this.colorValue,
      plannedAmount: plannedAmount ?? this.plannedAmount,
      completedAmount: completedAmount ?? this.completedAmount,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
