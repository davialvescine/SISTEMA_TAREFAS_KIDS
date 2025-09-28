// lib/presentation/screens/home/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId != null) {
        // Carregar crianças
        final childrenResponse = await _supabase
            .from('children')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        setState(() {
          _children = List<Map<String, dynamic>>.from(childrenResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(authProvider),
            ),

            // Resumo Rápido
            SliverToBoxAdapter(
              child: _buildQuickSummary(),
            ),

            // Título da seção
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
                    if (_children.isEmpty)
                      Container()
                    else
                      Text(
                        '${_children.length} ${_children.length == 1 ? 'criança' : 'crianças'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ).animate().fadeIn(delay: 500.ms),
                  ],
                ),
              ),
            ),

            // Lista de crianças ou estado vazio
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_children.isEmpty)
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
                      return _buildChildCard(_children[index], index);
                    },
                    childCount: _children.length,
                  ),
                ),
              ),
          ],
        ),
      ),

      // Botão flutuante para adicionar criança
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddChildDialog,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Criança'),
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
                  'Vamos organizar as tarefas de hoje?',
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
                // Navegar para configurações
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
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildQuickSummary() {
    final totalPoints = _children.fold<int>(
      0,
      (sum, child) => sum + (child['current_points'] as int? ?? 0),
    );

    final totalStars = _children.fold<int>(
      0,
      (sum, child) => sum + (child['stars'] as int? ?? 0),
    );

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
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildChildCard(Map<String, dynamic> child, int index) {
    final colors = _getGradientColors(child['color'] ?? 'purple');

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
                        child['name']?.substring(0, 1).toUpperCase() ?? '?',
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
                          child['name'] ?? 'Sem nome',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Nível ${child['level'] ?? 1}',
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
                      // Implementar menu de opções
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
                      '${child['current_points'] ?? 0}',
                      'Pontos',
                    ),
                    _buildStatItem(
                      '⭐',
                      '${child['stars'] ?? 0}',
                      'Estrelas',
                    ),
                    _buildStatItem(
                      '💰',
                      'R\$ ${(child['real_money'] ?? 0.0).toStringAsFixed(2)}',
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
                        // Implementar marcar tarefa
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Função de tarefas em breve!'),
                          ),
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
                        // Implementar ver histórico
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Histórico em breve!'),
                          ),
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
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.child_care,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ).animate().fadeIn().scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma criança cadastrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            Text(
              'Adicione sua primeira criança para começar a organizar as tarefas!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddChildDialog,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Primeira Criança'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                ),
          ],
        ),
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

  void _showAddChildDialog() {
    final nameController = TextEditingController();
    String selectedColor = 'purple';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Adicionar Criança'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da criança',
                  hintText: 'Ex: João',
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
                if (nameController.text.isNotEmpty) {
                  try {
                    final userId = _supabase.auth.currentUser?.id;

                    await _supabase.from('children').insert({
                      'user_id': userId,
                      'name': nameController.text.trim(),
                      'color': selectedColor,
                      'current_points': 0,
                      'total_points': 0,
                      'stars': 0,
                      'real_money': 0.0,
                      'level': 1,
                    });

                    if (context.mounted) {
                      Navigator.pop(dialogContext);
                      _loadData(); // Recarregar dados

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Criança adicionada com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao adicionar criança: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}
