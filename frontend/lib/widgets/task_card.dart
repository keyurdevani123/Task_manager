import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final List<Task> allTasks;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(String newStatus) onStatusChange;

  const TaskCard({
    super.key,
    required this.task,
    required this.allTasks,
    required this.onTap,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final isBlocked = task.isBlocked(allTasks);
    final blockerName = task.blockerTitle(allTasks);
    final isOverdue = task.isOverdue;
    final dateFormat = DateFormat('MMM d, yyyy');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isBlocked
              ? AppTheme.surface.withValues(alpha: 0.5)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isBlocked
                ? AppTheme.cardBorder.withValues(alpha: 0.3)
                : isOverdue
                    ? AppTheme.danger.withValues(alpha: 0.4)
                    : AppTheme.cardBorder,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // --- Main Card Content ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Title + Delete
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status indicator dot
                      Container(
                        margin: const EdgeInsets.only(top: 4, right: 10),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isBlocked
                              ? AppTheme.textMuted
                              : AppTheme.statusColor(task.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Title
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isBlocked
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary,
                            decoration: task.status == 'Done'
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppTheme.textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Delete button
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: AppTheme.textMuted,
                          padding: EdgeInsets.zero,
                          tooltip: 'Delete task',
                        ),
                      ),
                    ],
                  ),

                  // Description (if present)
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isBlocked
                              ? AppTheme.textMuted.withValues(alpha: 0.6)
                              : AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Bottom row: Due date, Status chip, Recurring icon
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Row(
                      children: [
                        // Due date
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: isOverdue && !isBlocked
                              ? AppTheme.danger
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(task.dueDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue && !isBlocked
                                ? AppTheme.danger
                                : AppTheme.textMuted,
                            fontWeight: isOverdue ? FontWeight.w500 : null,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Status chip
                        _StatusChip(
                          status: task.status,
                          isBlocked: isBlocked,
                          onStatusChange: onStatusChange,
                        ),

                        const Spacer(),

                        // Recurring icon
                        if (task.isRecurring) ...[
                          Icon(
                            Icons.repeat_rounded,
                            size: 16,
                            color: isBlocked
                                ? AppTheme.textMuted.withValues(alpha: 0.5)
                                : AppTheme.accentLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.recurrenceType ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: isBlocked
                                  ? AppTheme.textMuted.withValues(alpha: 0.5)
                                  : AppTheme.accentLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Blocked indicator
                  if (isBlocked && blockerName != null) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.danger.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 13,
                              color: AppTheme.danger.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Blocked by: $blockerName',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.danger.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // --- Blocked overlay ---
            if (isBlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.transparent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Interactive status chip with popup menu
class _StatusChip extends StatelessWidget {
  final String status;
  final bool isBlocked;
  final void Function(String newStatus) onStatusChange;

  const _StatusChip({
    required this.status,
    required this.isBlocked,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final color = isBlocked ? AppTheme.textMuted : AppTheme.statusColor(status);

    return PopupMenuButton<String>(
      onSelected: isBlocked ? null : onStatusChange,
      enabled: !isBlocked,
      offset: const Offset(0, 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppTheme.surfaceLight,
      itemBuilder: (context) => [
        _statusMenuItem('To-Do', AppTheme.todoColor),
        _statusMenuItem('In Progress', AppTheme.inProgressColor),
        _statusMenuItem('Done', AppTheme.doneColor),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _statusMenuItem(String label, Color color) {
    return PopupMenuItem(
      value: label,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }
}
