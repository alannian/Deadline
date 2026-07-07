import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../services/database_service.dart';

class HabitProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  List<Habit> _habits = [];
  List<Habit> get habits => _habits;

  // 某日的完成记录（habitId → true）
  Map<String, bool> _todayCompletions = {};
  Map<String, bool> get todayCompletions => _todayCompletions;

  Map<String, bool> _yesterdayCompletions = {};
  Map<String, bool> get yesterdayCompletions => _yesterdayCompletions;

  /// 习惯分数
  double _score = 60.0;
  double get score => _score;

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> loadHabits() async {
    _habits = await _db.getAllHabits();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayList = await _db.getCompletionsByDate(_dateKey(today));
    _todayCompletions = {for (final c in todayList) c.habitId: true};

    final yesterdayList = await _db.getCompletionsByDate(_dateKey(yesterday));
    _yesterdayCompletions = {for (final c in yesterdayList) c.habitId: true};

    await _calcScore();

    notifyListeners();
  }

  /// 计算习惯分数：初始60，从记录的起始日期开始算
  Future<void> _calcScore() async {
    if (_habits.isEmpty) {
      _score = 60.0;
      return;
    }

    // 读取起始日期，若无则设为今天
    final startStr = await _db.getSetting('scoreStartDate');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime startDate;
    if (startStr == null) {
      startDate = today;
      await _db.setSetting('scoreStartDate', _dateKey(today));
    } else {
      startDate = DateTime.parse(startStr);
    }

    final allCompletions = await _db.getAllCompletions();
    // date → Set<habitId>
    final Map<String, Set<String>> completionsByDate = {};
    for (final c in allCompletions) {
      completionsByDate.putIfAbsent(c.date, () => {}).add(c.habitId);
    }

    double s = 60.0;
    // 从起始日期次日开始算分（起始当天不扣分）
    var day = startDate.add(const Duration(days: 1));
    while (!day.isAfter(today)) {
      final key = _dateKey(day);
      final doneSet = completionsByDate[key] ?? {};
      for (final h in _habits) {
        final created = DateTime(h.createdAt.year, h.createdAt.month, h.createdAt.day);
        if (!created.isAfter(day.subtract(const Duration(days: 1)))) {
          if (doneSet.contains(h.id)) {
            s += 0.5;
          } else {
            // 今天还没结束，不扣分
            if (day.isAtSameMomentAs(today)) continue;
            s -= 1.0;
          }
        }
      }
      day = day.add(const Duration(days: 1));
    }
    _score = s;
  }

  Future<void> addHabit(String name) async {
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    await _db.insertHabit(habit);
    await loadHabits();
  }

  Future<void> removeHabit(String id) async {
    await _db.deleteHabit(id);
    await loadHabits();
  }

  Future<void> toggleToday(String habitId) async {
    final now = DateTime.now();
    final key = _dateKey(DateTime(now.year, now.month, now.day));
    if (_todayCompletions.containsKey(habitId)) {
      await _db.deleteHabitCompletion(habitId, key);
    } else {
      await _db.insertHabitCompletion(HabitCompletion(
        id: _uuid.v4(),
        habitId: habitId,
        date: key,
      ));
    }
    await loadHabits();
  }

  /// 昨天完成率 0.0 ~ 1.0
  double get yesterdayRate {
    if (_habits.isEmpty) return 1.0;
    // 只计算昨天之前创建的习惯
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final eligible =
        _habits.where((h) => !h.createdAt.isAfter(yesterday)).toList();
    if (eligible.isEmpty) return 1.0;
    final done =
        eligible.where((h) => _yesterdayCompletions.containsKey(h.id)).length;
    return done / eligible.length;
  }

  /// 今天已完成数
  int get todayDoneCount => _todayCompletions.length;
}
