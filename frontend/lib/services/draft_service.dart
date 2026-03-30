import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists draft form data so the user doesn't lose work
/// if they accidentally swipe back or minimize the app.
class DraftService {
  static const String _draftKey = 'task_draft';

  /// Save current form state as a draft
  Future<void> saveDraft({
    required String title,
    required String description,
    required String dueDate,
    required String status,
    int? blockedById,
    bool isRecurring = false,
    String? recurrenceType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final draft = json.encode({
      'title': title,
      'description': description,
      'due_date': dueDate,
      'status': status,
      'blocked_by_id': blockedById,
      'is_recurring': isRecurring,
      'recurrence_type': recurrenceType,
    });
    await prefs.setString(_draftKey, draft);
  }

  /// Load saved draft, returns null if no draft exists
  Future<Map<String, dynamic>?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftString = prefs.getString(_draftKey);
    if (draftString == null || draftString.isEmpty) return null;
    try {
      return json.decode(draftString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Clear the saved draft (after successful save)
  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  /// Check if a draft exists
  Future<bool> hasDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_draftKey);
  }
}
