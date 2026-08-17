import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/awareness_goal.dart';
import '../models/habit.dart';
import '../providers/awareness_provider.dart';
import '../providers/habit_provider.dart';
import '../l10n/app_strings.dart';

class AwarenessPage extends StatefulWidget {
  const AwarenessPage({super.key});

  @override
  State<AwarenessPage> createState() => _AwarenessPageState();
}

class _AwarenessPageState extends State<AwarenessPage> {
  @override
  void initState() {
    super.initState();
    final awarenessProvider = context.read<AwarenessProvider>();
    final habitProvider = context.read<HabitProvider>();
    Future.microtask(() {
      awarenessProvider.loadGoals();
      habitProvider.loadHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(s.awarenessTitle)),
      body: Column(
        children: [
          Expanded(
            child: _Section(
              title: s.goals,
              icon: Icons.flag_outlined,
              onAdd: () => _showGoalDialog(context),
              child: Consumer<AwarenessProvider>(
                builder: (context, provider, _) {
                  if (provider.goals.isEmpty) {
                    return _EmptyText(text: s.noGoalsYet);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    itemCount: provider.goals.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final goal = provider.goals[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: SizedBox(
                          width: 32,
                          child: Text(
                            '${index + 1}.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(goal.title),
                        onTap: () => _showGoalDialog(context, goal: goal),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red[300],
                          ),
                          onPressed: () => provider.deleteGoal(goal.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
          Expanded(
            child: _Section(
              title: s.habits,
              icon: Icons.check_circle_outline_rounded,
              onAdd: () => _showHabitDialog(context),
              child: Consumer<HabitProvider>(
                builder: (context, provider, _) {
                  if (provider.habits.isEmpty) {
                    return _EmptyText(text: s.noHabitsYet);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    itemCount: provider.habits.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final habit = provider.habits[index];
                      final done = provider.todayCompletions.containsKey(
                        habit.id,
                      );
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: IconButton(
                          icon: Icon(
                            done
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: done ? Colors.green : Colors.grey,
                          ),
                          onPressed: () => provider.toggleToday(habit.id),
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
                        onTap: () => _showHabitDialog(context, habit: habit),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red[300],
                          ),
                          onPressed: () => provider.removeHabit(habit.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog(BuildContext context, {AwarenessGoal? goal}) {
    final s = S.read(context);
    final ctrl = TextEditingController(text: goal?.title ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(goal == null ? s.addGoal : s.editGoal),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: s.goalNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              final title = ctrl.text.trim();
              if (title.isEmpty) return;
              final provider = context.read<AwarenessProvider>();
              if (goal == null) {
                provider.addGoal(title);
              } else {
                provider.updateGoal(goal, title);
              }
              Navigator.pop(ctx);
            },
            child: Text(s.ok),
          ),
        ],
      ),
    );
  }

  void _showHabitDialog(BuildContext context, {Habit? habit}) {
    final s = S.read(context);
    final ctrl = TextEditingController(text: habit?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(habit == null ? s.addHabit : s.habits),
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
              if (name.isEmpty) return;
              final provider = context.read<HabitProvider>();
              if (habit == null) {
                provider.addHabit(name);
              } else {
                provider.updateHabit(habit, name);
              }
              Navigator.pop(ctx);
            },
            child: Text(s.ok),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onAdd;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.onAdd,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: title,
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;

  const _EmptyText({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        text,
        style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[500]),
      ),
    );
  }
}
