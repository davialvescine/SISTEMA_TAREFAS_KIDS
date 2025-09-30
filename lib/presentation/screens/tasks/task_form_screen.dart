// lib/presentation/screens/tasks/task_form_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();

  String _type = 'positive';
  String _frequency = 'unlimited';
  String _category = 'Geral';
  String _selectedIcon = '⭐';
  bool _isActive = true;
  bool _isLoading = false;
  Map<String, dynamic>? _editingTask;

  final List<String> _categories = [
    'Geral',
    'Higiene',
    'Quarto',
    'Estudos',
    'Casa',
    'Alimentação',
    'Comportamento',
    'Eletrônicos'
  ];

  final Map<String, List<String>> _iconsByCategory = {
    'Geral': ['⭐', '✨', '🎯', '✅', '🏆'],
    'Higiene': ['🦷', '🚿', '🧼', '🪥', '💅'],
    'Quarto': ['🛏️', '🧸', '🎒', '👕', '🧹'],
    'Estudos': ['📚', '📖', '📝', '✏️', '🎓'],
    'Casa': ['🏠', '🍽️', '🗑️', '🌱', '🐕'],
    'Alimentação': ['🍎', '🥗', '💧', '🥛', '🍽️'],
    'Comportamento': ['🤝', '💝', '😴', '🙏', '😊'],
    'Eletrônicos': ['📱', '🎮', '💻', '📺', '⏰'],
  };

  final Map<String, List<String>> _negativeIcons = {
    'Comportamento': ['😤', '😠', '🙊', '🤥', '🚫'],
    'Estudos': ['📚', '❌', '😴', '🚫', '⚠️'],
    'Quarto': ['🏚️', '🗑️', '😵', '🚫', '❌'],
    'Eletrônicos': ['📱', '🎮', '⏰', '🚫', '⚠️'],
  };

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final task =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (task != null) {
        _editingTask = task;
        _titleController.text = task['title'] ?? '';
        _descriptionController.text = task['description'] ?? '';
        _pointsController.text = task['points'].abs().toString();
        _type = task['type'] ?? 'positive';
        _frequency = task['frequency'] ?? 'unlimited';
        _category = task['category'] ?? 'Geral';
        _selectedIcon = task['icon'] ?? '⭐';
        _isActive = task['is_active'] ?? true;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  List<String> _getAvailableIcons() {
    if (_type == 'negative') {
      return _negativeIcons[_category] ?? _negativeIcons['Comportamento']!;
    }
    return _iconsByCategory[_category] ?? _iconsByCategory['Geral']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingTask == null ? 'Nova Tarefa' : 'Editar Tarefa'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tipo de Tarefa
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Tarefa',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Positiva'),
                            subtitle: const Text('Ganha pontos'),
                            value: 'positive',
                            groupValue: _type,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              setState(() {
                                _type = value!;
                                _selectedIcon = _getAvailableIcons().first;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Negativa'),
                            subtitle: const Text('Perde pontos'),
                            value: 'negative',
                            groupValue: _type,
                            activeColor: Colors.red,
                            onChanged: (value) {
                              setState(() {
                                _type = value!;
                                _selectedIcon = _getAvailableIcons().first;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Informações Básicas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informações',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título da Tarefa',
                        hintText: 'Ex: Escovar os dentes',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite o título da tarefa';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição (opcional)',
                        hintText: 'Ex: Escovar bem após as refeições',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pointsController,
                      decoration: InputDecoration(
                        labelText: 'Pontos',
                        hintText: 'Ex: 5',
                        prefixIcon: Icon(
                          _type == 'positive'
                              ? Icons.add_circle
                              : Icons.remove_circle,
                          color:
                              _type == 'positive' ? Colors.green : Colors.red,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite a quantidade de pontos';
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return 'Digite um número válido maior que zero';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Categoria e Ícone
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Categoria',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _category = value!;
                          _selectedIcon = _getAvailableIcons().first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ícone',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getAvailableIcons().map((icon) {
                        final isSelected = _selectedIcon == icon;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIcon = icon;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Frequência
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Frequência',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<String>(
                      title: const Text('Ilimitada'),
                      subtitle: const Text('Pode ser feita várias vezes'),
                      value: 'unlimited',
                      groupValue: _frequency,
                      onChanged: (value) {
                        setState(() {
                          _frequency = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Diária'),
                      subtitle: const Text('Uma vez por dia'),
                      value: 'daily',
                      groupValue: _frequency,
                      onChanged: (value) {
                        setState(() {
                          _frequency = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Semanal'),
                      subtitle: const Text('Uma vez por semana'),
                      value: 'weekly',
                      groupValue: _frequency,
                      onChanged: (value) {
                        setState(() {
                          _frequency = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Status
            SwitchListTile(
              title: const Text('Tarefa Ativa'),
              subtitle: const Text('Tarefa disponível para ser marcada'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),

            const SizedBox(height: 24),

            // Botão Salvar
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTask,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_editingTask == null
                        ? 'Criar Tarefa'
                        : 'Salvar Alterações'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      final points = int.parse(_pointsController.text);

      final taskData = {
        'user_id': userId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'points': _type == 'negative' ? -points : points,
        'category': _category,
        'icon': _selectedIcon,
        'type': _type,
        'frequency': _frequency,
        'is_active': _isActive,
      };

      if (_editingTask == null) {
        // Criar nova tarefa
        await _supabase.from('tasks').insert(taskData);
      } else {
        // Atualizar tarefa existente
        await _supabase
            .from('tasks')
            .update(taskData)
            .eq('id', _editingTask!['id']);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _editingTask == null ? 'Tarefa criada!' : 'Tarefa atualizada!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
