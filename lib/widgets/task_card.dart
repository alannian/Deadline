import 'package:flutter/material.dart';
import '../models/task.dart';
import '../l10n/app_strings.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onRecord;
  final VoidCallback onDelete;
  final bool isLocked;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onRecord,
    required this.onDelete,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    // 颜色优先级：已完成→绿色，置顶→红色，默认→蓝色
    final Color color;
    if (isLocked) {
      color = isDark ? Colors.grey[700]! : Colors.grey[400]!;
    } else if (task.isCompleted) {
      color = Colors.green;
    } else if (task.isPinned) {
      color = Colors.red;
    } else {
      color = const Color(0xFF42A5F5);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // 左侧：色标
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),

              // 中间：标题 + 进度条
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                      if (task.isPinned && !task.isCompleted)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.push_pin,
                                size: 13, color: Colors.red[300]),
                          ),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isLocked
                                  ? (isDark ? Colors.grey[500] : Colors.grey[600])
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (task.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('✓',
                                style: TextStyle(
                                    color: Colors.green, fontSize: 11)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: task.progress,
                              minHeight: 4,
                              backgroundColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatAmount(task.completedAmount)}/${_formatAmount(task.targetAmount)}',
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // 右侧：剩余量 + 记录按钮
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAmount(task.remainingAmount),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    s.unitRemainingLabel(task.unit),
                    style: TextStyle(
                        fontSize: 10,
                        color:
                            isDark ? Colors.grey[500] : Colors.grey[600]),
                  ),
                ],
              ),
              if (!task.isCompleted) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  child: FilledButton.tonal(
                    onPressed: isLocked ? null : onRecord,
                    style: FilledButton.styleFrom(
                      backgroundColor: color.withValues(alpha: 0.15),
                      foregroundColor: color,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text(s.record),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(1);
  }
}
