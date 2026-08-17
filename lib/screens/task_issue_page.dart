import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_issue.dart';
import '../providers/task_issue_provider.dart';
import '../l10n/app_strings.dart';

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
    final provider = context.read<TaskIssueProvider>();
    Future.microtask(provider.loadIssues);
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
              onPressed: () => _showIssueDialog(context),
              child: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ),
      body: Consumer<TaskIssueProvider>(
        builder: (context, provider, _) {
          if (provider.issues.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: provider.issues.length,
            itemBuilder: (context, index) {
              return _buildIssueCard(context, provider.issues[index]);
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

  Widget _buildIssueCard(BuildContext context, TaskIssue issue) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time =
        '${issue.updatedAt.hour}:${issue.updatedAt.minute.toString().padLeft(2, '0')}';
    final note = issue.note.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showIssueDialog(context, issue: issue),
        onLongPress: () => _confirmDeleteIssue(context, issue),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  size: 20,
                  color: Color(0xFFFFB300),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      s.updatedAt(
                        issue.updatedAt.month,
                        issue.updatedAt.day,
                        time,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: Colors.red[300],
                ),
                onPressed: () => _confirmDeleteIssue(context, issue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIssueDialog(BuildContext context, {TaskIssue? issue}) {
    final s = S.read(context);
    final titleCtrl = TextEditingController(text: issue?.title ?? '');
    final noteCtrl = TextEditingController(text: issue?.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(issue == null ? s.newIssue : s.editIssue),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: InputDecoration(hintText: s.issueTitleHint),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    hintText: s.issueNoteHint,
                    alignLabelWithHint: true,
                  ),
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 6,
                  maxLines: 12,
                ),
              ],
            ),
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
              final note = noteCtrl.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(s.fillAllFields)));
                return;
              }

              final provider = context.read<TaskIssueProvider>();
              if (issue == null) {
                provider.addIssue(title: title, note: note);
              } else {
                provider.updateIssue(issue, title: title, note: note);
              }
              Navigator.pop(ctx);
            },
            child: Text(issue == null ? s.create : s.ok),
          ),
        ],
      ),
    );
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
