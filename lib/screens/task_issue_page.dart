import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/task_issue.dart';
import '../providers/task_issue_provider.dart';
import 'task_issue_edit_page.dart';

class TaskIssuePage extends StatefulWidget {
  const TaskIssuePage({super.key, required this.onShowChecklist});

  final VoidCallback onShowChecklist;

  @override
  State<TaskIssuePage> createState() => _TaskIssuePageState();
}

class _TaskIssuePageState extends State<TaskIssuePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(context.read<TaskIssueProvider>().loadIssues);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.issuesMode)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'showChecklist',
              tooltip: s.checklistMode,
              onPressed: widget.onShowChecklist,
              child: const Icon(Icons.checklist_rounded),
            ),
            FloatingActionButton(
              heroTag: 'addIssue',
              tooltip: s.newIssue,
              onPressed: () => _openIssueEditor(context),
              child: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ),
      body: Consumer<TaskIssueProvider>(
        builder: (context, provider, _) {
          if (provider.issues.isEmpty) return _buildEmptyState(context);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: provider.issues.length,
            itemBuilder: (context, index) {
              return _buildIssueRow(context, provider.issues[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline_rounded,
            size: 72,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            s.noIssuesYet,
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.tapToCreateIssue,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueRow(BuildContext context, TaskIssue issue) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final createdTime =
        '${issue.createdAt.hour.toString().padLeft(2, '0')}:'
        '${issue.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _openIssueEditor(context, issue: issue),
        onLongPress: () => _confirmDeleteIssue(context, issue),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.issueCreatedAt(
                        issue.createdAt.year,
                        issue.createdAt.month,
                        issue.createdAt.day,
                        createdTime,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                s.issueDuration(_durationText(s, issue.createdAt)),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _durationText(S s, DateTime createdAt) {
    final elapsed = DateTime.now().difference(createdAt);
    if (elapsed.inDays > 0) return s.durationDays(elapsed.inDays);
    if (elapsed.inHours > 0) return s.durationHours(elapsed.inHours);
    return s.durationMinutes(elapsed.inMinutes.clamp(1, 59));
  }

  Future<void> _openIssueEditor(
    BuildContext context, {
    TaskIssue? issue,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskIssueEditPage(issue: issue)),
    );
    if (context.mounted) {
      await context.read<TaskIssueProvider>().loadIssues();
    }
  }

  void _confirmDeleteIssue(BuildContext context, TaskIssue issue) {
    final s = S.read(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.confirmDelete),
        content: Text(s.deleteIssueConfirm(issue.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskIssueProvider>().deleteIssue(issue.id);
              Navigator.pop(ctx);
            },
            child: Text(s.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
