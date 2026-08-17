import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_issue.dart';
import '../services/database_service.dart';

class TaskIssueProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  List<TaskIssue> _issues = [];
  List<TaskIssue> get issues => _issues;

  Future<void> loadIssues() async {
    _issues = await _db.getTaskIssues();
    notifyListeners();
  }

  Future<void> addIssue({required String title, String note = ''}) async {
    final now = DateTime.now();
    final issue = TaskIssue(
      id: _uuid.v4(),
      title: title,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertTaskIssue(issue);
    await loadIssues();
  }

  Future<void> updateIssue(
    TaskIssue issue, {
    required String title,
    required String note,
  }) async {
    final updated = issue.copyWith(
      title: title,
      note: note,
      updatedAt: DateTime.now(),
    );
    await _db.updateTaskIssue(updated);
    await loadIssues();
  }

  Future<void> deleteIssue(String id) async {
    await _db.deleteTaskIssue(id);
    await loadIssues();
  }
}
