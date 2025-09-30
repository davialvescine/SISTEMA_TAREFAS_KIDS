import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  final Map<String, int> _childPoints = {};
  final Map<String, List<CompletedTask>> _completedTasks = {};

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;

  int getChildPoints(String childId) => _childPoints[childId] ?? 0;

  List<CompletedTask> getCompletedTasks(String childId) {
    return _completedTasks[childId] ?? [];
  }

  // Estatísticas
  Map<String, dynamic> getChildStats(String childId) {
    final completed = getCompletedTasks(childId);
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    final todayTasks = completed
        .where((t) =>
            t.completedAt.day == today.day &&
            t.completedAt.month == today.month &&
            t.completedAt.year == today.year)
        .toList();

    final weekTasks =
        completed.where((t) => t.completedAt.isAfter(startOfWeek)).toList();

    int todayPoints = todayTasks.fold(0, (sum, task) => sum + task.points);
    int weekPoints = weekTasks.fold(0, (sum, task) => sum + task.points);

    return {
      'totalPoints': getChildPoints(childId),
      'todayPoints': todayPoints,
      'weekPoints': weekPoints,
      'todayTasks': todayTasks.length,
      'weekTasks': weekTasks.length,
      'level': _calculateLevel(getChildPoints(childId)),
      'nextLevelPoints': _getNextLevelPoints(getChildPoints(childId)),
      'levelProgress': _getLevelProgress(getChildPoints(childId)),
    };
  }

  // Sistema de níveis
  Map<String, dynamic> _calculateLevel(int points) {
    if (points < 50) {
      return {'level': 1, 'title': 'Iniciante', 'icon': Icons.star_border};
    } else if (points < 100) {
      return {'level': 2, 'title': 'Ajudante', 'icon': Icons.star_half};
    } else if (points < 200) {
      return {'level': 3, 'title': 'Super Ajudante', 'icon': Icons.star};
    } else if (points < 400) {
      return {'level': 4, 'title': 'Herói', 'icon': Icons.military_tech};
    } else if (points < 600) {
      return {'level': 5, 'title': 'Lenda', 'icon': Icons.emoji_events};
    } else {
      return {'level': 6, 'title': 'Mestre', 'icon': Icons.workspace_premium};
    }
  }

  int _getNextLevelPoints(int points) {
    if (points < 50) return 50;
    if (points < 100) return 100;
    if (points < 200) return 200;
    if (points < 400) return 400;
    if (points < 600) return 600;
    return points; // Nível máximo
  }

  double _getLevelProgress(int points) {
    if (points < 50) return points / 50;
    if (points < 100) return (points - 50) / 50;
    if (points < 200) return (points - 100) / 100;
    if (points < 400) return (points - 200) / 200;
    if (points < 600) return (points - 400) / 200;
    return 1.0; // Nível máximo
  }

  // Carregar tarefas
  Future<void> loadTasks(String childId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString('tasks_$childId');
      final pointsJson = prefs.getInt('points_$childId') ?? 0;
      final completedJson = prefs.getString('completed_$childId');

      if (tasksJson != null) {
        final List<dynamic> tasksList = json.decode(tasksJson);
        _tasks = tasksList.map((e) => TaskModel.fromJson(e)).toList();

        // Reseta contadores diários/semanais se necessário
        _resetTaskCounters();
      }

      _childPoints[childId] = pointsJson;

      if (completedJson != null) {
        final List<dynamic> completedList = json.decode(completedJson);
        _completedTasks[childId] =
            completedList.map((e) => CompletedTask.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar tarefas: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Adicionar nova tarefa
  Future<void> addTask(String childId, TaskModel task) async {
    _tasks.add(task);
    await _saveTasks(childId);
    notifyListeners();
  }

  // Editar tarefa
  Future<void> editTask(String childId, TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      await _saveTasks(childId);
      notifyListeners();
    }
  }

  // Deletar tarefa
  Future<void> deleteTask(String childId, String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    await _saveTasks(childId);
    notifyListeners();
  }

  // Ativar/Desativar tarefa
  Future<void> toggleTaskStatus(
      String childId, String taskId, bool isActive) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(isActive: isActive);
      await _saveTasks(childId);
      notifyListeners();
    }
  }

  // Completar tarefa
  Future<void> completeTask(String childId, String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    if (!task.canComplete) return;

    // Atualiza contadores
    final now = DateTime.now();
    int newTodayCount = task.completedToday;
    int newWeekCount = task.completedThisWeek;

    // Verifica se precisa resetar contador diário
    if (task.lastCompletedAt != null) {
      if (task.lastCompletedAt!.day != now.day) {
        newTodayCount = 0;
      }
    }

    newTodayCount++;
    newWeekCount++;

    // Atualiza a tarefa
    _tasks[taskIndex] = task.copyWith(
      completedToday: newTodayCount,
      completedThisWeek: newWeekCount,
      lastCompletedAt: now,
    );

    // Atualiza pontos
    final currentPoints = _childPoints[childId] ?? 0;
    final newPoints = task.type == TaskType.positive
        ? currentPoints + task.points
        : currentPoints - task.points;

    _childPoints[childId] = newPoints > 0 ? newPoints : 0;

    // Adiciona ao histórico
    if (_completedTasks[childId] == null) {
      _completedTasks[childId] = [];
    }

    _completedTasks[childId]!.add(
      CompletedTask(
        taskId: task.id,
        taskName: task.name,
        points: task.type == TaskType.positive ? task.points : -task.points,
        completedAt: now,
        type: task.type,
      ),
    );

    // Salva tudo
    await _saveTasks(childId);
    await _savePoints(childId);
    await _saveCompletedTasks(childId);

    notifyListeners();
  }

  // Reseta contadores diários/semanais
  void _resetTaskCounters() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      bool needsUpdate = false;
      int newTodayCount = task.completedToday;
      int newWeekCount = task.completedThisWeek;

      // Reset diário
      if (task.lastCompletedAt != null) {
        if (task.lastCompletedAt!.day != now.day ||
            task.lastCompletedAt!.month != now.month ||
            task.lastCompletedAt!.year != now.year) {
          newTodayCount = 0;
          needsUpdate = true;
        }

        // Reset semanal
        if (task.lastCompletedAt!.isBefore(startOfWeek)) {
          newWeekCount = 0;
          needsUpdate = true;
        }
      }

      if (needsUpdate) {
        _tasks[i] = task.copyWith(
          completedToday: newTodayCount,
          completedThisWeek: newWeekCount,
        );
      }
    }
  }

  // Salvar tarefas
  Future<void> _saveTasks(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = json.encode(_tasks.map((e) => e.toJson()).toList());
    await prefs.setString('tasks_$childId', tasksJson);
  }

  // Salvar pontos
  Future<void> _savePoints(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('points_$childId', _childPoints[childId] ?? 0);
  }

  // Salvar histórico
  Future<void> _saveCompletedTasks(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = _completedTasks[childId] ?? [];
    final completedJson =
        json.encode(completed.map((e) => e.toJson()).toList());
    await prefs.setString('completed_$childId', completedJson);
  }
}

// Modelo para tarefas completadas
class CompletedTask {
  final String taskId;
  final String taskName;
  final int points;
  final DateTime completedAt;
  final TaskType type;

  CompletedTask({
    required this.taskId,
    required this.taskName,
    required this.points,
    required this.completedAt,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'taskName': taskName,
        'points': points,
        'completedAt': completedAt.toIso8601String(),
        'type': type.index,
      };

  factory CompletedTask.fromJson(Map<String, dynamic> json) => CompletedTask(
        taskId: json['taskId'],
        taskName: json['taskName'],
        points: json['points'],
        completedAt: DateTime.parse(json['completedAt']),
        type: TaskType.values[json['type']],
      );
}
