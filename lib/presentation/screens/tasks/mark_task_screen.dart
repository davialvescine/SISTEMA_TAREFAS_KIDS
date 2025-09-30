import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/models/child_model.dart';
import '../../../core/utils/level_system.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';

class MarkTaskScreen extends StatefulWidget {
  const MarkTaskScreen({super.key});

  @override
  State<MarkTaskScreen> createState() => _MarkTaskScreenState();
}

class _MarkTaskScreenState extends State<MarkTaskScreen> {
  final _supabase = Supabase.instance.client;
  late ConfettiController _confettiController;

  List<Map<String, dynamic>> _tasks = [];
  ChildModel? _selectedChild;
  Map<String, dynamic>? _selectedTask;
  String _taskType = 'all'; // all, positive, negative
  String _selectedCategory = 'Todas';
  bool _isLoading = true;

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
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Carregar crianças do provider
      final childProvider = context.read<ChildProvider>();
      await childProvider.loadChildren();

      // Carregar tarefas ativas
      final userId = _supabase.auth.currentUser?.id;
      final tasksResponse = await _supabase
          .from('tasks')
          .select('*')
          .eq('user_id', userId!)
          .eq('is_active', true)
          .order('category')
          .order('points', ascending: false);

      setState(() {
        _tasks = List<Map<String, dynamic>>.from(tasksResponse);

        // Se recebeu uma criança como argumento, selecionar
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        if (args != null && args['child'] != null) {
          _selectedChild = ChildModel.fromJson(args['child']);
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredTasks {
    var tasks = _tasks;

    // Filtrar por tipo
    if (_taskType != 'all') {
      tasks = tasks.where((t) => t['type'] == _taskType).toList();
    }

    // Filtrar por categoria
    if (_selectedCategory != 'Todas') {
      tasks = tasks.where((t) => t['category'] == _selectedCategory).toList();
    }

    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Marcar Tarefa'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.orange, Colors.purple],
              numberOfParticles: 30,
            ),
          ),

          // Conteúdo principal
          Consumer<ChildProvider>(
            builder: (context, childProvider, _) {
              if (_isLoading || childProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (childProvider.children.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.child_care,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma criança cadastrada',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/dashboard');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar Criança'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Passo 1: Selecionar Criança
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  '1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Selecione a Criança',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: childProvider.children.length,
                            itemBuilder: (context, index) {
                              final child = childProvider.children[index];
                              final isSelected = _selectedChild?.id == child.id;
                              final colors = _getGradientColors(child.color);
                              final level = LevelSystem.getCurrentLevel(child.totalPoints);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedChild = child;
                                    _selectedTask = null;
                                  });
                                },
                                child: Container(
                                  width: 150,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(colors: colors)
                                        : null,
                                    color: isSelected ? null : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? colors[0] : Colors.grey[300]!,
                                      width: isSelected ? 3 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: colors[0].withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          child.name,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white.withValues(alpha: 0.2)
                                                : level.color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Nível ${level.level}',
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : level.color,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              size: 14,
                                              color: isSelected ? Colors.white : Colors.amber,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${child.currentPoints} pts',
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.black54,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: Duration(milliseconds: index * 100))
                                    .slideX(begin: 0.2, end: 0),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_selectedChild != null) ...[
                    const Divider(height: 1),

                    // Passo 2: Filtros
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    '2',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Escolha a Tarefa',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              // Tipo de tarefa
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'all',
                                    icon: Icon(Icons.all_inclusive, size: 16),
                                  ),
                                  ButtonSegment(
                                    value: 'positive',
                                    icon: Icon(Icons.add_circle_outline, size: 16),
                                  ),
                                  ButtonSegment(
                                    value: 'negative',
                                    icon: Icon(Icons.remove_circle_outline, size: 16),
                                  ),
                                ],
                                selected: {_taskType},
                                onSelectionChanged: (Set<String> newSelection) {
                                  setState(() {
                                    _taskType = newSelection.first;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Filtro de categorias
                          SizedBox(
                            height: 36,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
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
                                    selectedColor: Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.2),
                                    checkmarkColor: Theme.of(context).primaryColor,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lista de tarefas
                    Expanded(
                      child: _filteredTasks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhuma tarefa encontrada',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (_selectedCategory != 'Todas')
                                    Text(
                                      'na categoria $_selectedCategory',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredTasks.length,
                              itemBuilder: (context, index) {
                                final task = _filteredTasks[index];
                                final isPositive = task['type'] == 'positive';
                                final isSelected = _selectedTask?['id'] == task['id'];

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedTask = task;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isPositive
                                              ? Colors.green[50]
                                              : Colors.red[50])
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? (isPositive ? Colors.green : Colors.red)
                                            : Colors.grey[200]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          // Ícone
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: (isPositive
                                                      ? Colors.green
                                                      : Colors.red)
                                                  .withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                task['icon'] ??
                                                    (isPositive ? '⭐' : '⚠️'),
                                                style: const TextStyle(fontSize: 24),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Título e descrição
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  task['title'],
                                                  style: TextStyle(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                if (task['description'] != null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    task['description'],
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[200],
                                                        borderRadius:
                                                            BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        task['category'] ?? 'Geral',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                    if (task['frequency'] !=
                                                        'unlimited') ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue[100],
                                                          borderRadius:
                                                              BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          task['frequency'] == 'daily'
                                                              ? 'Diária'
                                                              : 'Semanal',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.blue[700],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Pontos
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: (isPositive
                                                      ? Colors.green
                                                      : Colors.red)
                                                  .withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${isPositive ? "+" : "-"}${task['points']}',
                                              style: TextStyle(
                                                color: isPositive
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: Duration(milliseconds: index * 50))
                                    .slideY(begin: 0.1, end: 0);
                              },
                            ),
                    ),

                    // Botão confirmar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          children: [
                            if (_selectedTask != null) ...[
                              // Preview da ação
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _selectedTask!['type'] == 'positive'
                                        ? [Colors.green[50]!, Colors.green[100]!]
                                        : [Colors.red[50]!, Colors.red[100]!],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedTask!['type'] == 'positive'
                                        ? Colors.green[200]!
                                        : Colors.red[200]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          _getGradientColors(_selectedChild!.color)[0],
                                      child: Text(
                                        _selectedChild!.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedChild!.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            _selectedTask!['title'],
                                            style: TextStyle(
                                              color: _selectedTask!['type'] == 'positive'
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (_selectedTask!['type'] == 'positive'
                                                ? Colors.green
                                                : Colors.red)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _selectedTask!['type'] == 'positive'
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _selectedTask!['type'] == 'positive'
                                                ? Icons.add_circle
                                                : Icons.remove_circle,
                                            size: 18,
                                            color: _selectedTask!['type'] == 'positive'
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_selectedTask!['points']} pts',
                                            style: TextStyle(
                                              color: _selectedTask!['type'] == 'positive'
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                              const SizedBox(height: 12),
                            ],

                            // Botão de confirmar
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _selectedTask == null ? null : _markTask,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedTask == null
                                      ? Colors.grey
                                      : (_selectedTask!['type'] == 'positive'
                                          ? Colors.green
                                          : Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _selectedTask == null
                                          ? Icons.task
                                          : (_selectedTask!['type'] == 'positive'
                                              ? Icons.check_circle
                                              : Icons.warning),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedTask == null
                                          ? 'Selecione uma tarefa'
                                          : (_selectedTask!['type'] == 'positive'
                                              ? 'Confirmar Tarefa Concluída'
                                              : 'Registrar Comportamento'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Mensagem quando não há criança selecionada
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Selecione uma criança para continuar',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _markTask() async {
    if (_selectedChild == null || _selectedTask == null) return;

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );

      final childProvider = context.read<ChildProvider>();

      // Marcar tarefa através do provider
      final leveledUp = await childProvider.completeTask(
        childId: _selectedChild!.id,
        taskId: _selectedTask!['id'],
        taskName: _selectedTask!['title'],
        points: _selectedTask!['points'] as int,
        type: _selectedTask!['type'],
      );

      if (mounted) {
        Navigator.pop(context); // Fechar loading

        if (leveledUp) {
          // Se subiu de nível, mostrar animação especial
          _showLevelUpAnimation();
        } else {
          // Mostrar animação normal de sucesso
          _showSuccessAnimation();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao marcar tarefa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessAnimation() {
    final isPositive = _selectedTask!['type'] == 'positive';

    if (isPositive) {
      _confettiController.play();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.celebration : Icons.info_outline,
                size: 80,
                color: isPositive ? Colors.amber : Colors.orange,
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .shake(delay: 600.ms),
              const SizedBox(height: 16),
              Text(
                isPositive ? 'Parabéns!' : 'Registrado!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_selectedChild!.name} ${isPositive ? "ganhou" : "perdeu"}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                '${isPositive ? "+" : "-"}${_selectedTask!['points']} pontos',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ).animate().scale(delay: 300.ms),
              const SizedBox(height: 8),
              Text(
                'Saldo atual: ${_selectedChild!.currentPoints + (isPositive ? (_selectedTask!['points'] as int) : -(_selectedTask!['points'] as int))} pontos',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Voltar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        if (mounted) {
                          setState(() {
                            _selectedTask = null;
                          });
                          _loadData();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text('Nova Tarefa'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
      ),
    );
  }

  void _showLevelUpAnimation() {
    final newLevel = LevelSystem.getCurrentLevel(
      _selectedChild!.totalPoints + (_selectedTask!['points'] as int),
    );

    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: LevelSystem.getLevelGradient(
                _selectedChild!.totalPoints + (_selectedTask!['points'] as int),
              ),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  newLevel.icon,
                  size: 60,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .scale(duration: 800.ms, curve: Curves.elasticOut)
                  .rotate(duration: 1000.ms),
              const SizedBox(height: 16),
              const Text(
                '🎉 SUBIU DE NÍVEL! 🎉',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn().scale(),
              const SizedBox(height: 8),
              Text(
                _selectedChild!.name,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'agora é ${newLevel.title}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nível ${newLevel.level}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _showSuccessAnimation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: newLevel.color,
                ),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
      ),
    );
  }

  List<Color> _getGradientColors(String colorName) {
    final colorMap = {
      'purple': [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
      'blue': [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
      'green': [const Color(0xFF10B981), const Color(0xFF34D399)],
      'orange': [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
      'pink': [const Color(0xFFEC4899), const Color(0xFFF472B6)],
      'red': [const Color(0xFFEF4444), const Color(0xFFF87171)],
    };

    return colorMap[colorName] ?? colorMap['purple']!;
  }
}