import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_strings.dart';
import 'task_list_page.dart';
import 'calendar_page.dart';
import 'memo_page.dart';
import 'settings_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    TaskListPage(),
    CalendarPage(),
    MemoPage(),
    SettingsPage(),
  ];

  static const _icons = <IconData>[
    Icons.checklist_rounded,
    Icons.calendar_month_rounded,
    Icons.note_alt_outlined,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final pageOrder = context.watch<SettingsProvider>().pageOrder;
    final s = S.of(context);
    final labels = s.navLabels;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (final idx in pageOrder) _pages[idx],
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          for (final idx in pageOrder)
            NavigationDestination(
              icon: Icon(_icons[idx]),
              label: labels[idx],
            ),
        ],
      ),
    );
  }
}
