class ActivityModel {
  final String id;
  final String childId;
  final String? taskId;
  final String? taskName;
  final int points;
  final String type; // 'positive' ou 'negative'
  final String? description;
  final DateTime completedAt;

  ActivityModel({
    required this.id,
    required this.childId,
    this.taskId,
    this.taskName,
    required this.points,
    required this.type,
    this.description,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'child_id': childId,
        'task_id': taskId,
        'task_name': taskName,
        'points': points,
        'type': type,
        'description': description,
        'completed_at': completedAt.toIso8601String(),
      };

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
        id: json['id'],
        childId: json['child_id'],
        taskId: json['task_id'],
        taskName: json['task_name'],
        points: json['points'],
        type: json['type'],
        description: json['description'],
        completedAt: DateTime.parse(json['completed_at']),
      );

  // Método auxiliar para saber se é positivo
  bool get isPositive => type == 'positive';

  // Método auxiliar para formatação de pontos com sinal
  String get pointsFormatted => isPositive ? '+$points' : '-$points';
}