import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Task> _tasks = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String _searchQuery = '';
  String? _statusFilter;

  // --- Getters ---
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;

  /// Filtered tasks based on current search and status filter
  List<Task> get filteredTasks {
    var result = List<Task>.from(_tasks);

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      result = result.where((t) => t.status == _statusFilter).toList();
    }

    return result;
  }

  /// Get list of tasks available for "Blocked By" dropdown (excludes given task)
  List<Task> availableBlockers(int? excludeTaskId) {
    return _tasks.where((t) => t.id != excludeTaskId).toList();
  }

  // --- Actions ---

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _api.fetchTasks();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  Future<bool> createTask(Task task) async {
    if (_isSaving) return false; // Prevent double-tap

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _api.createTask(task);
      _tasks.insert(0, created);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(int id, Map<String, dynamic> updates) async {
    if (_isSaving) return false; // Prevent double-tap

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final (updatedTask, newRecurring) = await _api.updateTask(id, updates);

      // Replace the updated task in the list
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }

      // If a new recurring task was generated, add it
      if (newRecurring != null) {
        _tasks.insert(0, newRecurring);
      }

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      await _api.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
      // Also clear any blocked_by references to the deleted task
      for (int i = 0; i < _tasks.length; i++) {
        if (_tasks[i].blockedById == id) {
          _tasks[i] = _tasks[i].copyWith(clearBlockedBy: true);
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
