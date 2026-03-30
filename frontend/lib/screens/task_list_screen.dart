import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';
import '../widgets/status_filter.dart';
import '../widgets/search_bar.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    // Load tasks when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  void _navigateToCreateTask() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const TaskFormScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _navigateToEditTask(Task task) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => TaskFormScreen(task: task),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Task',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to delete "${task.title}"?',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TaskProvider>().deleteTask(task.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${task.title}" deleted'),
                  backgroundColor: AppTheme.surfaceLight,
                ),
              );
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  void _onStatusChange(Task task, String newStatus) {
    context.read<TaskProvider>().updateTask(task.id!, {'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Tasks',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 2),
                      Consumer<TaskProvider>(
                        builder: (_, provider, __) {
                          final count = provider.filteredTasks.length;
                          return Text(
                            '$count task${count == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  // Refresh button
                  IconButton(
                    onPressed: () =>
                        context.read<TaskProvider>().loadTasks(),
                    icon: const Icon(Icons.refresh_rounded),
                    color: AppTheme.textSecondary,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // --- Search Bar ---
            Consumer<TaskProvider>(
              builder: (_, provider, __) {
                return DebouncedSearchBar(
                  initialQuery: provider.searchQuery,
                  onChanged: (query) => provider.setSearchQuery(query),
                );
              },
            ),

            const SizedBox(height: 14),

            // --- Status Filters ---
            Consumer<TaskProvider>(
              builder: (_, provider, __) {
                return StatusFilter(
                  selectedStatus: provider.statusFilter,
                  onChanged: (status) => provider.setStatusFilter(status),
                );
              },
            ),

            const SizedBox(height: 10),

            // --- Task List ---
            Expanded(
              child: Consumer<TaskProvider>(
                builder: (_, provider, __) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accent,
                        strokeWidth: 2,
                      ),
                    );
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              size: 48,
                              color: AppTheme.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Unable to connect',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Make sure the backend server is running\non localhost:8000',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextButton.icon(
                              onPressed: () => provider.loadTasks(),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Retry'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final tasks = provider.filteredTasks;

                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            provider.searchQuery.isNotEmpty ||
                                    provider.statusFilter != null
                                ? Icons.search_off_rounded
                                : Icons.task_alt_rounded,
                            size: 56,
                            color: AppTheme.textMuted.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.searchQuery.isNotEmpty ||
                                    provider.statusFilter != null
                                ? 'No matching tasks'
                                : 'No tasks yet',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            provider.searchQuery.isNotEmpty ||
                                    provider.statusFilter != null
                                ? 'Try adjusting your filters'
                                : 'Tap + to create your first task',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadTasks(),
                    color: AppTheme.accent,
                    backgroundColor: AppTheme.surface,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 100),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: tasks.length,
                      itemBuilder: (_, index) {
                        final task = tasks[index];
                        return TaskCard(
                          task: task,
                          allTasks: provider.tasks,
                          onTap: () => _navigateToEditTask(task),
                          onDelete: () => _confirmDelete(context, task),
                          onStatusChange: (newStatus) =>
                              _onStatusChange(task, newStatus),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // --- FAB ---
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateTask,
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
