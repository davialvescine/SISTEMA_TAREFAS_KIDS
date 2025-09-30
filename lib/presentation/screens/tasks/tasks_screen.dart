import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/task_model.dart';
import '../../../core/providers/task_provider.dart';
import 'add_task_screen.dart';
import '../../../widgets/task_card.dart';

class TasksScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const TasksScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'Todas';
  final List<String> _categories = [
    'Todas',
    'Estudos',
    'Casa',
    'Higiene',
    'Comportamento',
    'Esporte',
    'Alimentação'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Carrega as tarefas ao iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks(widget.childId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks, TaskType type) {
    var filtered = tasks.where((task) => task.type == type).toList();

    if (_selectedCategory != 'Todas') {
      filtered =
          filtered.where((task) => task.category == _selectedCategory).toList();
    }

    // Ordena: ativas primeiro, depois por pontos
    filtered.sort((a, b) {
      if (a.isActive != b.isActive) {
        return a.isActive ? -1 : 1;
      }
      return b.points.compareTo(a.points);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tarefas de ${widget.childName}',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Gerencie as atividades',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle,
                color: Color(0xFF6B4EFF), size: 32),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTaskScreen(childId: widget.childId),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6B4EFF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6B4EFF),
          tabs: const [
            Tab(
              icon: Icon(Icons.thumb_up),
              text: 'Positivas',
            ),
            Tab(
              icon: Icon(Icons.thumb_down),
              text: 'Negativas',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filtro de categorias
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: const Color(0xFF6B4EFF).withAlpha(20),
                    checkmarkColor: const Color(0xFF6B4EFF),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF6B4EFF)
                          : Colors.grey[700],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Lista de tarefas
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                if (taskProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Tarefas Positivas
                    _buildTaskList(
                      _filterTasks(taskProvider.tasks, TaskType.positive),
                      TaskType.positive,
                    ),
                    // Tarefas Negativas
                    _buildTaskList(
                      _filterTasks(taskProvider.tasks, TaskType.negative),
                      TaskType.negative,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<TaskModel> tasks, TaskType type) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == TaskType.positive
                  ? Icons.sentiment_satisfied
                  : Icons.sentiment_dissatisfied,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma tarefa ${type == TaskType.positive ? "positiva" : "negativa"}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory != 'Todas'
                  ? 'na categoria $_selectedCategory'
                  : 'cadastrada ainda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTaskScreen(
                      childId: widget.childId,
                      initialType: type,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Tarefa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          childId: widget.childId,
          onComplete: () {
            context.read<TaskProvider>().completeTask(widget.childId, task.id);

            // Mostra feedback visual
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      task.type == TaskType.positive
                          ? Icons.add_circle
                          : Icons.remove_circle,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      task.type == TaskType.positive
                          ? '+${task.points} pontos ganhos!'
                          : '-${task.points} pontos perdidos',
                    ),
                  ],
                ),
                backgroundColor:
                    task.type == TaskType.positive ? Colors.green : Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          onEdit: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTaskScreen(
                  childId: widget.childId,
                  task: task,
                ),
              ),
            );
          },
          onToggle: (value) {
            context
                .read<TaskProvider>()
                .toggleTaskStatus(widget.childId, task.id, value);
          },
        );
      },
    );
  }
}
