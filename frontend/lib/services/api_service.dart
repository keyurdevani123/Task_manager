import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  // Set to the laptop's local IP network address so mobile can connect!
  static const String baseUrl = 'http://10.15.90.36:8000';

  // --- GET all tasks (with optional search & filter) ---
  Future<List<Task>> fetchTasks({String? search, String? status}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final uri = Uri.parse('$baseUrl/tasks').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> taskList = data['tasks'];
      return taskList.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tasks: ${response.statusCode}');
    }
  }

  // --- GET single task ---
  Future<Task> fetchTask(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/tasks/$id'));

    if (response.statusCode == 200) {
      return Task.fromJson(json.decode(response.body));
    } else {
      throw Exception('Task not found');
    }
  }

  // --- POST create task ---
  Future<Task> createTask(Task task) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(task.toJson()),
    );

    if (response.statusCode == 201) {
      return Task.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create task: ${response.body}');
    }
  }

  // --- PUT update task ---
  /// Returns (updatedTask, newRecurringTask?)
  Future<(Task, Task?)> updateTask(int id, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final updatedTask = Task.fromJson(data['task']);
      Task? newRecurring;
      if (data['new_recurring_task'] != null) {
        newRecurring = Task.fromJson(data['new_recurring_task']);
      }
      return (updatedTask, newRecurring);
    } else {
      throw Exception('Failed to update task: ${response.body}');
    }
  }

  // --- DELETE task ---
  Future<void> deleteTask(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/tasks/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete task: ${response.statusCode}');
    }
  }
}
