import 'package:flutter/material.dart';
import 'task_list_page.dart';
import 'task_issue_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  bool _showChecklist = true;

  @override
  Widget build(BuildContext context) {
    if (_showChecklist) {
      return TaskListPage(
        onShowIssues: () => setState(() => _showChecklist = false),
      );
    }

    return TaskIssuePage(
      onShowChecklist: () => setState(() => _showChecklist = true),
    );
  }
}
