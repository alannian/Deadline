class Task {
  final String id;
  final String title;
  final String unit; // 量化单位：页、题、章、个、套...
  final double targetAmount; // 目标总量
  final double completedAmount; // 已完成量
  final int colorValue;
  final bool isPinned;
  final bool isHidden;
  final bool isIndependent;
  final String? note; // 备注
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.unit,
    required this.targetAmount,
    this.completedAmount = 0,
    this.colorValue = 0xFF42A5F5,
    this.isPinned = false,
    this.isHidden = false,
    this.isIndependent = false,
    this.note,
    required this.createdAt,
  });

  /// 剩余量
  double get remainingAmount =>
      (targetAmount - completedAmount).clamp(0, targetAmount);

  /// 完成进度 0.0 - 1.0
  double get progress =>
      targetAmount > 0 ? (completedAmount / targetAmount).clamp(0, 1) : 0;

  /// 是否已完成
  bool get isCompleted => completedAmount >= targetAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'unit': unit,
      'targetAmount': targetAmount,
      'completedAmount': completedAmount,
      'colorValue': colorValue,
      'isPinned': isPinned ? 1 : 0,
      'isHidden': isHidden ? 1 : 0,
      'isIndependent': isIndependent ? 1 : 0,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      unit: map['unit'] ?? '个',
      targetAmount: (map['targetAmount'] as num).toDouble(),
      completedAmount: (map['completedAmount'] as num?)?.toDouble() ?? 0,
      colorValue: map['colorValue'] ?? 0xFF42A5F5,
      isPinned: (map['isPinned'] ?? 0) == 1,
      isHidden: (map['isHidden'] ?? 0) == 1,
      isIndependent: (map['isIndependent'] ?? 0) == 1,
      note: map['note'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  Task copyWith({
    String? title,
    String? unit,
    double? targetAmount,
    double? completedAmount,
    int? colorValue,
    bool? isPinned,
    bool? isHidden,
    bool? isIndependent,
    String? note,
    bool clearNote = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      unit: unit ?? this.unit,
      targetAmount: targetAmount ?? this.targetAmount,
      completedAmount: completedAmount ?? this.completedAmount,
      colorValue: colorValue ?? this.colorValue,
      isPinned: isPinned ?? this.isPinned,
      isHidden: isHidden ?? this.isHidden,
      isIndependent: isIndependent ?? this.isIndependent,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt,
    );
  }
}
