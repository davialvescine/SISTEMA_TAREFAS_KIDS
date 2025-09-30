import 'package:flutter/material.dart';

enum TaskFrequency { unlimited, daily, weekly }

enum TaskType { positive, negative }

class TaskModel {
  final String id;
  final String name;
  final String description;
  final int points;
  final TaskType type;
  final TaskFrequency frequency;
  final int? limitCount; // Limite para tarefas diárias/semanais
  final String category;
  final IconData icon;
  final Color color;
  final bool isActive;
  final DateTime createdAt;
  final int completedToday;
  final int completedThisWeek;
  final DateTime? lastCompletedAt;

  TaskModel({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
    required this.type,
    required this.frequency,
    this.limitCount,
    required this.category,
    required this.icon,
    required this.color,
    this.isActive = true,
    required this.createdAt,
    this.completedToday = 0,
    this.completedThisWeek = 0,
    this.lastCompletedAt,
  });

  // Verifica se a tarefa pode ser completada
  bool get canComplete {
    if (!isActive) return false;

    switch (frequency) {
      case TaskFrequency.unlimited:
        return true;
      case TaskFrequency.daily:
        return limitCount == null || completedToday < limitCount!;
      case TaskFrequency.weekly:
        return limitCount == null || completedThisWeek < limitCount!;
    }
  }

  // Retorna o número de vezes restantes
  int get remainingCount {
    if (frequency == TaskFrequency.unlimited) return -1; // Ilimitado

    switch (frequency) {
      case TaskFrequency.daily:
        return limitCount != null ? limitCount! - completedToday : -1;
      case TaskFrequency.weekly:
        return limitCount != null ? limitCount! - completedThisWeek : -1;
      default:
        return -1;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'points': points,
        'type': type.index,
        'frequency': frequency.index,
        'limitCount': limitCount,
        'category': category,
        'icon': icon.codePoint,
        'color': color.toARGB32(),
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'completedToday': completedToday,
        'completedThisWeek': completedThisWeek,
        'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        points: json['points'],
        type: TaskType.values[json['type']],
        frequency: TaskFrequency.values[json['frequency']],
        limitCount: json['limitCount'],
        category: json['category'],
        icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
        color: Color(json['color']),
        isActive: json['isActive'] ?? true,
        createdAt: DateTime.parse(json['createdAt']),
        completedToday: json['completedToday'] ?? 0,
        completedThisWeek: json['completedThisWeek'] ?? 0,
        lastCompletedAt: json['lastCompletedAt'] != null
            ? DateTime.parse(json['lastCompletedAt'])
            : null,
      );

  TaskModel copyWith({
    String? name,
    String? description,
    int? points,
    TaskType? type,
    TaskFrequency? frequency,
    int? limitCount,
    String? category,
    IconData? icon,
    Color? color,
    bool? isActive,
    int? completedToday,
    int? completedThisWeek,
    DateTime? lastCompletedAt,
  }) {
    return TaskModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      points: points ?? this.points,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      limitCount: limitCount ?? this.limitCount,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      completedToday: completedToday ?? this.completedToday,
      completedThisWeek: completedThisWeek ?? this.completedThisWeek,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
    );
  }
}