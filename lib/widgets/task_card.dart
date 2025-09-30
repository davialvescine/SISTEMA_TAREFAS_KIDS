import 'package:flutter/material.dart';
import '../core/models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final String childId;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final Function(bool) onToggle;

  const TaskCard({
    super.key,
    required this.task,
    required this.childId,
    required this.onComplete,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final canComplete = task.canComplete;
    final isPositive = task.type == TaskType.positive;

    return Card(
      elevation: task.isActive ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: task.isActive ? Colors.transparent : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: canComplete ? onComplete : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: task.isActive ? 1.0 : 0.5,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: task.isActive && canComplete
                  ? LinearGradient(
                      colors: [
                        task.color.withAlpha(10),
                        task.color.withAlpha(5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Ícone da tarefa
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: task.color.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    task.icon,
                    color: task.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Informações da tarefa
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Badge de pontos
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? Colors.green.withAlpha(20)
                                  : Colors.red.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositive ? Icons.add : Icons.remove,
                                  size: 14,
                                  color: isPositive ? Colors.green : Colors.red,
                                ),
                                Text(
                                  '${task.points} pts',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isPositive ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Categoria
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              task.category,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Frequência
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getFrequencyIcon(task.frequency),
                                  size: 12,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getFrequencyText(task),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Botões de ação
                          if (!canComplete && task.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Limite atingido',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Menu de opções
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'toggle':
                        onToggle(!task.isActive);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            task.isActive ? Icons.pause : Icons.play_arrow,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(task.isActive ? 'Desativar' : 'Ativar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFrequencyIcon(TaskFrequency frequency) {
    switch (frequency) {
      case TaskFrequency.unlimited:
        return Icons.all_inclusive;
      case TaskFrequency.daily:
        return Icons.today;
      case TaskFrequency.weekly:
        return Icons.date_range;
    }
  }

  String _getFrequencyText(TaskModel task) {
    switch (task.frequency) {
      case TaskFrequency.unlimited:
        return 'Ilimitada';
      case TaskFrequency.daily:
        if (task.limitCount != null) {
          return '${task.completedToday}/${task.limitCount} hoje';
        }
        return 'Diária';
      case TaskFrequency.weekly:
        if (task.limitCount != null) {
          return '${task.completedThisWeek}/${task.limitCount} semana';
        }
        return 'Semanal';
    }
  }
}
