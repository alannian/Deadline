class TaskRecord {
  final String id;
  final String taskId;
  final double amount;
  final DateTime date;
  final String? note;

  TaskRecord({
    required this.id,
    required this.taskId,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory TaskRecord.fromMap(Map<String, dynamic> map) {
    return TaskRecord(
      id: map['id'],
      taskId: map['taskId'],
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      note: map['note'],
    );
  }
}
