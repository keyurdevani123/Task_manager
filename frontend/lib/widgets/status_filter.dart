import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusFilter extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?> onChanged;

  const StatusFilter({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip('All', null),
          const SizedBox(width: 8),
          _buildChip('To-Do', 'To-Do', AppTheme.todoColor),
          const SizedBox(width: 8),
          _buildChip('In Progress', 'In Progress', AppTheme.inProgressColor),
          const SizedBox(width: 8),
          _buildChip('Done', 'Done', AppTheme.doneColor),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String? value, [Color? color]) {
    final isSelected = selectedStatus == value;
    final chipColor = color ?? AppTheme.accent;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.2)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? chipColor.withValues(alpha: 0.5)
                : AppTheme.cardBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? chipColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
