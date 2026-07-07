import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class S {
  static S of(BuildContext context) {
    final lang = context.watch<SettingsProvider>().language;
    return S._(lang);
  }

  static S read(BuildContext context) {
    final lang = context.read<SettingsProvider>().language;
    return S._(lang);
  }

  final String _lang;
  S._(this._lang);

  bool get isCn => _lang == 'zh';

  // ── 通用 ──
  String get cancel => isCn ? '取消' : 'Cancel';
  String get delete => isCn ? '删除' : 'Delete';
  String get create => isCn ? '创建' : 'Create';
  String get confirm => isCn ? '确认' : 'Confirm';
  String get ok => isCn ? '确定' : 'OK';
  String get save => isCn ? '已保存' : 'Saved';
  String get confirmDelete => isCn ? '确认删除' : 'Confirm Delete';

  // ── 底部导航 ──
  String get navTasks => isCn ? '短期任务' : 'Tasks';
  String get navCalendar => isCn ? '日历视图' : 'Calendar';
  String get navMemo => isCn ? '长期规划' : 'Plans';
  String get navSettings => isCn ? '设置' : 'Settings';
  List<String> get navLabels => [navTasks, navCalendar, navMemo, navSettings];

  // ── 短期任务页 ──
  String get tasksTitle => isCn ? '短期任务' : 'Tasks';
  String get tapToSetDeadline => isCn ? '点击设置截止日期' : 'Tap to set deadline';
  String get daysRemaining => isCn ? '天剩余' : 'days left';
  String deadlineDate(int month, int day) =>
      isCn ? '截止 $month月$day日' : 'Due $month/$day';
  String get noTasksYet => isCn ? '还没有任务' : 'No tasks yet';
  String get tapToCreateTask =>
      isCn ? '点击右下角 + 创建量化任务' : 'Tap + to create a task';
  String get newTask => isCn ? '新建任务' : 'New Task';
  String get taskNameHint => isCn ? '任务名称' : 'Task name';
  String get targetAmountHint => isCn ? '目标数量' : 'Target';
  String get unitHint => isCn ? '单位' : 'Unit';
  String get fillAllFields => isCn ? '请填写完整信息' : 'Please fill in all fields';
  String recordTitle(String name) => isCn ? '记录 · $name' : 'Record · $name';
  String remaining(String amount, String unit) =>
      isCn ? '剩余 $amount $unit' : '$amount $unit remaining';
  String get completedAmountHint => isCn ? '完成数量' : 'Amount';
  String get noteHint => isCn ? '备注（可选）' : 'Note (optional)';
  String recorded(String amount, String unit) =>
      isCn ? '已记录 $amount $unit' : 'Recorded $amount $unit';
  String get completionRecords => isCn ? '完成记录' : 'Records';
  String recordCount(int count) => isCn ? '$count 条' : '$count';
  String get noRecords => isCn ? '暂无记录' : 'No records';
  String get pin => isCn ? '置顶' : 'Pin';
  String get unpin => isCn ? '取消置顶' : 'Unpin';
  String get hideTask => isCn ? '收纳' : 'Archive';
  String get unhideTask => isCn ? '取出' : 'Unarchive';
  String get hiddenTasks => isCn ? '已收纳' : 'Archived';
  String deleteTaskConfirm(String name) =>
      isCn ? '确定要删除「$name」吗？所有记录也会被删除。' : 'Delete "$name"? All records will be removed.';
  String get unitRemaining => isCn ? '剩余' : 'left';
  String unitRemainingLabel(String unit) => isCn ? '$unit剩余' : '$unit left';
  String get record => isCn ? '记录' : 'Log';
  String get editTask => isCn ? '编辑任务' : 'Edit Task';
  String get taskNoteHint => isCn ? '备注（可选）' : 'Note (optional)';
  String get saved => isCn ? '已保存' : 'Saved';
  String get selectMode => isCn ? '选择' : 'Select';
  String selectedCount(int n) => isCn ? '已选 $n 项' : '$n selected';
  String batchDeleteConfirm(int n) =>
      isCn ? '确定要删除选中的 $n 个任务吗？所有记录也会被删除。' : 'Delete $n selected tasks? All records will be removed.';
  String get donation => isCn ? '打赏' : 'Donate';
  String get donationDesc => isCn ? '\ud83d\ude04 做的不错，赏！' : '\ud83d\ude04 Great job, take my money!';
  String get feedbackDesc => isCn ? '\ud83d\ude23 做的好拉，来人！' : '\ud83d\ude23 This is terrible, help!';
  String get contactTitle => isCn ? '联系作者' : 'Contact';
  // ── 日历页 ──
  String get calendarTitle => isCn ? '日历' : 'Calendar';
  String get overviewMode => isCn ? '总览模式' : 'Overview';
  String get dayMode => isCn ? '单日模式' : 'Day view';
  String scheduleDate(int month, int day) =>
      isCn ? '$month月$day日 日程' : 'Schedule $month/$day';
  String itemCount(int count) => isCn ? '$count 项' : '$count';
  String get noSchedule => isCn ? '暂无日程安排' : 'No schedules';
  String fullDate(int year, int month, int day) =>
      isCn ? '$year年$month月$day日' : '$month/$day/$year';
  String get noScheduleToday => isCn ? '当天暂无安排' : 'Nothing scheduled';
  String planned(String amount) => isCn ? '计划: $amount' : 'Plan: $amount';
  String planAndDone(String plan, String done) =>
      isCn ? '计划: $plan  完成: $done' : 'Plan: $plan  Done: $done';
  String get recordCompletion => isCn ? '记录完成量' : 'Record Completion';
  String get actualAmountHint => isCn ? '实际完成数量' : 'Actual amount';
  String get confirmComplete => isCn ? '确认完成' : 'Complete';
  String get addSchedule => isCn ? '添加日程' : 'Add Schedule';
  String get linkTask => isCn ? '关联任务（可选）' : 'Link task (optional)';
  String get independent => isCn ? '无（独立事项）' : 'None (independent)';
  String taskRemaining(String name, String amount, String unit) =>
      isCn ? '$name（剩 $amount $unit）' : '$name ($amount $unit left)';
  String get scheduleContentHint => isCn ? '日程内容' : 'Schedule title';
  String get plannedAmountHint => isCn ? '计划完成量' : 'Planned amount';
  String startTime(String time) => isCn ? '开始 $time' : 'Start $time';
  String endTime(String time) => isCn ? '结束 $time' : 'End $time';
  String get add => isCn ? '添加' : 'Add';
  String calendarNote(String start, String end) =>
      isCn ? '日历: $start-$end' : 'Calendar: $start-$end';

  // ── 工作时间段 ──
  String get workPeriods => isCn ? '时间段预设' : 'Time Presets';
  String get manageWorkPeriods => isCn ? '管理工作时间段' : 'Manage Work Periods';
  String get addPeriod => isCn ? '添加时间段' : 'Add Period';
  String get periodNameHint => isCn ? '名称（如：上午）' : 'Name (e.g. Morning)';
  String get noPeriods => isCn ? '暂无时间段预设，点击下方添加' : 'No presets yet, tap below to add';
  String get quickSelect => isCn ? '快速选择' : 'Quick Select';
  String get customTime => isCn ? '自定义' : 'Custom';
  String get presetPeriods => isCn ? '时间段' : 'Presets';

  // ── 长期规划页 ──
  String get memoTitle => isCn ? '长期规划' : 'Plans';
  String get emptyFolder => isCn ? '空文件夹' : 'Empty folder';
  String get allFiles => isCn ? '全部文件' : 'All files';
  String get newItem => isCn ? '新建' : 'New';
  String get newFolder => isCn ? '新建文件夹' : 'New Folder';
  String get newMemo => isCn ? '新建文件' : 'New File';
  String get folderNameHint => isCn ? '文件夹名称' : 'Folder name';
  String get rename => isCn ? '重命名' : 'Rename';
  String deleteFolderConfirm(String name) =>
      isCn ? '将永久删除「$name」及其所有内容，此操作不可恢复。' : 'Permanently delete "$name" and all its contents? This cannot be undone.';
  String get renameFolder => isCn ? '重命名文件夹' : 'Rename Folder';
  String get moveTo => isCn ? '移动到...' : 'Move to...';
  String get moveToFolder => isCn ? '移动到' : 'Move to';
  String get rootFolder => isCn ? '根目录' : 'Root';
  String moved(String name) => isCn ? '已移动「$name」' : 'Moved "$name"';

  // ── 备忘录编辑页 ──
  String get editMemo => isCn ? '编辑长期规划' : 'Edit Plan';
  String get untitled => isCn ? '无标题' : 'Untitled';
  String get startWriting => isCn ? '开始写点什么...' : 'Start writing...';
  String get defaultMemoTitle => isCn ? '新规划' : 'New Plan';

  // ── 每日习惯 ──
  String get habits => isCn ? '每日习惯' : 'Daily Habits';
  String get addHabit => isCn ? '添加习惯' : 'Add Habit';
  String get habitNameHint => isCn ? '习惯名称' : 'Habit name';
  String get noHabitsYet => isCn ? '还没有习惯，点击 + 添加' : 'No habits yet, tap + to add';
  String get treeHealthy => isCn ? '🌳 茁壮成长' : '🌳 Thriving';
  String get treeGood => isCn ? '🌲 状态良好' : '🌲 Healthy';
  String get treeWilting => isCn ? '🌿 有些枯萎' : '🌿 Wilting';
  String get treeDying => isCn ? '🥀 即将枯萎' : '🥀 Dying';
  String get treeDead => isCn ? '🍂 已经枯萎' : '🍂 Withered';
  String get yesterdayHabits => isCn ? '昨日完成' : 'Yesterday';
  String get todayHabits => isCn ? '今日打卡' : 'Today';

  // ── 设置页 ──
  String get settingsTitle => isCn ? '设置' : 'Settings';
  String get appearance => isCn ? '外观' : 'Appearance';
  String get darkMode => isCn ? '深色模式' : 'Dark Mode';
  String get enabled => isCn ? '已开启' : 'Enabled';
  String get disabled => isCn ? '已关闭' : 'Disabled';
  String get targetDate => isCn ? '目标日期' : 'Target Date';
  String get deadlineDateLabel => isCn ? 'Deadline 日期' : 'Deadline Date';
  String get notSet => isCn ? '未设置' : 'Not set';
  String get clear => isCn ? '清除' : 'Clear';
  String deadlineInfo(int year, int month, int day, int remaining) =>
      isCn ? '$year/$month/$day  · 还剩 $remaining 天' : '$year/$month/$day  · $remaining days left';
  String get pageOrder => isCn ? '页面顺序' : 'Page Order';
  String get dragToReorder =>
      isCn ? '长按拖拽来调整底部导航栏的页面顺序' : 'Long press and drag to reorder navigation tabs';
  String get language => isCn ? '语言' : 'Language';
  String get languageLabel => isCn ? '中文 / English' : 'English / 中文';
  String get currentLanguage => isCn ? '中文' : 'English';
  String get about => isCn ? '关于' : 'About';
  String get appSubtitle => isCn ? '极简任务管理 · v1.0.0' : 'Minimalist Task Manager · v1.0.0';
}
