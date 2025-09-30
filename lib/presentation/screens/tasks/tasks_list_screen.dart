// lib/presentation/screens/tasks/tasks_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _positiveTasks = [];
  List<Map<String, dynamic>> _negativeTasks = [];
  bool _isLoading = true;
  String _selectedCategory = 'Todas';
  final List<String> _categories = [
    'Todas',
    'Higiene',
    'Quarto',
    'Estudos',
    'Casa',
    'Alimentação',
    'Comportamento',
    'Eletrônicos'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      setState(() => _isLoading = true);

      final userId = _supabase.auth.currentUser?.id;
      final response = await _supabase
          .from('tasks')
          .select('*')
          .eq('user_id', userId!)
          .order('category')
          .order('points', ascending: false);

      final tasks = List<Map<String, dynamic>>.from(response);

      setState(() {
        _positiveTasks = tasks.where((t) => t['type'] == 'positive').toList();
        _negativeTasks = tasks.where((t) => t['type'] == 'negative').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar tarefas: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Gerenciar Tarefas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.add_circle_outline),
              text: 'Positivas',
            ),
            Tab(
              icon: Icon(Icons.remove_circle_outline),
              text: 'Negativas',
            ),
          ],
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'reset_tasks') {
                _showResetTasksDialog();
              } else if (value == 'reset_app') {
                _showResetAppDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset_tasks',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 12),
                    Text('Resetar Tarefas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset_app',
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Zerar Todo App', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro de categorias
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        _selectedCategory = selected ? category : 'Todas';
                      });
                    },
                    selectedColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          ),

          // Lista de tarefas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTasksList(_positiveTasks, true),
                      _buildTasksList(_negativeTasks, false),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/task-form');
          if (result == true) _loadTasks();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
      ),
    );
  }

  Widget _buildTasksList(List<Map<String, dynamic>> tasks, bool isPositive) {
    // Filtrar por categoria
    final filteredTasks = _selectedCategory == 'Todas'
        ? tasks
        : tasks.where((t) => t['category'] == _selectedCategory).toList();

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPositive ? Icons.add_task : Icons.rule,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma tarefa ${isPositive ? "positiva" : "negativa"}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (_selectedCategory != 'Todas') ...[
              const SizedBox(height: 8),
              Text(
                'na categoria $_selectedCategory',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        final color = isPositive ? Colors.green : Colors.red;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  task['icon'] ?? (isPositive ? '⭐' : '⚠️'),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Text(
              task['title'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task['description'] != null)
                  Text(
                    task['description'],
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.add_circle : Icons.remove_circle,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? "+" : ""}${task['points']} pontos',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task['category'] ?? 'Geral',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (task['frequency'] != 'unlimited')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          task['frequency'] == 'daily' ? 'Diária' : 'Semanal',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: task['is_active'] ?? true,
                  onChanged: (value) async {
                    await _toggleTask(task['id'], value);
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.pushNamed(
                        context,
                        '/task-form',
                        arguments: task,
                      ).then((result) {
                        if (result == true) _loadTasks();
                      });
                    } else if (value == 'delete') {
                      _deleteTask(task);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child:
                          Text('Deletar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
      },
    );
  }

  Future<void> _toggleTask(String taskId, bool isActive) async {
    try {
      await _supabase
          .from('tasks')
          .update({'is_active': isActive}).eq('id', taskId);

      _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar tarefa: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Tarefa?'),
        content: Text('Deseja deletar "${task['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.from('tasks').delete().eq('id', task['id']);
        _loadTasks();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarefa deletada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao deletar: $e')),
          );
        }
      }
    }
  }

  void _showResetTasksDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange),
            SizedBox(width: 12),
            Text('Resetar Tarefas'),
          ],
        ),
        content: const Text(
          'Isso irá:\n'
          '• Deletar todas as tarefas atuais\n'
          '• Recriar as tarefas padrão\n\n'
          'Pontos e histórico serão mantidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetTasks();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Resetar Tarefas'),
          ),
        ],
      ),
    );
  }

  void _showResetAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Zerar Todo o App'),
          ],
        ),
        content: const Text(
          '⚠️ ATENÇÃO! Isso irá:\n\n'
          '• Zerar todos os pontos\n'
          '• Deletar todo o histórico\n'
          '• Resetar níveis para 1\n'
          '• Recriar tarefas padrão\n'
          '• Remover recompensas\n\n'
          'Esta ação NÃO pode ser desfeita!',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetApp();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Zerar Tudo'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetTasks() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );

      final userId = _supabase.auth.currentUser?.id;
      await _supabase
          .rpc('reset_user_tasks', params: {'user_id_param': userId});

      await _loadTasks();

      if (mounted) {
        Navigator.pop(context); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarefas resetadas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao resetar: $e')),
        );
      }
    }
  }

  Future<void> _resetApp() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );

      final userId = _supabase.auth.currentUser?.id;
      await _supabase.rpc('reset_user_app', params: {'user_id_param': userId});

      if (mounted) {
        Navigator.pop(context); // Fechar loading
        Navigator.pushNamedAndRemoveUntil(
            context, '/dashboard', (route) => false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App resetado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao resetar app: $e')),
        );
      }
    }
  }
}
