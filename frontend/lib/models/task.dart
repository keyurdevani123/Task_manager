import 'dart:convert';

class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status; // "To-Do", "In Progress", "Done"
  final int? blockedById;
  final bool isRecurring;
  final String? recurrenceType; // "Daily", "Weekly"
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = 'To-Do',
    this.blockedById,
    this.isRecurring = false,
    this.recurrenceType,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      dueDate: DateTime.parse(json['due_date'] as String),
      status: json['status'] as String? ?? 'To-Do',
      blockedById: json['blocked_by_id'] as int?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrenceType: json['recurrence_type'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String().split('T')[0],
      'status': status,
      'blocked_by_id': blockedById,
      'is_recurring': isRecurring,
      'recurrence_type': recurrenceType,
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    int? blockedById,
    bool? clearBlockedBy,
    bool? isRecurring,
    String? recurrenceType,
    bool? clearRecurrence,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedById: clearBlockedBy == true ? null : (blockedById ?? this.blockedById),
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: clearRecurrence == true ? null : (recurrenceType ?? this.recurrenceType),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Check if this task is currently blocked (blocker exists and isn't Done)
  bool isBlocked(List<Task> allTasks) {
    if (blockedById == null) return false;
    final blocker = allTasks.where((t) => t.id == blockedById).firstOrNull;
    if (blocker == null) return false;
    return blocker.status != 'Done';
  }

  /// Get the blocker task name
  String? blockerTitle(List<Task> allTasks) {
    if (blockedById == null) return null;
    final blocker = allTasks.where((t) => t.id == blockedById).firstOrNull;
    return blocker?.title;
  }

  bool get isOverdue {
    if (status == 'Done') return false;
    return dueDate.isBefore(DateTime.now().subtract(const Duration(days: 0)));
  }

  @override
  String toString() => 'Task(id: $id, title: $title, status: $status)';
}
