import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/database_service.dart';

/// 工作时间段预设
class TimePeriod {
  final String name;
  final int startMinutes;
  final int endMinutes;

  TimePeriod({
    required this.name,
    required this.startMinutes,
    required this.endMinutes,
  });

  String get startStr {
    final h = startMinutes ~/ 60;
    final m = startMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String get endStr {
    final h = endMinutes ~/ 60;
    final m = endMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'start': startMinutes,
        'end': endMinutes,
      };

  factory TimePeriod.fromMap(Map<String, dynamic> map) => TimePeriod(
        name: map['name'] as String,
        startMinutes: map['start'] as int,
        endMinutes: map['end'] as int,
      );
}

class SettingsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  DateTime? _deadline;
  DateTime? get deadline => _deadline;

  String? _deadlineReward;
  String? get deadlineReward => _deadlineReward;

  List<int> _pageOrder = [0, 1, 2, 3];
  List<int> get pageOrder => _pageOrder;

  String _language = 'zh';
  String get language => _language;

  List<TimePeriod> _timePeriods = [];
  List<TimePeriod> get timePeriods => _timePeriods;

  /// 剩余天数（含今天，明天截止则显示1）
  int get remainingDays {
    if (_deadline == null) return -1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dl = DateTime(_deadline!.year, _deadline!.month, _deadline!.day);
    final diff = dl.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get activeTasksLocked => _deadline != null && remainingDays <= 0;

  /// 加载设置
  Future<void> loadSettings() async {
    // 主题
    final themeStr = await _db.getSetting('themeMode');
    _themeMode =
        themeStr == 'light' ? ThemeMode.light : ThemeMode.dark;

    // 截止日期
    final deadlineStr = await _db.getSetting('deadline');
    if (deadlineStr != null) {
      if (deadlineStr.isNotEmpty) {
        _deadline =
            DateTime.fromMillisecondsSinceEpoch(int.parse(deadlineStr));
      }
    }

    final rewardStr = await _db.getSetting('deadlineReward');
    if (rewardStr != null && rewardStr.trim().isNotEmpty) {
      _deadlineReward = rewardStr;
    }

    // 页面顺序
    final orderStr = await _db.getSetting('pageOrder');
    if (orderStr != null) {
      _pageOrder = orderStr.split(',').map(int.parse).toList();
      // 校验
      if (_pageOrder.length != 4 ||
          !{0, 1, 2, 3}.containsAll(_pageOrder.toSet())) {
        _pageOrder = [0, 1, 2, 3];
      }
    }

    // 语言
    final langStr = await _db.getSetting('language');
    if (langStr != null) {
      _language = langStr;
    }

    // 工作时间段预设
    final periodsStr = await _db.getSetting('timePeriods');
    if (periodsStr != null && periodsStr.isNotEmpty) {
      final list = jsonDecode(periodsStr) as List;
      _timePeriods = list.map((e) => TimePeriod.fromMap(e)).toList();
    }

    notifyListeners();
  }

  /// 切换主题
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _db.setSetting(
        'themeMode', mode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  /// 设置截止日期
  Future<void> setDeadline(DateTime? date) async {
    _deadline = date;
    if (date != null) {
      await _db.setSetting(
          'deadline', date.millisecondsSinceEpoch.toString());
    } else {
      await _db.setSetting('deadline', '');
    }
    notifyListeners();
  }

  Future<void> setDeadlineWithReward(DateTime date, String reward) async {
    _deadline = date;
    _deadlineReward = reward.trim();
    await _db.setSetting(
        'deadline', date.millisecondsSinceEpoch.toString());
    await _db.setSetting('deadlineReward', _deadlineReward!);
    notifyListeners();
  }

  Future<void> clearDeadline() async {
    _deadline = null;
    _deadlineReward = null;
    await _db.setSetting('deadline', '');
    await _db.setSetting('deadlineReward', '');
    notifyListeners();
  }

  /// 设置页面顺序
  Future<void> setPageOrder(List<int> order) async {
    _pageOrder = order;
    await _db.setSetting('pageOrder', order.join(','));
    notifyListeners();
  }

  /// 设置语言
  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _db.setSetting('language', lang);
    notifyListeners();
  }

  /// 添加工作时间段预设
  Future<void> addTimePeriod(TimePeriod period) async {
    _timePeriods.add(period);
    await _saveTimePeriods();
    notifyListeners();
  }

  /// 删除工作时间段预设
  Future<void> removeTimePeriod(int index) async {
    _timePeriods.removeAt(index);
    await _saveTimePeriods();
    notifyListeners();
  }

  Future<void> _saveTimePeriods() async {
    final json = jsonEncode(_timePeriods.map((e) => e.toMap()).toList());
    await _db.setSetting('timePeriods', json);
  }
}
