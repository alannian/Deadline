import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/schedule_provider.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/habit_provider.dart';
import '../models/schedule.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  bool _isDayView = true; // false=总览, true=单日视图

  @override
  void initState() {
    super.initState();
    final sp = context.read<ScheduleProvider>();
    final tp = context.read<TaskProvider>();
    Future.microtask(() {
      sp.selectDate(DateTime.now());
      sp.loadAllSchedules();
      tp.loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.calendarTitle),
        actions: [
          // 工作时间段设置
          IconButton(
            icon: const Icon(Icons.schedule_rounded),
            tooltip: s.workPeriods,
            onPressed: () => _showManagePeriodsDialog(context),
          ),
          // 切换视图
          IconButton(
            icon: Icon(_isDayView
                ? Icons.calendar_month_rounded
                : Icons.view_day_rounded),
            tooltip: _isDayView ? s.overviewMode : s.dayMode,
            onPressed: () => setState(() => _isDayView = !_isDayView),
          ),
        ],
      ),
      floatingActionButton: Consumer<HabitProvider>(
        builder: (context, habitProv, _) {
          final score = habitProv.score;
          return SizedBox(
            width: MediaQuery.of(context).size.width - 32,
            height: 70,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomLeft,
                  child: habitProv.habits.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _showHabitsManageDialog(context),
                          child: _buildEnergyBall(
                            score,
                            total: habitProv.habits.length,
                            done: habitProv.todayDoneCount,
                          ),
                        )
                      : FloatingActionButton.small(
                          heroTag: 'addHabit',
                          tooltip: s.addHabit,
                          onPressed: () => _showAddHabitDialog(context),
                          child: const Icon(Icons.add_circle_outline_rounded),
                        ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: FloatingActionButton(
                    heroTag: 'addSchedule',
                    onPressed: () => _showCreateScheduleDialog(context),
                    child: const Icon(Icons.add_rounded),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Consumer3<ScheduleProvider, SettingsProvider, HabitProvider>(
        builder: (context, scheduleProv, settingsProv, habitProv, child) {
          return _isDayView
              ? _buildDayView(context, scheduleProv, isDark)
              : _buildOverviewWithCalendar(
                  context, scheduleProv, settingsProv, isDark);
        },
      ),
    );
  }

  // =========== 总览模式（日历 + 当日列表） ===========
  Widget _buildOverviewWithCalendar(BuildContext context,
      ScheduleProvider provider, SettingsProvider settings, bool isDark) {
    final s = S.of(context);
    final deadline = settings.deadline;
    DateTime focusedDay = provider.selectedDate;

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: deadline ?? DateTime.now().add(const Duration(days: 365)),
          focusedDay: focusedDay,
          calendarFormat: CalendarFormat.month,
          locale: 'zh_CN',
          selectedDayPredicate: (day) =>
              isSameDay(day, provider.selectedDate),
          onDaySelected: (selectedDay, focused) {
            provider.selectDate(selectedDay);
          },
          enabledDayPredicate: deadline != null
              ? (day) {
                  final today = DateTime(DateTime.now().year,
                      DateTime.now().month, DateTime.now().day);
                  final dl = DateTime(
                      deadline.year, deadline.month, deadline.day);
                  return !day.isBefore(today) && !day.isAfter(dl);
                }
              : null,
          eventLoader: (day) {
            final key = DateTime(day.year, day.month, day.day);
            return provider.allSchedulesMap[key] ?? [];
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: isDark
                  ? AppTheme.accentColor
                  : const Color(0xFF42A5F5).withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppTheme.highlightColor,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: Color(0xFF42A5F5),
              shape: BoxShape.circle,
            ),
            markerSize: 6,
            markersMaxCount: 3,
            disabledTextStyle: TextStyle(
                color: isDark ? Colors.grey[800] : Colors.grey[400]),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const Divider(height: 1),
        // 日程标题
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Text(
                s.scheduleDate(provider.selectedDate.month, provider.selectedDate.day),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(s.itemCount(provider.daySchedules.length),
                  style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 14)),
            ],
          ),
        ),
        // 日程列表
        Expanded(
          child: provider.daySchedules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available_rounded,
                          size: 48,
                          color:
                              isDark ? Colors.grey[700] : Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(s.noSchedule,
                          style: TextStyle(
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.daySchedules.length,
                  itemBuilder: (context, index) {
                    return _buildScheduleItem(
                        context, provider.daySchedules[index], isDark);
                  },
                ),
        ),
      ],
    );
  }

  // =========== 单日视图（时间轴） ===========
  Widget _buildDayView(
      BuildContext context, ScheduleProvider provider, bool isDark) {
    final s = S.of(context);
    return Column(
      children: [
        // 日期导航
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  final prev = provider.selectedDate
                      .subtract(const Duration(days: 1));
                  provider.selectDate(prev);
                },
              ),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: provider.selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) provider.selectDate(picked);
                },
                child: Text(
                  s.fullDate(provider.selectedDate.year, provider.selectedDate.month, provider.selectedDate.day),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  final next =
                      provider.selectedDate.add(const Duration(days: 1));
                  provider.selectDate(next);
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 时间轴
        Expanded(
          child: provider.daySchedules.isEmpty
              ? Center(
                  child: Text(s.noScheduleToday,
                      style: TextStyle(
                          color:
                              isDark ? Colors.grey[600] : Colors.grey[500])),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.daySchedules.length,
                  itemBuilder: (context, index) {
                    final schedule = provider.daySchedules[index];
                    return _buildTimelineItem(
                        context, schedule, isDark, index == 0,
                        index == provider.daySchedules.length - 1);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, Schedule schedule,
      bool isDark, bool isFirst, bool isLast) {
    final s = S.of(context);
    final color = Color(schedule.colorValue);
    final duration = schedule.durationMinutes;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 时间列
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(schedule.startTimeStr,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (duration > 0)
                  Text(schedule.endTimeStr,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark ? Colors.grey[500] : Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 时间线
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // 内容卡片
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _onScheduleTap(context, schedule),
                onLongPress: () => _showScheduleOptions(context, schedule),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              schedule.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                decoration: schedule.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: schedule.isCompleted
                                    ? (isDark ? Colors.grey : Colors.grey[600])
                                    : null,
                              ),
                            ),
                          ),
                          if (schedule.isCompleted)
                            const Icon(Icons.check_circle_rounded,
                                color: AppTheme.successColor, size: 20),
                        ],
                      ),
                      if (schedule.plannedAmount != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          schedule.completedAmount != null
                              ? s.planAndDone(_formatAmount(schedule.plannedAmount!), _formatAmount(schedule.completedAmount!))
                              : s.planned(_formatAmount(schedule.plannedAmount!)),
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(
      BuildContext context, Schedule schedule, bool isDark) {
    final s = S.of(context);
    final color = Color(schedule.colorValue);
    return Dismissible(
      key: Key(schedule.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) =>
          context.read<ScheduleProvider>().deleteSchedule(schedule.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onScheduleTap(context, schedule),
          onLongPress: () => _showScheduleOptions(context, schedule),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 时间
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(schedule.startTimeStr,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(schedule.endTimeStr,
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.grey[500]
                                : Colors.grey[600])),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  width: 3,
                  height: 40,
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.title,
                        style: TextStyle(
                          fontSize: 15,
                          decoration: schedule.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: schedule.isCompleted
                              ? Colors.grey
                              : null,
                        ),
                      ),
                      if (schedule.plannedAmount != null)
                        Text(
                          s.planned(_formatAmount(schedule.plannedAmount!)),
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                if (schedule.isCompleted)
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.successColor, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onScheduleTap(BuildContext context, Schedule schedule) {
    if (schedule.isCompleted) {
      // 取消完成
      context.read<ScheduleProvider>().uncompleteSchedule(schedule);
      return;
    }

    // 如果关联任务，弹出记录量对话框
    if (schedule.taskId != null) {
      _showCompleteWithAmountDialog(context, schedule);
    } else {
      // 独立事项直接标记完成
      context
          .read<ScheduleProvider>()
          .completeSchedule(schedule);
    }
  }

  void _showScheduleOptions(BuildContext context, Schedule schedule) {
    final s = S.read(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(schedule.title),
        content: Text(
            '${schedule.startTimeStr} - ${schedule.endTimeStr}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<ScheduleProvider>()
                  .deleteSchedule(schedule.id);
              Navigator.pop(ctx);
            },
            child: Text(s.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCompleteWithAmountDialog(
      BuildContext context, Schedule schedule) {
    final s = S.read(context);
    final amountCtrl = TextEditingController(
        text: schedule.plannedAmount != null
            ? _formatAmount(schedule.plannedAmount!)
            : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.recordCompletion),
        content: TextField(
          controller: amountCtrl,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: s.actualAmountHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text.trim());
              final sp = context.read<ScheduleProvider>();
              sp.completeSchedule(schedule, completedAmount: amount);

              if (amount != null && amount > 0 && schedule.taskId != null) {
                context.read<TaskProvider>().recordCompletion(
                      taskId: schedule.taskId!,
                      amount: amount,
                      note: s.calendarNote(schedule.startTimeStr, schedule.endTimeStr),
                    );
              }
              Navigator.pop(ctx);
            },
            child: Text(s.confirmComplete),
          ),
        ],
      ),
    );
  }

  void _showCreateScheduleDialog(BuildContext context) {
    final s = S.read(context);
    final titleCtrl = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    String? selectedTaskId;
    final amountCtrl = TextEditingController();
    bool usePresets = false;
    Set<int> selectedPresets = {};

    final tasks = context.read<TaskProvider>().tasks;
    final periods = context.read<SettingsProvider>().timePeriods;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final selectedTask = selectedTaskId != null
              ? tasks.firstWhere((t) => t.id == selectedTaskId,
                  orElse: () => tasks.first)
              : null;

          return AlertDialog(
            title: Text(s.addSchedule),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 关联任务选择
                  if (tasks.isNotEmpty) ...[
                    Text(s.linkTask,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedTaskId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10)),
                      items: [
                        DropdownMenuItem(
                            value: null, child: Text(s.independent)),
                        ...tasks.map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(
                                s.taskRemaining(t.title, _formatAmount(t.remainingAmount), t.unit),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedTaskId = val;
                          if (val != null) {
                            final t =
                                tasks.firstWhere((t) => t.id == val);
                            titleCtrl.text = t.title;

                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  // 标题
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(hintText: s.scheduleContentHint),
                  ),
                  const SizedBox(height: 12),
                  // 计划量（仅关联任务时）
                  if (selectedTask != null) ...[
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        hintText: s.plannedAmountHint,
                        suffixText: selectedTask.unit,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // ── 时间选择模式 ──
                  if (periods.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                              value: false, label: Text(s.customTime)),
                          ButtonSegment(
                              value: true, label: Text(s.presetPeriods)),
                        ],
                        selected: {usePresets},
                        onSelectionChanged: (set) {
                          setDialogState(() => usePresets = set.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // ── 自定义时间 ──
                  if (!usePresets) ...[
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                  context: ctx, initialTime: startTime);
                              if (t != null) {
                                setDialogState(() => startTime = t);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .inputDecorationTheme
                                    .fillColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                  s.startTime(startTime.format(ctx)),
                                  textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                  context: ctx, initialTime: endTime);
                              if (t != null) {
                                setDialogState(() => endTime = t);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .inputDecorationTheme
                                    .fillColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                  s.endTime(endTime.format(ctx)),
                                  textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  // ── 时间段预设多选 ──
                  if (usePresets) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: List.generate(periods.length, (i) {
                        final p = periods[i];
                        final sel = selectedPresets.contains(i);
                        return FilterChip(
                          label: Text('${p.name}  ${p.startStr}-${p.endStr}',
                              style: const TextStyle(fontSize: 13)),
                          selected: sel,
                          showCheckmark: true,
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                selectedPresets.add(i);
                              } else {
                                selectedPresets.remove(i);
                              }
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.cancel),
              ),
              TextButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final provider = context.read<ScheduleProvider>();
                  final title = titleCtrl.text.trim();
                  final date = provider.selectedDate;
                  final planned = selectedTaskId != null
                      ? double.tryParse(amountCtrl.text.trim())
                      : null;

                  if (usePresets && selectedPresets.isNotEmpty) {
                    // 多时间段 → 创建多个日程
                    for (final i in selectedPresets) {
                      final p = periods[i];
                      provider.createSchedule(
                        taskId: selectedTaskId,
                        title: title,
                        date: date,
                        startMinutes: p.startMinutes,
                        endMinutes: p.endMinutes,
                        colorValue: 0xFF42A5F5,
                        plannedAmount: planned,
                      );
                    }
                  } else if (!usePresets) {
                    provider.createSchedule(
                      taskId: selectedTaskId,
                      title: title,
                      date: date,
                      startMinutes:
                          startTime.hour * 60 + startTime.minute,
                      endMinutes: endTime.hour * 60 + endTime.minute,
                      colorValue: 0xFF42A5F5,
                      plannedAmount: planned,
                    );
                  }
                  Navigator.pop(ctx);
                },
                child: Text(s.add),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── 管理工作时间段预设 ──
  void _showManagePeriodsDialog(BuildContext context) {
    final s = S.read(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final periods = context.watch<SettingsProvider>().timePeriods;
            return AlertDialog(
              title: Text(s.manageWorkPeriods),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (periods.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(s.noPeriods,
                            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      )
                    else
                      ...List.generate(periods.length, (i) {
                        final p = periods[i];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(p.name),
                          subtitle: Text('${p.startStr} - ${p.endStr}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                            onPressed: () {
                              context.read<SettingsProvider>().removeTimePeriod(i);
                              setDialogState(() {});
                            },
                          ),
                        );
                      }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(s.ok),
                ),
                TextButton(
                  onPressed: () => _showAddPeriodDialog(context, setDialogState),
                  child: Text(s.addPeriod),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddPeriodDialog(BuildContext context, void Function(void Function()) parentSetState) {
    final s = S.read(context);
    final nameCtrl = TextEditingController();
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 12, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(s.addPeriod),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(hintText: s.periodNameHint),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final t = await showTimePicker(context: ctx, initialTime: start);
                        if (t != null) setDialogState(() => start = t);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(s.startTime(start.format(ctx)), textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final t = await showTimePicker(context: ctx, initialTime: end);
                        if (t != null) setDialogState(() => end = t);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(s.endTime(end.format(ctx)), textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                context.read<SettingsProvider>().addTimePeriod(TimePeriod(
                  name: nameCtrl.text.trim(),
                  startMinutes: start.hour * 60 + start.minute,
                  endMinutes: end.hour * 60 + end.minute,
                ));
                parentSetState(() {});
                Navigator.pop(ctx);
              },
              child: Text(s.add),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(1);
  }

  // =========== 能量球 ===========

  Widget _buildEnergyBall(double score,
      {required int total, required int done}) {
    final int remaining = total - done;
    final double progress = total > 0 ? done / total : 1.0;

    // 颜色随分数变化：红(<40) → 橙(40-55) → 蓝(55-70) → 绿(70-85) → 金(>85)
    final Color coreColor;
    if (score < 40) {
      coreColor = const Color(0xFFEF5350);
    } else if (score < 55) {
      coreColor = const Color(0xFFFF9800);
    } else if (score < 70) {
      coreColor = const Color(0xFF42A5F5);
    } else if (score < 85) {
      coreColor = const Color(0xFF66BB6A);
    } else {
      coreColor = const Color(0xFFFFD54F);
    }

    return SizedBox(
      width: 62,
      height: 62,
      child: CustomPaint(
        painter: _EnergyRingPainter(
          progress: progress,
          ringColor: coreColor,
        ),
        child: Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  coreColor.withValues(alpha: 0.95),
                  coreColor.withValues(alpha: 0.55),
                  coreColor.withValues(alpha: 0.2),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: coreColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 高光
                Positioned(
                  top: 6,
                  left: 8,
                  child: Container(
                    width: 14,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // 分数 + 剩余数
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: score.abs() >= 100 ? 9 : 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    if (remaining > 0)
                      Text(
                        '-$remaining',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                      )
                    else
                      Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========== 习惯管理弹窗 ===========

  void _showHabitsManageDialog(BuildContext context) {
    final s = S.read(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer<HabitProvider>(
          builder: (ctx, habitProv, _) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.8,
              builder: (ctx, scrollCtrl) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Text(s.habits,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showAddHabitDialog(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (habitProv.habits.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(s.noHabitsYet,
                              style: TextStyle(color: Colors.grey[500])),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          controller: scrollCtrl,
                          itemCount: habitProv.habits.length,
                          itemBuilder: (ctx, i) {
                            final habit = habitProv.habits[i];
                            final done = habitProv.todayCompletions
                                .containsKey(habit.id);
                            return ListTile(
                              leading: IconButton(
                                icon: Icon(
                                  done
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: done
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey,
                                ),
                                onPressed: () =>
                                    habitProv.toggleToday(habit.id),
                              ),
                              title: Text(
                                habit.name,
                                style: TextStyle(
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: done ? Colors.grey : null,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline_rounded,
                                    size: 20, color: Colors.red[300]),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _confirmDeleteHabit(context, habit);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    final s = S.read(context);
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.addHabit),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: s.habitNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                context.read<HabitProvider>().addHabit(name);
                Navigator.pop(ctx);
              }
            },
            child: Text(s.add),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteHabit(BuildContext context, dynamic habit) {
    final s = S.read(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.confirmDelete),
        content: Text(s.deleteTaskConfirm(habit.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<HabitProvider>().removeHabit(habit.id);
              Navigator.pop(ctx);
            },
            child: Text(s.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );  
  }
}

/// 能量球外圈进度环
class _EnergyRingPainter extends CustomPainter {
  final double progress; // 0.0 ~ 1.0
  final Color ringColor;

  _EnergyRingPainter({required this.progress, required this.ringColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // 背景环
    final bgPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius, bgPaint);

    // 进度环
    if (progress > 0) {
      final fgPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      final sweepAngle = 2 * pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyRingPainter old) =>
      old.progress != progress || old.ringColor != ringColor;
}
