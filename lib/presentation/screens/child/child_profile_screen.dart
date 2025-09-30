import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/models/child_model.dart';
import '../../../core/models/activity_model.dart';
import '../../../core/utils/level_system.dart';

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  String _selectedPeriod = '7d'; // 7d, 30d, all

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final childId = ModalRoute.of(context)?.settings.arguments as String?;
      if (childId != null) {
        final provider = context.read<ChildProvider>();
        final child = provider.children.firstWhere((c) => c.id == childId);
        provider.selectChild(child);
        provider.loadActivities(childId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChildProvider>(
      builder: (context, provider, _) {
        final child = provider.selectedChild;

        if (child == null) {
          return const Scaffold(
            body: Center(
              child: Text('Nenhuma criança selecionada'),
            ),
          );
        }

        final stats = provider.getChildStats(child.id);
        final level = stats['level'] as LevelInfo;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWeb = constraints.maxWidth > 800;
              final isMobile = constraints.maxWidth < 600;

              if (isWeb) {
                return _buildWebLayout(child, stats, level, provider);
              } else {
                return _buildMobileLayout(child, stats, level, provider, isMobile);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildWebLayout(ChildModel child, Map<String, dynamic> stats, LevelInfo level, ChildProvider provider) {
    return Row(
      children: [
        // Sidebar com informações
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: _buildProfileInfo(child, stats, level, provider, true),
        ),

        // Conteúdo principal
        Expanded(
          child: Column(
            children: [
              _buildHeader(child, isWeb: true),
              Expanded(
                child: _buildTabContent(child, provider, stats),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ChildModel child, Map<String, dynamic> stats, LevelInfo level, ChildProvider provider, bool isMobile) {
    return CustomScrollView(
      slivers: [
        // App Bar com gradiente
        SliverAppBar(
          expandedHeight: isMobile ? 200 : 250,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getGradientColors(child.color),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: _buildProfileHeader(child, stats, level, provider),
              ),
            ),
          ),
        ),

        // Conteúdo
        SliverToBoxAdapter(
          child: _buildProfileInfo(child, stats, level, provider, false),
        ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: 600,
            child: _buildTabContent(child, provider, stats),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ChildModel child, {bool isWeb = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(child.color),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          if (!isWeb)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          Text(
            'Perfil de ${child.name}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'edit') {
                _editChild(child);
              } else if (value == 'avatar') {
                _changeAvatar(child);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 12),
                    Text('Editar Perfil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'avatar',
                child: Row(
                  children: [
                    Icon(Icons.camera_alt),
                    SizedBox(width: 12),
                    Text('Alterar Foto'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ChildModel child, Map<String, dynamic> stats, LevelInfo level, ChildProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _changeAvatar(child),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: child.avatarUrl != null
                      ? NetworkImage(child.avatarUrl!)
                      : null,
                  child: child.avatarUrl == null
                      ? Text(
                          child.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _getGradientColors(child.color)[0],
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().scale(),

          const SizedBox(height: 16),

          Text(
            child.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          if (child.age != null)
            Text(
              '${child.age} anos',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(ChildModel child, Map<String, dynamic> stats, LevelInfo level, ChildProvider provider, bool isWeb) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWeb) ...[
            _buildProfileHeader(child, stats, level, provider),
            const Divider(),
          ],

          // Nível e progresso
          _buildLevelCard(level, stats),

          const SizedBox(height: 24),

          // Saldos
          _buildBalanceCards(child, isWeb),

          const SizedBox(height: 24),

          // Estatísticas
          _buildStatsCards(stats, isWeb),

          const SizedBox(height: 24),

          // Botões de ação
          _buildActionButtons(child, provider),
        ],
      ),
    );
  }

  Widget _buildLevelCard(LevelInfo level, Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: LevelSystem.getLevelGradient(stats['totalPoints']),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              level.buildBadge(size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nível ${level.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      level.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${stats['totalPoints']} pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LevelInfo.buildProgressBar(
            totalPoints: stats['totalPoints'],
            showText: true,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildBalanceCards(ChildModel child, bool isWeb) {
    final cards = [
      _buildBalanceCard(
        '🎯',
        'Pontos',
        child.currentPoints.toString(),
        Colors.blue,
        'Disponíveis',
      ),
      _buildBalanceCard(
        '⭐',
        'Estrelas',
        child.stars.toString(),
        Colors.amber,
        'Acumuladas',
      ),
      _buildBalanceCard(
        '💰',
        'Reais',
        'R\$ ${child.realMoney.toStringAsFixed(2)}',
        Colors.green,
        'Em conta',
      ),
    ];

    if (isWeb) {
      return Column(children: cards);
    } else {
      return Row(
        children: cards.map((card) => Expanded(child: card)).toList(),
      );
    }
  }

  Widget _buildBalanceCard(String emoji, String title, String value, Color color, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildStatsCards(Map<String, dynamic> stats, bool isWeb) {
    final cards = [
      _buildStatCard('Hoje', '${stats['todayPoints']}', 'pontos'),
      _buildStatCard('Semana', '${stats['weekPoints']}', 'pontos'),
      _buildStatCard('Tarefas', '${stats['todayTasks']}', 'hoje'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cards,
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ChildModel child, ChildProvider provider) {
    return Column(
      children: [
        // Converter pontos em estrelas
        if (child.currentPoints >= 10)
          _buildActionButton(
            icon: Icons.stars,
            label: 'Converter Pontos',
            color: Colors.amber,
            onPressed: () => _showConversionDialog(child, provider, 'points_to_stars'),
          ),

        const SizedBox(height: 8),

        // Converter estrelas em dinheiro
        if (child.stars >= 20)
          _buildActionButton(
            icon: Icons.monetization_on,
            label: 'Converter Estrelas',
            color: Colors.green,
            onPressed: () => _showConversionDialog(child, provider, 'stars_to_money'),
          ),

        const SizedBox(height: 8),

        // Sacar dinheiro
        if (child.realMoney > 0)
          _buildActionButton(
            icon: Icons.account_balance_wallet,
            label: 'Sacar Dinheiro',
            color: Colors.red,
            onPressed: () => _showWithdrawDialog(child, provider),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(ChildModel child, ChildProvider provider, Map<String, dynamic> stats) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Atividades', icon: Icon(Icons.list)),
            Tab(text: 'Gráficos', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Conquistas', icon: Icon(Icons.emoji_events)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildActivitiesTab(provider.activities),
              _buildChartsTab(provider.activities, stats),
              _buildAchievementsTab(stats),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesTab(List<ActivityModel> activities) {
    if (activities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhuma atividade registrada'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        final isPositive = activity.isPositive;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPositive ? Icons.add_circle : Icons.remove_circle,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            title: Text(activity.taskName ?? 'Atividade'),
            subtitle: Text(
              DateFormat('dd/MM/yyyy HH:mm').format(activity.completedAt),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                activity.pointsFormatted,
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartsTab(List<ActivityModel> activities, Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filtro de período
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '7d', label: Text('7 dias')),
                  ButtonSegment(value: '30d', label: Text('30 dias')),
                  ButtonSegment(value: 'all', label: Text('Tudo')),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (Set<String> selection) {
                  setState(() {
                    _selectedPeriod = selection.first;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Gráfico de evolução de pontos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evolução de Pontos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildPointsChart(activities),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Gráfico de tarefas por categoria
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tarefas por Tipo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildPieChart(activities),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsChart(List<ActivityModel> activities) {
    // Filtrar atividades pelo período selecionado
    final now = DateTime.now();
    final filteredActivities = activities.where((a) {
      if (_selectedPeriod == '7d') {
        return a.completedAt.isAfter(now.subtract(const Duration(days: 7)));
      } else if (_selectedPeriod == '30d') {
        return a.completedAt.isAfter(now.subtract(const Duration(days: 30)));
      }
      return true;
    }).toList();

    if (filteredActivities.isEmpty) {
      return const Center(child: Text('Sem dados para exibir'));
    }

    // Agrupar por dia
    final Map<String, int> dailyPoints = {};
    for (final activity in filteredActivities) {
      final day = DateFormat('dd/MM').format(activity.completedAt);
      dailyPoints[day] = (dailyPoints[day] ?? 0) + activity.points;
    }

    final spots = dailyPoints.entries.map((entry) {
      final index = dailyPoints.keys.toList().indexOf(entry.key);
      return FlSpot(index.toDouble(), entry.value.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < dailyPoints.length) {
                  return Text(
                    dailyPoints.keys.toList()[index],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<ActivityModel> activities) {
    final positive = activities.where((a) => a.isPositive).length;
    final negative = activities.length - positive;

    if (activities.isEmpty) {
      return const Center(child: Text('Sem dados para exibir'));
    }

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: positive.toDouble(),
            title: 'Positivas\n$positive',
            color: Colors.green,
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (negative > 0)
            PieChartSectionData(
              value: negative.toDouble(),
              title: 'Negativas\n$negative',
              color: Colors.red,
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildAchievementsTab(Map<String, dynamic> stats) {
    final achievements = [
      {
        'icon': '🎯',
        'title': 'Primeira Tarefa',
        'description': 'Complete sua primeira tarefa',
        'unlocked': stats['totalPoints'] > 0,
      },
      {
        'icon': '⭐',
        'title': 'Colecionador',
        'description': 'Acumule 10 estrelas',
        'unlocked': stats['stars'] >= 10,
      },
      {
        'icon': '🏆',
        'title': 'Centurião',
        'description': 'Alcance 100 pontos',
        'unlocked': stats['totalPoints'] >= 100,
      },
      {
        'icon': '💎',
        'title': 'Lendário',
        'description': 'Alcance o nível Lenda',
        'unlocked': stats['level'].level >= 5,
      },
      {
        'icon': '🎮',
        'title': 'Mestre Supremo',
        'description': 'Alcance o nível máximo',
        'unlocked': stats['level'].level >= 6,
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final unlocked = achievement['unlocked'] as bool;

        return Card(
          color: unlocked ? Colors.amber[50] : Colors.grey[100],
          child: InkWell(
            onTap: unlocked
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Conquista desbloqueada: ${achievement['title']}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ColorFiltered(
                    colorFilter: unlocked
                        ? const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply,
                          )
                        : const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          ),
                    child: Text(
                      achievement['icon'] as String,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    achievement['title'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: unlocked ? Colors.black : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement['description'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: unlocked ? Colors.grey[600] : Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showConversionDialog(ChildModel child, ChildProvider provider, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          type == 'points_to_stars' ? 'Converter Pontos em Estrelas' : 'Converter Estrelas em Dinheiro',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type == 'points_to_stars'
                  ? '10 pontos = 1 estrela\nPontos disponíveis: ${child.currentPoints}'
                  : '20 estrelas = R\$ 3,00\nEstrelas disponíveis: ${child.stars}',
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: type == 'points_to_stars' ? 'Quantas estrelas?' : 'Quanto em reais?',
                hintText: type == 'points_to_stars' ? 'Ex: 5' : 'Ex: 3.00',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementar conversão
            },
            child: const Text('Converter'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(ChildModel child, ChildProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sacar Dinheiro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Saldo disponível: R\$ ${child.realMoney.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Valor do saque',
                hintText: 'Ex: 10.00',
                prefixText: 'R\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementar saque
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Sacar'),
          ),
        ],
      ),
    );
  }

  void _editChild(ChildModel child) {
    // Implementar edição
  }

  void _changeAvatar(ChildModel child) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Implementar upload da imagem
    }
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