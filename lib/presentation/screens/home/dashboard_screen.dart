// lib/presentation/screens/home/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/models/child_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Carregar dados através do provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChildProvider>().loadChildren();
      _checkAndShowWelcome();
    });
  }

  // Método para verificar e mostrar boas-vindas
  Future<void> _checkAndShowWelcome() async {
    // Verificar se é novo usuário através dos argumentos de navegação
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Verificar também se é a primeira vez usando SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome =
        prefs.getBool('hasSeenWelcome_${_supabase.auth.currentUser?.id}') ??
            false;

    if ((args != null && args['isNewUser'] == true) || !hasSeenWelcome) {
      final userName = args?['userName'] ??
          _supabase.auth.currentUser?.userMetadata?['name'] ??
          _supabase.auth.currentUser?.email?.split('@')[0] ??
          'Usuário';

      // Marcar que já viu o welcome
      await prefs.setBool(
          'hasSeenWelcome_${_supabase.auth.currentUser?.id}', true);

      // Mostrar SnackBar de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    args?['isNewUser'] == true
                        ? 'Conta criada com sucesso! Bem-vindo(a), $userName!'
                        : 'Bem-vindo(a) de volta, $userName!',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      // Se é completamente novo (sem crianças), mostrar dialog tutorial
      if (args?['isNewUser'] == true) {
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        final childProvider = context.read<ChildProvider>();
        if (childProvider.children.isEmpty) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.celebration, color: Colors.amber, size: 30),
                  SizedBox(width: 10),
                  Text('Vamos começar!'),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Para começar a usar o app:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Text('1️⃣ Adicione suas crianças'),
                  SizedBox(height: 8),
                  Text('2️⃣ Crie tarefas personalizadas'),
                  SizedBox(height: 8),
                  Text('3️⃣ Defina pontos e recompensas'),
                  SizedBox(height: 8),
                  Text('4️⃣ Acompanhe o progresso!'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Depois'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddChildDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar criança'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final childProvider = context.watch<ChildProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(authProvider),
            ),

            // Resumo Rápido (só mostra se tem crianças)
            if (childProvider.children.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildQuickSummary(childProvider),
              ),

            // Título da seção
            if (!childProvider.isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Minhas Crianças',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ).animate().fadeIn(delay: 400.ms),
                      if (childProvider.children.isNotEmpty)
                        Text(
                          '${childProvider.children.length} ${childProvider.children.length == 1 ? 'criança' : 'crianças'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ).animate().fadeIn(delay: 500.ms),
                    ],
                  ),
                ),
              ),

            // Conteúdo principal
            if (childProvider.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (childProvider.children.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildChildCard(childProvider.children[index], index);
                    },
                    childCount: childProvider.children.length,
                  ),
                ),
              ),

            // Espaçamento para o FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),

      // Botão flutuante único
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddChildDialog,
        icon: const Icon(Icons.add),
        label: Text(childProvider.children.isEmpty
            ? 'Adicionar Primeira Criança'
            : 'Adicionar Criança'),
        backgroundColor: Theme.of(context).primaryColor,
      ).animate().fadeIn(delay: 600.ms).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
          ),
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    final userName = authProvider.user?.userMetadata?['name'] ??
        authProvider.user?.email?.split('@')[0] ??
        'Usuário';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $userName! 👋',
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate().fadeIn(duration: 600.ms),
                const SizedBox(height: 4),
                Text(
                  context.watch<ChildProvider>().children.isEmpty
                      ? 'Adicione suas crianças para começar!'
                      : 'Vamos organizar as tarefas de hoje?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),

          // Menu de opções
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.more_vert,
                color: Theme.of(context).primaryColor,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'settings') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Configurações em breve!')),
                );
              } else if (value == 'logout') {
                await context.read<AuthProvider>().signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Configurações'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Sair', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.child_care,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
            ).animate().scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma criança cadastrada',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            Text(
              'Adicione suas crianças para começar a organizar as tarefas e acompanhar o progresso delas!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSummary(ChildProvider childProvider) {
    final totalPoints = childProvider.totalFamilyPoints;
    final totalStars = childProvider.totalFamilyStars;
    final totalMoney = childProvider.totalFamilyMoney;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withBlue(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('🎯', totalPoints.toString(), 'Pontos Totais'),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildSummaryItem('⭐', totalStars.toString(), 'Estrelas Totais'),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildSummaryItem('💰', 'R\$ ${totalMoney.toStringAsFixed(2)}', 'Reais Totais'),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildSummaryItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildChildCard(ChildModel child, int index) {
    final colors = _getGradientColors(child.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        child.name.isNotEmpty ? child.name.substring(0, 1).toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colors[0],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Nome e nível
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Nível ${child.level}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu de opções
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {
                      _showChildOptionsMenu(child);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Estatísticas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      '🎯',
                      '${child.currentPoints}',
                      'Pontos',
                    ),
                    _buildStatItem(
                      '⭐',
                      '${child.stars}',
                      'Estrelas',
                    ),
                    _buildStatItem(
                      '💰',
                      'R\$ ${child.realMoney.toStringAsFixed(2)}',
                      'Reais',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/mark-task',
                          arguments: {'child': child},
                        );
                      },
                      icon: const Icon(Icons.add_task),
                      label: const Text('Marcar Tarefa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        foregroundColor: colors[0],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/child-profile',
                          arguments: {'child': child},
                        );
                      },
                      icon: Icon(Icons.history, color: colors[0]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 500 + (index * 100)))
        .slideX(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  List<Color> _getGradientColors(String colorName) {
    final colorMap = {
      'purple': [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      'blue': [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
      'green': [const Color(0xFF10B981), const Color(0xFF059669)],
      'orange': [const Color(0xFFF97316), const Color(0xFFEA580C)],
      'pink': [const Color(0xFFEC4899), const Color(0xFFDB2777)],
      'red': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
    };

    return colorMap[colorName] ?? colorMap['purple']!;
  }

  void _showChildOptionsMenu(ChildModel child) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _showEditChildDialog(child);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remover', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteChild(child);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteChild(ChildModel child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover criança?'),
        content: Text(
            'Deseja remover ${child.name}? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              if (!mounted) return;

              final childProvider = context.read<ChildProvider>();
              final success = await childProvider.deleteChild(child.id);

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Criança removida com sucesso!'
                      : 'Erro ao remover criança'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _showEditChildDialog(ChildModel child) {
    final nameController = TextEditingController(text: child.name);
    String selectedColor = child.color;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Editar Criança'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da criança',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),
              const Text('Escolha uma cor:'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  'purple',
                  'blue',
                  'green',
                  'orange',
                  'pink',
                  'red',
                ].map((color) {
                  final colors = _getGradientColors(color);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == color
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(dialogContext);

                  final childProvider = context.read<ChildProvider>();
                  final success = await childProvider.updateChild(
                    childId: child.id,
                    name: nameController.text.trim(),
                    color: selectedColor,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Criança atualizada com sucesso!'
                            : 'Erro ao atualizar criança'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChildDialog() {
    final nameController = TextEditingController();
    String selectedColor = 'purple';
    DateTime? birthDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.child_care, color: Colors.purple),
              SizedBox(width: 12),
              Text('Adicionar Criança'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome da criança',
                    hintText: 'Ex: João',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),

                // Data de nascimento (opcional)
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        birthDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            birthDate != null
                                ? '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}'
                                : 'Data de nascimento (opcional)',
                            style: TextStyle(
                              color: birthDate != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Text('Escolha uma cor:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'purple',
                    'blue',
                    'green',
                    'orange',
                    'pink',
                    'red',
                  ].map((color) {
                    final colors = _getGradientColors(color);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: colors),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color
                                ? Colors.black
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: selectedColor == color
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // Valida se o campo de nome não está vazio
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, insira o nome da criança'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Usar o provider para adicionar a criança
                final childProvider = context.read<ChildProvider>();
                Navigator.pop(dialogContext); // Fecha o diálogo primeiro

                // Mostra loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Adiciona a criança
                final success = await childProvider.addChild(
                  name: nameController.text.trim(),
                  color: selectedColor,
                  birthDate: birthDate,
                );

                // Fecha o loading
                if (mounted) Navigator.pop(context);

                // Mostra resultado
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            Text('${nameController.text} foi adicionado(a) com sucesso!'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(childProvider.errorMessage ??
                                  'Erro ao adicionar criança'),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}