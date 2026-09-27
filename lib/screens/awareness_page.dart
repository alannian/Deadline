import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/habit.dart';
import '../models/life_item.dart';
import '../providers/habit_provider.dart';
import '../providers/life_item_provider.dart';

class AwarenessPage extends StatefulWidget {
  const AwarenessPage({super.key});

  @override
  State<AwarenessPage> createState() => _AwarenessPageState();
}

class _AwarenessPageState extends State<AwarenessPage> {
  bool _habitsExpanded = false;

  @override
  void initState() {
    super.initState();
    final habitProvider = context.read<HabitProvider>();
    final lifeItemProvider = context.read<LifeItemProvider>();
    Future.microtask(() {
      habitProvider.loadHabits();
      lifeItemProvider.loadItems();
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
          if (_habitsExpanded)
            Expanded(
              child: _Section(
                title: s.habits,
                icon: Icons.check_circle_outline_rounded,
                onAdd: () => _showHabitDialog(context),
                onToggle: () => setState(() => _habitsExpanded = false),
                isExpanded: true,
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
          if (!_habitsExpanded)
            _SectionHeader(
              title: s.habits,
              icon: Icons.check_circle_outline_rounded,
              onAdd: () => _showHabitDialog(context),
              onToggle: () => setState(() => _habitsExpanded = true),
              isExpanded: false,
            ),
          Divider(
            height: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
          Expanded(
            child: _Section(
              title: s.life,
              icon: Icons.home_outlined,
              onAdd: () => _showLifeItemDialog(context),
              child: Consumer<LifeItemProvider>(
                builder: (context, provider, _) {
                  if (provider.items.isEmpty) {
                    return _EmptyText(text: s.noLifeItemsYet);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    itemCount: provider.items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = provider.items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: IconButton(
                          tooltip: s.confirm,
                          icon: const Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: Colors.grey,
                          ),
                          onPressed: () => provider.completeItem(item.id),
                        ),
                        title: Text(item.title),
                        onTap: () => _showLifeItemDialog(context, item: item),
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

  void _showHabitDialog(BuildContext context, {Habit? habit}) {
    final s = S.read(context);
    final controller = TextEditingController(text: habit?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(habit == null ? s.addHabit : s.habits),
        content: TextField(
          controller: controller,
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
              final name = controller.text.trim();
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

  void _showLifeItemDialog(BuildContext context, {LifeItem? item}) {
    final s = S.read(context);
    final controller = TextEditingController(text: item?.title ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? s.addLifeItem : s.editLifeItem),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: s.lifeItemHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isEmpty) return;
              final provider = context.read<LifeItemProvider>();
              if (item == null) {
                provider.addItem(title);
              } else {
                provider.updateItem(item, title);
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
  const _Section({
    required this.title,
    required this.icon,
    required this.onAdd,
    required this.child,
    this.onToggle,
    this.isExpanded,
  });

  final String title;
  final IconData icon;
  final VoidCallback onAdd;
  final Widget child;
  final VoidCallback? onToggle;
  final bool? isExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(
          title: title,
          icon: icon,
          onAdd: onAdd,
          onToggle: onToggle,
          isExpanded: isExpanded,
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onAdd,
    this.onToggle,
    this.isExpanded,
  });

  final String title;
  final IconData icon;
  final VoidCallback onAdd;
  final VoidCallback? onToggle;
  final bool? isExpanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                    if (onToggle != null) ...[
                      const Spacer(),
                      Icon(
                        isExpanded == true
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: title,
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText({required this.text});

  final String text;

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
