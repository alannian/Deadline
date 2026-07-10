import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import '../l10n/app_strings.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key, required this.onShowPlanning});

  final VoidCallback onShowPlanning;

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  bool _selectMode = false;
  final Set<String> _selectedIds = {};
  bool _showHidden = false;

  @override
  void initState() {
    super.initState();
    final tp = context.read<TaskProvider>();
    Future.microtask(() {
      tp.loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectMode ? s.selectedCount(_selectedIds.length) : s.checklistMode,
        ),
        leading: _selectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selectMode = false;
                  _selectedIds.clear();
                }),
              )
            : null,
        actions: [
          if (_selectMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all_rounded),
              onPressed: () {
                final tasks = context.read<TaskProvider>().tasks;
                setState(() {
                  if (_selectedIds.length == tasks.length) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds
                      ..clear()
                      ..addAll(tasks.map((t) => t.id));
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.red),
              onPressed: _selectedIds.isEmpty
                  ? null
                  : () => _confirmBatchDelete(context),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist_rounded),
              onPressed: () => setState(() => _selectMode = true),
            ),
          ],
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'showPlanning',
              tooltip: s.planningMode,
              onPressed: widget.onShowPlanning,
              child: const Icon(Icons.calendar_month_rounded),
            ),
            FloatingActionButton(
              heroTag: 'addTask',
              onPressed: settings.activeTasksLocked
                  ? () => _showLockedMessage(context)
                  : () => _showCreateTaskDialog(context),
              child: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 倒计时头部
          Consumer<TaskProvider>(
            builder: (context, taskProvider, _) =>
                _buildDeadlineHeader(context, settings, taskProvider, isDark),
          ),

          // 任务列表
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, child) {
                final visibleTasks = provider.tasks;
                final hidden = provider.hiddenTasks;
                if (visibleTasks.isEmpty && hidden.isEmpty) {
                  return _buildEmptyState(isDark);
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  children: [
                    // 可见任务
                    ...visibleTasks.asMap().entries.map((e) {
                      final task = e.value;
                      final locked = _isTaskLocked(task, settings);
                      if (_selectMode) {
                        final selected = _selectedIds.contains(task.id);
                        return Row(
                          children: [
                            Checkbox(
                              value: selected,
                              onChanged: (_) => setState(() {
                                selected
                                    ? _selectedIds.remove(task.id)
                                    : _selectedIds.add(task.id);
                              }),
                            ),
                            Expanded(
                              child: TaskCard(
                                task: task,
                                isLocked: locked,
                                onTap: () => setState(() {
                                  selected
                                      ? _selectedIds.remove(task.id)
                                      : _selectedIds.add(task.id);
                                }),
                                onRecord: () {},
                                onDelete: () {},
                              ),
                            ),
                          ],
                        );
                      }
                      return TaskCard(
                        task: task,
                        isLocked: locked,
                        onTap: () => _showTaskDetail(context, task),
                        onRecord: () => locked
                            ? _showLockedMessage(context)
                            : _showRecordDialog(context, task),
                        onDelete: () => _showTaskMenu(context, task),
                      );
                    }),
                    // 已收纳分区
                    if (hidden.isNotEmpty && !_selectMode) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(() => _showHidden = !_showHidden),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _showHidden
                                    ? Icons.inventory_2_rounded
                                    : Icons.inventory_2_outlined,
                                size: 18,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                s.hiddenTasks,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${hidden.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                _showHidden
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                size: 18,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showHidden)
                        ...hidden.map(
                          (task) => Opacity(
                            opacity: 0.6,
                            child: TaskCard(
                              task: task,
                              isLocked: false,
                              onTap: () => _showTaskDetail(context, task),
                              onRecord: () => _showRecordDialog(context, task),
                              onDelete: () => _showTaskMenu(context, task),
                            ),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineHeader(
    BuildContext context,
    SettingsProvider settings,
    TaskProvider taskProvider,
    bool isDark,
  ) {
    final s = S.of(context);
    final activeTasks = taskProvider.tasks;
    final total = activeTasks.fold<double>(
      0,
      (sum, task) => sum + task.targetAmount,
    );
    final done = activeTasks.fold<double>(
      0,
      (sum, task) =>
          sum + task.completedAmount.clamp(0, task.targetAmount).toDouble(),
    );
    final progress = total > 0
        ? (done / total).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final reward = settings.deadlineReward?.trim();
    final showReward = reward != null && reward.isNotEmpty;
    final rewardActive =
        settings.deadline != null && settings.remainingDays == 1;

    return InkWell(
      onTap: () => _pickDeadline(context, settings),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF42A5F5).withValues(alpha: 0.15),
                    Colors.transparent,
                  ]
                : [
                    const Color(0xFF42A5F5).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: settings.deadline == null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.tapToSetDeadline,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${settings.remainingDays}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: settings.remainingDays <= 7
                              ? Colors.red
                              : const Color(0xFF42A5F5),
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.daysRemaining,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          Text(
                            s.deadlineDate(
                              settings.deadline!.month,
                              settings.deadline!.day,
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        Icons.edit_calendar_outlined,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                        settings.activeTasksLocked
                            ? Colors.grey
                            : const Color(0xFF42A5F5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${s.totalProgress} ${_formatAmount(done)}/${_formatAmount(total)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      if (showReward)
                        Flexible(
                          child: Text(
                            '${s.reward}: $reward',
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: rewardActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: rewardActive
                                  ? const Color(0xFFFFB300)
                                  : (isDark
                                        ? Colors.grey[600]
                                        : Colors.grey[500]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final s = S.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 72,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            s.noTasksYet,
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.tapToCreateTask,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _pickDeadline(BuildContext context, SettingsProvider settings) async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('zh', 'CN'),
      initialDate:
          settings.deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      if (!context.mounted) return;
      final reward = await _askReward(context, settings.deadlineReward);
      if (reward == null || reward.trim().isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(S.read(context).rewardRequired)));
        return;
      }
      await settings.setDeadlineWithReward(picked, reward);
    }
  }

  Future<String?> _askReward(BuildContext context, String? initialReward) {
    final ctrl = TextEditingController(text: initialReward ?? '');
    final s = S.read(context);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.setDeadlineReward),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: s.rewardHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(s.ok),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final s = S.read(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.newTask),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: InputDecoration(hintText: s.taskNameHint),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(hintText: s.targetAmountHint),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: unitCtrl,
                      decoration: InputDecoration(hintText: s.unitHint),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  hintText: s.taskNoteHint,
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                minLines: 3,
              ),
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
              final title = titleCtrl.text.trim();
              final unit = unitCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text.trim());
              if (title.isEmpty ||
                  unit.isEmpty ||
                  amount == null ||
                  amount <= 0) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(s.fillAllFields)));
                return;
              }
              context.read<TaskProvider>().createTask(
                title: title,
                unit: unit,
                targetAmount: amount,
                note: noteCtrl.text.trim().isEmpty
                    ? null
                    : noteCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: Text(s.create),
          ),
        ],
      ),
    );
  }

  void _showRecordDialog(BuildContext context, Task task) {
    if (_isTaskLocked(task, context.read<SettingsProvider>())) {
      _showLockedMessage(context);
      return;
    }
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final s = S.read(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.recordTitle(task.title)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.remaining(_formatAmount(task.remainingAmount), task.unit),
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: s.completedAmountHint,
                suffixText: task.unit,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(hintText: s.noteHint),
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
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null || amount <= 0) return;
              context.read<TaskProvider>().recordCompletion(
                taskId: task.id,
                amount: amount,
                note: noteCtrl.text.trim().isEmpty
                    ? null
                    : noteCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(s.recorded(_formatAmount(amount), task.unit)),
                ),
              );
            },
            child: Text(s.confirm),
          ),
        ],
      ),
    );
  }

  void _showTaskDetail(BuildContext context, Task task) {
    final provider = context.read<TaskProvider>();
    provider.loadRecords(task.id);
    final locked = _isTaskLocked(task, context.read<SettingsProvider>());

    // 颜色优先级同 TaskCard
    final Color color;
    if (task.isCompleted) {
      color = Colors.green;
    } else if (task.isPinned) {
      color = Colors.red;
    } else {
      color = const Color(0xFF42A5F5);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.read(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollCtrl) => Consumer<TaskProvider>(
          builder: (ctx, provider, _) {
            return Column(
              children: [
                // 手柄
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatAmount(task.completedAmount)} / ${_formatAmount(task.targetAmount)} ${task.unit}',
                        style: TextStyle(color: color, fontSize: 16),
                      ),
                      if (task.note != null && task.note!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          task.note!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        s.completionRecords,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        s.recordCount(provider.currentRecords.length),
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: provider.currentRecords.isEmpty
                      ? Center(
                          child: Text(
                            s.noRecords,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[500],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: provider.currentRecords.length,
                          itemBuilder: (ctx, index) {
                            final record = provider.currentRecords[index];
                            return ListTile(
                              leading: Icon(
                                Icons.check_circle_outline,
                                color: color,
                                size: 20,
                              ),
                              title: Text(
                                '+${_formatAmount(record.amount)} ${task.unit}',
                              ),
                              subtitle: Text(
                                '${record.date.month}/${record.date.day} ${record.date.hour}:${record.date.minute.toString().padLeft(2, '0')}${record.note != null ? '  ${record.note}' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                ),
                                onPressed: locked
                                    ? null
                                    : () => provider.deleteRecord(record),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showTaskMenu(BuildContext context, Task task) {
    final provider = context.read<TaskProvider>();
    final s = S.read(context);
    final locked = _isTaskLocked(task, context.read<SettingsProvider>());
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(task.title),
        children: [
          if (locked)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Text(
                s.deadlineLocked,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[500]
                      : Colors.grey[600],
                ),
              ),
            )
          else
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                _showEditTaskDialog(context, task);
              },
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 20),
                  const SizedBox(width: 12),
                  Text(s.editTask),
                ],
              ),
            ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              provider.togglePin(task);
            },
            child: Row(
              children: [
                Icon(
                  task.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(task.isPinned ? s.unpin : s.pin),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              provider.toggleHidden(task);
            },
            child: Row(
              children: [
                Icon(
                  task.isHidden
                      ? Icons.inventory_2_outlined
                      : Icons.inventory_2_rounded,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(task.isHidden ? s.unhideTask : s.hideTask),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelete(context, task);
            },
            child: Row(
              children: [
                const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                const SizedBox(width: 12),
                Text(s.delete, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    if (_isTaskLocked(task, context.read<SettingsProvider>())) {
      _showLockedMessage(context);
      return;
    }
    final titleCtrl = TextEditingController(text: task.title);
    final unitCtrl = TextEditingController(text: task.unit);
    final amountCtrl = TextEditingController(
      text: _formatAmount(task.targetAmount),
    );
    final noteCtrl = TextEditingController(text: task.note ?? '');
    final s = S.read(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.editTask),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(hintText: s.taskNameHint),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(hintText: s.targetAmountHint),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: unitCtrl,
                      decoration: InputDecoration(hintText: s.unitHint),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  hintText: s.taskNoteHint,
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                minLines: 3,
              ),
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
              final title = titleCtrl.text.trim();
              final unit = unitCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text.trim());
              if (title.isEmpty ||
                  unit.isEmpty ||
                  amount == null ||
                  amount <= 0) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(s.fillAllFields)));
                return;
              }
              final updated = task.copyWith(
                title: title,
                unit: unit,
                targetAmount: amount,
                note: noteCtrl.text.trim().isEmpty
                    ? null
                    : noteCtrl.text.trim(),
                clearNote: noteCtrl.text.trim().isEmpty,
              );
              context.read<TaskProvider>().updateTask(updated);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(s.saved),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Text(s.ok),
          ),
        ],
      ),
    );
  }

  void _confirmBatchDelete(BuildContext context) {
    final s = S.read(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.confirmDelete),
        content: Text(s.batchDeleteConfirm(_selectedIds.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskProvider>().deleteTasks(_selectedIds.toList());
              Navigator.pop(ctx);
              setState(() {
                _selectMode = false;
                _selectedIds.clear();
              });
            },
            child: Text(s.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Task task) {
    final s = S.read(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.confirmDelete),
        content: Text(s.deleteTaskConfirm(task.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskProvider>().deleteTask(task.id);
              Navigator.pop(ctx);
            },
            child: Text(s.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(1);
  }

  bool _isTaskLocked(Task task, SettingsProvider settings) {
    return !task.isHidden && settings.activeTasksLocked;
  }

  void _showLockedMessage(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(S.read(context).deadlineLocked)));
  }
}
