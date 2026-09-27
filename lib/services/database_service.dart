import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/task_record.dart';
import '../models/schedule.dart';
import '../models/memo.dart';
import '../models/habit.dart';
import '../models/awareness_goal.dart';
import '../models/task_issue.dart';
import '../models/life_item.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._init();

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('deadline_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 13,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        unit TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        completedAmount REAL DEFAULT 0,
        colorValue INTEGER DEFAULT 4282557941,
        isPinned INTEGER DEFAULT 0,
        isHidden INTEGER DEFAULT 0,
        isIndependent INTEGER DEFAULT 0,
        note TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE task_records (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules (
        id TEXT PRIMARY KEY,
        taskId TEXT,
        title TEXT NOT NULL,
        description TEXT,
        date INTEGER NOT NULL,
        startMinutes INTEGER NOT NULL,
        endMinutes INTEGER NOT NULL,
        colorValue INTEGER DEFAULT 4282557941,
        plannedAmount REAL,
        completedAmount REAL,
        isCompleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE memo_folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parentId TEXT,
        sortOrder INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        isStarred INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE memos (
        id TEXT PRIMARY KEY,
        folderId TEXT,
        title TEXT NOT NULL,
        content TEXT DEFAULT '',
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isStarred INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_completions (
        id TEXT PRIMARY KEY,
        habitId TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE awareness_goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE task_issues (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        note TEXT DEFAULT '',
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE life_items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');
  }

  // ==================== Settings ====================

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ==================== Task CRUD ====================

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'createdAt ASC');
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<Task?> getTask(String id) async {
    final db = await database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    await db.delete('task_records', where: 'taskId = ?', whereArgs: [id]);
    await db.delete('schedules', where: 'taskId = ?', whereArgs: [id]);
  }

  // ==================== TaskRecord CRUD ====================

  Future<void> insertTaskRecord(TaskRecord record) async {
    final db = await database;
    await db.insert(
      'task_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // 更新任务的已完成量
    await _recalcTaskCompleted(record.taskId);
  }

  Future<List<TaskRecord>> getRecordsByTask(String taskId) async {
    final db = await database;
    final maps = await db.query(
      'task_records',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => TaskRecord.fromMap(map)).toList();
  }

  Future<void> deleteTaskRecord(TaskRecord record) async {
    final db = await database;
    await db.delete('task_records', where: 'id = ?', whereArgs: [record.id]);
    await _recalcTaskCompleted(record.taskId);
  }

  Future<void> _recalcTaskCompleted(String taskId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM task_records WHERE taskId = ?',
      [taskId],
    );
    final total = (result.first['total'] as num?)?.toDouble() ?? 0;
    await db.update(
      'tasks',
      {'completedAmount': total},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // ==================== Schedule CRUD ====================

  Future<void> insertSchedule(Schedule schedule) async {
    final db = await database;
    await db.insert(
      'schedules',
      schedule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Schedule>> getSchedulesByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final maps = await db.query(
      'schedules',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'startMinutes ASC',
    );
    return maps.map((map) => Schedule.fromMap(map)).toList();
  }

  Future<List<Schedule>> getAllSchedules() async {
    final db = await database;
    final maps = await db.query(
      'schedules',
      orderBy: 'date ASC, startMinutes ASC',
    );
    return maps.map((map) => Schedule.fromMap(map)).toList();
  }

  Future<void> updateSchedule(Schedule schedule) async {
    final db = await database;
    await db.update(
      'schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<void> deleteSchedule(String id) async {
    final db = await database;
    await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  /// 获取某任务在日程中的已规划总量
  Future<double> getTaskAllocatedAmount(String taskId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(plannedAmount), 0) as total FROM schedules WHERE taskId = ?',
      [taskId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // ==================== DB Upgrade ====================

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE memo_folders ADD COLUMN parentId TEXT');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE tasks ADD COLUMN isPinned INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE tasks ADD COLUMN note TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE habits (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE habit_completions (
          id TEXT PRIMARY KEY,
          habitId TEXT NOT NULL,
          date TEXT NOT NULL,
          FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE memos ADD COLUMN isStarred INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 7) {
      try {
        await db.execute(
          'ALTER TABLE memo_folders ADD COLUMN isStarred INTEGER DEFAULT 0',
        );
      } catch (_) {}
    }
    if (oldVersion < 8) {
      // v7 upgrade may have been skipped due to a bug; ensure column exists
      try {
        await db.execute(
          'ALTER TABLE memo_folders ADD COLUMN isStarred INTEGER DEFAULT 0',
        );
      } catch (_) {}
    }
    if (oldVersion < 9) {
      await db.execute(
        'ALTER TABLE tasks ADD COLUMN isHidden INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS awareness_goals (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          createdAt INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS task_issues (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          note TEXT DEFAULT '',
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 12) {
      await db.execute(
        'ALTER TABLE tasks ADD COLUMN isIndependent INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 13) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS life_items (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          createdAt INTEGER NOT NULL
        )
      ''');
    }
  }

  // ==================== TaskIssue CRUD ====================

  Future<void> insertTaskIssue(TaskIssue issue) async {
    final db = await database;
    await db.insert(
      'task_issues',
      issue.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TaskIssue>> getTaskIssues() async {
    final db = await database;
    final maps = await db.query('task_issues', orderBy: 'createdAt DESC');
    return maps.map((map) => TaskIssue.fromMap(map)).toList();
  }

  Future<void> updateTaskIssue(TaskIssue issue) async {
    final db = await database;
    await db.update(
      'task_issues',
      issue.toMap(),
      where: 'id = ?',
      whereArgs: [issue.id],
    );
  }

  Future<void> deleteTaskIssue(String id) async {
    final db = await database;
    await db.delete('task_issues', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== LifeItem CRUD ====================

  Future<void> insertLifeItem(LifeItem item) async {
    final db = await database;
    await db.insert(
      'life_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LifeItem>> getLifeItems() async {
    final db = await database;
    final maps = await db.query('life_items', orderBy: 'createdAt ASC');
    return maps.map(LifeItem.fromMap).toList();
  }

  Future<void> updateLifeItem(LifeItem item) async {
    final db = await database;
    await db.update(
      'life_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteLifeItem(String id) async {
    final db = await database;
    await db.delete('life_items', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== AwarenessGoal CRUD ====================

  Future<void> insertAwarenessGoal(AwarenessGoal goal) async {
    final db = await database;
    await db.insert(
      'awareness_goals',
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AwarenessGoal>> getAwarenessGoals() async {
    final db = await database;
    final maps = await db.query('awareness_goals', orderBy: 'createdAt ASC');
    return maps.map((map) => AwarenessGoal.fromMap(map)).toList();
  }

  Future<void> updateAwarenessGoal(AwarenessGoal goal) async {
    final db = await database;
    await db.update(
      'awareness_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> deleteAwarenessGoal(String id) async {
    final db = await database;
    await db.delete('awareness_goals', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== MemoFolder CRUD ====================

  Future<void> insertMemoFolder(MemoFolder folder) async {
    final db = await database;
    await db.insert(
      'memo_folders',
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MemoFolder>> getAllMemoFolders() async {
    final db = await database;
    final maps = await db.query('memo_folders', orderBy: 'sortOrder ASC');
    return maps.map((map) => MemoFolder.fromMap(map)).toList();
  }

  /// 获取指定父文件夹下的所有子文件夹
  Future<List<MemoFolder>> getFoldersByParent(String? parentId) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (parentId == null) {
      maps = await db.query(
        'memo_folders',
        where: 'parentId IS NULL',
        orderBy: 'sortOrder ASC',
      );
    } else {
      maps = await db.query(
        'memo_folders',
        where: 'parentId = ?',
        whereArgs: [parentId],
        orderBy: 'sortOrder ASC',
      );
    }
    return maps.map((map) => MemoFolder.fromMap(map)).toList();
  }

  Future<void> updateMemoFolder(MemoFolder folder) async {
    final db = await database;
    await db.update(
      'memo_folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  /// 级联删除：递归删除文件夹及其所有子文件夹和备忘录
  Future<void> deleteMemoFolderCascade(String id) async {
    final db = await database;
    // 先递归删除所有子文件夹
    final children = await getFoldersByParent(id);
    for (final child in children) {
      await deleteMemoFolderCascade(child.id);
    }
    // 删除此文件夹下的所有备忘录
    await db.delete('memos', where: 'folderId = ?', whereArgs: [id]);
    // 删除文件夹本身
    await db.delete('memo_folders', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Memo CRUD ====================

  Future<void> insertMemo(Memo memo) async {
    final db = await database;
    await db.insert(
      'memos',
      memo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Memo>> getMemosByFolder(String? folderId) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (folderId == null) {
      maps = await db.query(
        'memos',
        where: 'folderId IS NULL',
        orderBy: 'updatedAt DESC',
      );
    } else {
      maps = await db.query(
        'memos',
        where: 'folderId = ?',
        whereArgs: [folderId],
        orderBy: 'updatedAt DESC',
      );
    }
    return maps.map((map) => Memo.fromMap(map)).toList();
  }

  Future<List<Memo>> getAllMemos() async {
    final db = await database;
    final maps = await db.query('memos', orderBy: 'updatedAt DESC');
    return maps.map((map) => Memo.fromMap(map)).toList();
  }

  Future<void> updateMemo(Memo memo) async {
    final db = await database;
    await db.update(
      'memos',
      memo.toMap(),
      where: 'id = ?',
      whereArgs: [memo.id],
    );
  }

  Future<void> deleteMemo(String id) async {
    final db = await database;
    await db.delete('memos', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Habit CRUD ====================

  Future<void> insertHabit(Habit habit) async {
    final db = await database;
    await db.insert(
      'habits',
      habit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Habit>> getAllHabits() async {
    final db = await database;
    final maps = await db.query('habits', orderBy: 'createdAt ASC');
    return maps.map((m) => Habit.fromMap(m)).toList();
  }

  Future<void> deleteHabit(String id) async {
    final db = await database;
    await db.delete('habit_completions', where: 'habitId = ?', whereArgs: [id]);
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await database;
    await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<void> insertHabitCompletion(HabitCompletion c) async {
    final db = await database;
    await db.insert(
      'habit_completions',
      c.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteHabitCompletion(String habitId, String date) async {
    final db = await database;
    await db.delete(
      'habit_completions',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, date],
    );
  }

  Future<List<HabitCompletion>> getCompletionsByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'habit_completions',
      where: 'date = ?',
      whereArgs: [date],
    );
    return maps.map((m) => HabitCompletion.fromMap(m)).toList();
  }

  /// 获取所有习惯完成记录
  Future<List<HabitCompletion>> getAllCompletions() async {
    final db = await database;
    final maps = await db.query('habit_completions');
    return maps.map((m) => HabitCompletion.fromMap(m)).toList();
  }
}
