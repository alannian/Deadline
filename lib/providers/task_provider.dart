import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/task_record.dart';
import '../services/database_service.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  List<Task> _tasks = [];
  List<Task> get tasks => _tasks.where((t) => !t.isHidden).toList();
  List<Task> get hiddenTasks => _tasks.where((t) => t.isHidden).toList();
  List<Task> get allTasks => _tasks;

  // 当前查看的任务记录
  List<TaskRecord> _currentRecords = [];
  List<TaskRecord> get currentRecords => _currentRecords;

  /// 加载所有任务（置顶排前面）
  Future<void> loadTasks() async {
    _tasks = await _db.getAllTasks();
    _tasks.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    notifyListeners();
  }

  /// 创建任务
  Future<void> createTask({
    required String title,
    required String unit,
    required double targetAmount,
    String? note,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      unit: unit,
      targetAmount: targetAmount,
      note: note,
      createdAt: DateTime.now(),
    );
    await _db.insertTask(task);
    await loadTasks();
  }

  /// 切换置顶
  Future<void> togglePin(Task task) async {
    final updated = task.copyWith(isPinned: !task.isPinned);
    await _db.updateTask(updated);
    await loadTasks();
  }

  /// 切换隐藏
  Future<void> toggleHidden(Task task) async {
    final updated = task.copyWith(isHidden: !task.isHidden);
    await _db.updateTask(updated);
    await loadTasks();
  }

  /// 更新任务
  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    await loadTasks();
  }

  /// 删除任务
  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
    await loadTasks();
  }

  /// 批量删除任务
  Future<void> deleteTasks(List<String> ids) async {
    for (final id in ids) {
      await _db.deleteTask(id);
    }
    await loadTasks();
  }

  /// 记录完成量
  Future<void> recordCompletion({
    required String taskId,
    required double amount,
    String? note,
  }) async {
    final record = TaskRecord(
      id: _uuid.v4(),
      taskId: taskId,
      amount: amount,
      date: DateTime.now(),
      note: note,
    );
    await _db.insertTaskRecord(record);
    await loadTasks();
  }

  /// 加载任务的完成记录
  Future<void> loadRecords(String taskId) async {
    _currentRecords = await _db.getRecordsByTask(taskId);
    notifyListeners();
  }

  /// 删除记录
  Future<void> deleteRecord(TaskRecord record) async {
    await _db.deleteTaskRecord(record);
    await loadTasks();
    await loadRecords(record.taskId);
  }
}
