import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/draft_service.dart';
import '../theme/app_theme.dart';

class TaskFormScreen extends StatefulWidget {
  /// If null, we're creating a new task. If provided, we're editing.
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _draftService = DraftService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  String _status = 'To-Do';
  int? _blockedById;
  bool _isRecurring = false;
  String? _recurrenceType;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (_isEditing) {
      // Editing — populate from task
      _titleController = TextEditingController(text: widget.task!.title);
      _descriptionController =
          TextEditingController(text: widget.task!.description);
      _dueDate = widget.task!.dueDate;
      _status = widget.task!.status;
      _blockedById = widget.task!.blockedById;
      _isRecurring = widget.task!.isRecurring;
      _recurrenceType = widget.task!.recurrenceType;
    } else {
      // Creating — try to load draft
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _loadDraft();
    }
  }

  Future<void> _loadDraft() async {
    final draft = await _draftService.loadDraft();
    if (draft != null && mounted) {
      setState(() {
        _titleController.text = draft['title'] ?? '';
        _descriptionController.text = draft['description'] ?? '';
        if (draft['due_date'] != null && draft['due_date'].isNotEmpty) {
          try {
            _dueDate = DateTime.parse(draft['due_date']);
          } catch (_) {}
        }
        _status = draft['status'] ?? 'To-Do';
        _blockedById = draft['blocked_by_id'] as int?;
        _isRecurring = draft['is_recurring'] ?? false;
        _recurrenceType = draft['recurrence_type'] as String?;
      });
    }
  }

  Future<void> _saveDraft() async {
    if (!_isEditing) {
      await _draftService.saveDraft(
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _dueDate.toIso8601String().split('T')[0],
        status: _status,
        blockedById: _blockedById,
        isRecurring: _isRecurring,
        recurrenceType: _recurrenceType,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save draft when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveDraft();
    }
  }

  @override
  void dispose() {
    // Save draft when user swipes back
    _saveDraft();
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accent,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
            dialogBackgroundColor: AppTheme.surface,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TaskProvider>();
    if (provider.isSaving) return; // Prevent double-tap

    bool success;

    if (_isEditing) {
      // Build update map with only changed fields
      final updates = <String, dynamic>{};
      if (_titleController.text != widget.task!.title) {
        updates['title'] = _titleController.text;
      }
      if (_descriptionController.text != widget.task!.description) {
        updates['description'] = _descriptionController.text;
      }
      if (_dueDate != widget.task!.dueDate) {
        updates['due_date'] = _dueDate.toIso8601String().split('T')[0];
      }
      if (_status != widget.task!.status) {
        updates['status'] = _status;
      }
      if (_blockedById != widget.task!.blockedById) {
        updates['blocked_by_id'] = _blockedById;
      }
      if (_isRecurring != widget.task!.isRecurring) {
        updates['is_recurring'] = _isRecurring;
      }
      if (_recurrenceType != widget.task!.recurrenceType) {
        updates['recurrence_type'] = _recurrenceType;
      }

      // If nothing changed, just go back
      if (updates.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }

      success = await provider.updateTask(widget.task!.id!, updates);
    } else {
      final newTask = Task(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _dueDate,
        status: _status,
        blockedById: _blockedById,
        isRecurring: _isRecurring,
        recurrenceType: _isRecurring ? _recurrenceType : null,
      );
      success = await provider.createTask(newTask);
    }

    if (success && mounted) {
      // Clear draft on successful save
      await _draftService.clearDraft();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Task updated successfully' : 'Task created successfully',
          ),
          backgroundColor: AppTheme.surfaceLight,
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Something went wrong'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          _isEditing ? 'Edit Task' : 'New Task',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          // Save button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: provider.isSaving ? null : _submitForm,
              child: provider.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.accent,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // --- Form ---
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _buildLabel('Title'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                    decoration: const InputDecoration(hintText: 'Enter task title'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Title is required' : null,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 20),

                  // Description
                  _buildLabel('Description'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                    decoration:
                        const InputDecoration(hintText: 'Enter task description'),
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                  ),

                  const SizedBox(height: 20),

                  // Due Date
                  _buildLabel('Due Date'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: AppTheme.accent),
                          const SizedBox(width: 12),
                          Text(
                            dateFormat.format(_dueDate),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Status
                  _buildLabel('Status'),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _status,
                        dropdownColor: AppTheme.surfaceLight,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.textMuted),
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        items: ['To-Do', 'In Progress', 'Done']
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.statusColor(s),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Text(s),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Blocked By
                  _buildLabel('Blocked By (Optional)'),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _blockedById,
                        dropdownColor: AppTheme.surfaceLight,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.textMuted),
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        hint: const Text('None',
                            style: TextStyle(color: AppTheme.textMuted)),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('None',
                                style: TextStyle(color: AppTheme.textMuted)),
                          ),
                          ...provider
                              .availableBlockers(widget.task?.id)
                              .map((t) => DropdownMenuItem<int?>(
                                    value: t.id,
                                    child: Text(
                                      t.title,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )),
                        ],
                        onChanged: (v) => setState(() => _blockedById = v),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Recurring Section ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.repeat_rounded,
                                  size: 20,
                                  color: _isRecurring
                                      ? AppTheme.accent
                                      : AppTheme.textMuted,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Recurring Task',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isRecurring,
                              onChanged: (v) {
                                setState(() {
                                  _isRecurring = v;
                                  if (!v) _recurrenceType = null;
                                  if (v && _recurrenceType == null) {
                                    _recurrenceType = 'Daily';
                                  }
                                });
                              },
                              activeColor: AppTheme.accent,
                              inactiveTrackColor: AppTheme.surfaceLight,
                            ),
                          ],
                        ),
                        if (_isRecurring) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _recurrenceChip('Daily'),
                              const SizedBox(width: 10),
                              _recurrenceChip('Weekly'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'When marked as Done, a new task will be created '
                            'with the due date moved '
                            '${_recurrenceType == 'Daily' ? '+1 day' : '+1 week'}.',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- Save Button (full width) ---
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: provider.isSaving ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        disabledBackgroundColor:
                            AppTheme.accent.withValues(alpha: 0.4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: provider.isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Saving...',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              _isEditing ? 'Update Task' : 'Create Task',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // --- Loading Overlay ---
          if (provider.isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _recurrenceChip(String label) {
    final isSelected = _recurrenceType == label;
    return GestureDetector(
      onTap: () => setState(() => _recurrenceType = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withValues(alpha: 0.2)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.accent.withValues(alpha: 0.5)
                : AppTheme.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
