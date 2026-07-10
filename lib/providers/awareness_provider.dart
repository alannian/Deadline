import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/awareness_goal.dart';
import '../services/database_service.dart';

class AwarenessProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  List<AwarenessGoal> _goals = [];
  List<AwarenessGoal> get goals => _goals;

  Future<void> loadGoals() async {
    _goals = await _db.getAwarenessGoals();
    notifyListeners();
  }

  Future<void> addGoal(String title) async {
    final goal = AwarenessGoal(
      id: _uuid.v4(),
      title: title,
      createdAt: DateTime.now(),
    );
    await _db.insertAwarenessGoal(goal);
    await loadGoals();
  }

  Future<void> updateGoal(AwarenessGoal goal, String title) async {
    await _db.updateAwarenessGoal(goal.copyWith(title: title));
    await loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    await _db.deleteAwarenessGoal(id);
    await loadGoals();
  }
}
