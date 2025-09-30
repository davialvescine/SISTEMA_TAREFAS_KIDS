import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/models/task_model.dart';
import '../../../core/providers/task_provider.dart';

class AddTaskScreen extends StatefulWidget {
  final String childId;
  final TaskModel? task;
  final TaskType? initialType;

  const AddTaskScreen({
    super.key,
    required this.childId,
    this.task,
    this.initialType,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  final _limitController = TextEditingController();

  late TaskType _selectedType;
  TaskFrequency _selectedFrequency = TaskFrequency.unlimited;
  String _selectedCategory = 'Casa';
  IconData _selectedIcon = Icons.star;
  Color _selectedColor = const Color(0xFF6B4EFF);

  static const List<String> _categories = [
    'Casa',
    'Estudos',
    'Higiene',
    'Comportamento',
    'Esporte',
    'Alimentação',
    'Organização',
    'Social',
  ];

  static const List<IconData> _availableIcons = [
    Icons.star,
    Icons.home,
    Icons.school,
    Icons.clean_hands,
    Icons.favorite,
    Icons.sports_soccer,
    Icons.restaurant,
    Icons.folder,
    Icons.people,
    Icons.brush,
    Icons.book,
    Icons.directions_run,
    Icons.bedtime,
    Icons.shower,
    Icons.checkroom,
    Icons.piano,
    Icons.palette,
    Icons.videogame_asset,
    Icons.pets,
    Icons.park,
  ];

  static const List<Color> _availableColors = [
    Color(0xFF6B4EFF),
    Color(0xFFFF6B9D),
    Color(0xFF00D084),
    Color(0xFF00B8D4),
    Color(0xFFFF5722),
    Color(0xFFFFC107),
    Color(0xFF9C27B0),
    Color(0xFF3F51B5),
    Color(0xFF4CAF50),
    Color(0xFF795548),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? TaskType.positive;
    _initializeFormData();
  }

  void _initializeFormData() {
    final task = widget.task;
    if (task != null) {
      _nameController.text = task.name;
      _descriptionController.text = task.description;
      _pointsController.text = task.points.toString();
      _selectedType = task.type;
      _selectedFrequency = task.frequency;
      _selectedCategory = task.category;
      _selectedIcon = task.icon;
      _selectedColor = task.color;

      if (task.limitCount != null) {
        _limitController.text = task.limitCount.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (_formKey.currentState?.validate() != true) return;

    final taskProvider = context.read<TaskProvider>();
    final isEditing = widget.task != null;

    final task = TaskModel(
      id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      points: int.parse(_pointsController.text),
      type: _selectedType,
      frequency: _selectedFrequency,
      limitCount: _parseLimitCount(),
      category: _selectedCategory,
      icon: _selectedIcon,
      color: _selectedColor,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
    );

    if (isEditing) {
      taskProvider.editTask(widget.childId, task);
    } else {
      taskProvider.addTask(widget.childId, task);
    }

    Navigator.of(context).pop();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditing ? 'Tarefa atualizada!' : 'Tarefa criada!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  int? _parseLimitCount() {
    if (_selectedFrequency == TaskFrequency.unlimited) return null;
    if (_limitController.text.isEmpty) return null;
    return int.tryParse(_limitController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.task != null ? 'Editar Tarefa' : 'Nova Tarefa',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: _saveTask,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Salvar'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.list(
                children: [
                  _PreviewCard(
                    selectedColor: _selectedColor,
                    selectedIcon: _selectedIcon,
                    taskName: _nameController.text,
                    points: _pointsController.text,
                    selectedType: _selectedType,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Tipo de Tarefa'),
                  const SizedBox(height: 8),
                  _TypeSelector(
                    selectedType: _selectedType,
                    onTypeChanged: (type) =>
                        setState(() => _selectedType = type),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nome da Tarefa',
                    hint: 'Ex: Arrumar a cama',
                    icon: Icons.edit,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Digite o nome da tarefa';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Descrição',
                    hint: 'Ex: Deixar a cama bem arrumadinha',
                    icon: Icons.description,
                    maxLines: 2,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Digite a descrição';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _pointsController,
                    label: 'Pontos',
                    hint: 'Ex: 10',
                    icon: Icons.stars,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Digite os pontos';
                      }
                      final points = int.tryParse(value!);
                      if (points == null || points <= 0) {
                        return 'Digite um valor válido';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Categoria'),
                  const SizedBox(height: 8),
                  _CategoryChips(
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (category) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Frequência'),
                  const SizedBox(height: 8),
                  _FrequencySelector(
                    selectedFrequency: _selectedFrequency,
                    onFrequencyChanged: (frequency) {
                      setState(() {
                        _selectedFrequency = frequency;
                        if (frequency == TaskFrequency.unlimited) {
                          _limitController.clear();
                        }
                      });
                    },
                  ),
                  if (_selectedFrequency != TaskFrequency.unlimited) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _limitController,
                      label: _selectedFrequency == TaskFrequency.daily
                          ? 'Limite diário'
                          : 'Limite semanal',
                      hint: 'Ex: 3',
                      icon: Icons.format_list_numbered,
                      helperText: 'Deixe vazio para sem limite',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _SectionTitle('Ícone'),
                  const SizedBox(height: 8),
                  _IconSelector(
                    availableIcons: _availableIcons,
                    selectedIcon: _selectedIcon,
                    selectedColor: _selectedColor,
                    onIconSelected: (icon) =>
                        setState(() => _selectedIcon = icon),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Cor'),
                  const SizedBox(height: 8),
                  _ColorSelector(
                    availableColors: _availableColors,
                    selectedColor: _selectedColor,
                    onColorSelected: (color) {
                      setState(() => _selectedColor = color);
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? helperText,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6B4EFF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}

// Widgets auxiliares extraídos para melhor organização

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final Color selectedColor;
  final IconData selectedIcon;
  final String taskName;
  final String points;
  final TaskType selectedType;

  const _PreviewCard({
    required this.selectedColor,
    required this.selectedIcon,
    required this.taskName,
    required this.points,
    required this.selectedType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selectedColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(selectedIcon, size: 48, color: selectedColor),
          const SizedBox(height: 8),
          Text(
            taskName.isEmpty ? 'Nome da Tarefa' : taskName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selectedType == TaskType.positive
                    ? Icons.add_circle
                    : Icons.remove_circle,
                color: selectedType == TaskType.positive
                    ? Colors.green
                    : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${points.isEmpty ? '0' : points} pontos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: selectedType == TaskType.positive
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final TaskType selectedType;
  final Function(TaskType) onTypeChanged;

  const _TypeSelector({
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeCard(
            type: TaskType.positive,
            label: 'Positiva',
            icon: Icons.thumb_up,
            color: Colors.green,
            isSelected: selectedType == TaskType.positive,
            onTap: () => onTypeChanged(TaskType.positive),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeCard(
            type: TaskType.negative,
            label: 'Negativa',
            icon: Icons.thumb_down,
            color: Colors.red,
            isSelected: selectedType == TaskType.negative,
            onTap: () => onTypeChanged(TaskType.negative),
          ),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final TaskType type;
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade400,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const _CategoryChips({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = selectedCategory == category;
        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (_) => onCategorySelected(category),
          selectedColor: const Color(0xFF6B4EFF).withValues(alpha: 0.2),
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  final TaskFrequency selectedFrequency;
  final Function(TaskFrequency) onFrequencyChanged;

  const _FrequencySelector({
    required this.selectedFrequency,
    required this.onFrequencyChanged,
  });

  String _getLabel(TaskFrequency frequency) {
    return switch (frequency) {
      TaskFrequency.unlimited => 'Ilimitada',
      TaskFrequency.daily => 'Diária',
      TaskFrequency.weekly => 'Semanal',
    };
  }

  String _getDescription(TaskFrequency frequency) {
    return switch (frequency) {
      TaskFrequency.unlimited => 'Pode ser feita quantas vezes quiser',
      TaskFrequency.daily => 'Limite de vezes por dia',
      TaskFrequency.weekly => 'Limite de vezes por semana',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: TaskFrequency.values.map((frequency) {
        return RadioListTile<TaskFrequency>(
          title: Text(_getLabel(frequency)),
          subtitle: Text(_getDescription(frequency)),
          value: frequency,
          groupValue: selectedFrequency,
          onChanged: (value) => onFrequencyChanged(value!),
          activeColor: const Color(0xFF6B4EFF),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
}

class _IconSelector extends StatelessWidget {
  final List<IconData> availableIcons;
  final IconData selectedIcon;
  final Color selectedColor;
  final Function(IconData) onIconSelected;

  const _IconSelector({
    required this.availableIcons,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: availableIcons.length,
        itemBuilder: (context, index) {
          final icon = availableIcons[index];
          final isSelected = selectedIcon == icon;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onIconSelected(icon),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedColor.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? selectedColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? selectedColor : Colors.grey.shade600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ColorSelector extends StatelessWidget {
  final List<Color> availableColors;
  final Color selectedColor;
  final Function(Color) onColorSelected;

  const _ColorSelector({
    required this.availableColors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: availableColors.map((color) {
        final isSelected = selectedColor == color;
        return InkWell(
          onTap: () => onColorSelected(color),
          borderRadius: BorderRadius.circular(50),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
