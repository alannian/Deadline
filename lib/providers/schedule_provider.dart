import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/schedule.dart';
import '../services/database_service.dart';

class ScheduleProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  List<Schedule> _daySchedules = [];
  List<Schedule> get daySchedules => _daySchedules;

  Map<DateTime, List<Schedule>> _allSchedulesMap = {};
  Map<DateTime, List<Schedule>> get allSchedulesMap => _allSchedulesMap;

  /// 选择日期并加载日程
  Future<void> selectDate(DateTime date) async {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _daySchedules = await _db.getSchedulesByDate(_selectedDate);
    notifyListeners();
  }

  /// 加载所有日程（用于日历标记）
  Future<void> loadAllSchedules() async {
    final all = await _db.getAllSchedules();
    _allSchedulesMap = {};
    for (var s in all) {
      final key = DateTime(s.date.year, s.date.month, s.date.day);
      _allSchedulesMap.putIfAbsent(key, () => []);
      _allSchedulesMap[key]!.add(s);
    }
    notifyListeners();
  }

  /// 创建日程
  Future<void> createSchedule({
    String? taskId,
    required String title,
    String? description,
    required DateTime date,
    required int startMinutes,
    required int endMinutes,
    int colorValue = 0xFF42A5F5,
    double? plannedAmount,
  }) async {
    final schedule = Schedule(
      id: _uuid.v4(),
      taskId: taskId,
      title: title,
      description: description,
      date: DateTime(date.year, date.month, date.day),
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      colorValue: colorValue,
      plannedAmount: plannedAmount,
    );
    await _db.insertSchedule(schedule);
    await selectDate(_selectedDate);
    await loadAllSchedules();
  }

  /// 完成日程并记录完成量
  Future<void> completeSchedule(Schedule schedule,
      {double? completedAmount}) async {
    final updated = schedule.copyWith(
      isCompleted: true,
      completedAmount: completedAmount,
    );
    await _db.updateSchedule(updated);
    await selectDate(_selectedDate);
  }

  /// 取消完成
  Future<void> uncompleteSchedule(Schedule schedule) async {
    final updated = schedule.copyWith(isCompleted: false);
    await _db.updateSchedule(updated);
    await selectDate(_selectedDate);
  }

  /// 删除日程
  Future<void> deleteSchedule(String id) async {
    await _db.deleteSchedule(id);
    await selectDate(_selectedDate);
    await loadAllSchedules();
  }

  /// 获取任务的已分配量
  Future<double> getTaskAllocatedAmount(String taskId) async {
    return await _db.getTaskAllocatedAmount(taskId);
  }
}
