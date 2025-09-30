import 'package:flutter/material.dart';

class LevelSystem {
  static const List<LevelInfo> levels = [
    LevelInfo(
      level: 1,
      title: 'Iniciante',
      minPoints: 0,
      maxPoints: 149,
      color: Colors.grey,
      icon: Icons.star_border,
      description: 'Começando a jornada!',
    ),
    LevelInfo(
      level: 2,
      title: 'Ajudante',
      minPoints: 150,
      maxPoints: 299,
      color: Colors.blue,
      icon: Icons.star_half,
      description: 'Sempre pronto para ajudar!',
    ),
    LevelInfo(
      level: 3,
      title: 'Super Ajudante',
      minPoints: 300,
      maxPoints: 599,
      color: Colors.green,
      icon: Icons.star,
      description: 'Um super herói das tarefas!',
    ),
    LevelInfo(
      level: 4,
      title: 'Herói',
      minPoints: 600,
      maxPoints: 799,
      color: Colors.orange,
      icon: Icons.military_tech,
      description: 'Herói da casa!',
    ),
    LevelInfo(
      level: 5,
      title: 'Lenda',
      minPoints: 800,
      maxPoints: 999,
      color: Colors.purple,
      icon: Icons.emoji_events,
      description: 'Uma verdadeira lenda!',
    ),
    LevelInfo(
      level: 6,
      title: 'Mestre',
      minPoints: 1000,
      maxPoints: 999999,
      color: Colors.red,
      icon: Icons.workspace_premium,
      description: 'O mestre supremo das tarefas!',
    ),
  ];

  // Obter informações do nível atual
  static LevelInfo getCurrentLevel(int totalPoints) {
    for (final level in levels.reversed) {
      if (totalPoints >= level.minPoints) {
        return level;
      }
    }
    return levels.first;
  }

  // Calcular progresso para o próximo nível
  static double getLevelProgress(int totalPoints) {
    final currentLevel = getCurrentLevel(totalPoints);

    if (currentLevel.level == levels.last.level) {
      return 1.0; // Nível máximo
    }

    final pointsInLevel = totalPoints - currentLevel.minPoints;
    final pointsNeeded = currentLevel.maxPoints - currentLevel.minPoints + 1;

    return (pointsInLevel / pointsNeeded).clamp(0.0, 1.0);
  }

  // Obter pontos necessários para o próximo nível
  static int getPointsToNextLevel(int totalPoints) {
    final currentLevel = getCurrentLevel(totalPoints);

    if (currentLevel.level == levels.last.level) {
      return 0; // Já está no nível máximo
    }

    return currentLevel.maxPoints - totalPoints + 1;
  }

  // Obter próximo nível
  static LevelInfo? getNextLevel(int totalPoints) {
    final currentLevel = getCurrentLevel(totalPoints);

    if (currentLevel.level < levels.length) {
      return levels[currentLevel.level]; // O próximo está no índice do level atual
    }

    return null; // Não há próximo nível
  }

  // Verificar se subiu de nível
  static bool checkLevelUp(int oldPoints, int newPoints) {
    final oldLevel = getCurrentLevel(oldPoints);
    final newLevel = getCurrentLevel(newPoints);

    return newLevel.level > oldLevel.level;
  }

  // Obter mensagem de parabéns ao subir de nível
  static String getLevelUpMessage(LevelInfo newLevel) {
    final messages = {
      2: '🎉 Parabéns! Você agora é um Ajudante!',
      3: '🌟 Incrível! Você se tornou um Super Ajudante!',
      4: '🦸 Uau! Você é um verdadeiro Herói agora!',
      5: '🏆 Espetacular! Você é uma Lenda viva!',
      6: '👑 IMPRESSIONANTE! Você alcançou o nível Mestre!',
    };

    return messages[newLevel.level] ?? '🎊 Parabéns pelo novo nível!';
  }

  // Obter cor gradiente do nível
  static List<Color> getLevelGradient(int totalPoints) {
    final level = getCurrentLevel(totalPoints);

    switch (level.level) {
      case 1:
        return [Colors.grey.shade400, Colors.grey.shade600];
      case 2:
        return [Colors.blue.shade400, Colors.blue.shade600];
      case 3:
        return [Colors.green.shade400, Colors.green.shade600];
      case 4:
        return [Colors.orange.shade400, Colors.orange.shade600];
      case 5:
        return [Colors.purple.shade400, Colors.purple.shade600];
      case 6:
        return [Colors.red.shade400, Colors.red.shade600];
      default:
        return [Colors.grey.shade400, Colors.grey.shade600];
    }
  }

  // Obter badge/conquista especial
  static String? getSpecialBadge(int totalPoints) {
    if (totalPoints >= 100 && totalPoints < 200) {
      return '🥉 Centurião';
    } else if (totalPoints >= 500 && totalPoints < 600) {
      return '🥈 Meio Milhar';
    } else if (totalPoints >= 1000 && totalPoints < 1100) {
      return '🥇 Milionário de Pontos';
    } else if (totalPoints >= 2000) {
      return '💎 Diamante';
    }
    return null;
  }

  // Calcular multiplicador de pontos baseado em streak
  static double getStreakMultiplier(int daysStreak) {
    if (daysStreak >= 30) return 2.0;
    if (daysStreak >= 14) return 1.5;
    if (daysStreak >= 7) return 1.25;
    if (daysStreak >= 3) return 1.1;
    return 1.0;
  }
}

// Classe para informações do nível
class LevelInfo {
  final int level;
  final String title;
  final int minPoints;
  final int maxPoints;
  final Color color;
  final IconData icon;
  final String description;

  const LevelInfo({
    required this.level,
    required this.title,
    required this.minPoints,
    required this.maxPoints,
    required this.color,
    required this.icon,
    required this.description,
  });

  // Widget para exibir o badge do nível
  Widget buildBadge({double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.8),
            color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }

  // Widget para exibir a barra de progresso
  static Widget buildProgressBar({
    required int totalPoints,
    double height = 20,
    bool showText = true,
  }) {
    final progress = LevelSystem.getLevelProgress(totalPoints);
    final pointsToNext = LevelSystem.getPointsToNextLevel(totalPoints);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: LevelSystem.getLevelGradient(totalPoints),
                    ),
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
              if (showText)
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showText && pointsToNext > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Faltam $pointsToNext pontos para ${LevelSystem.getNextLevel(totalPoints)?.title ?? "o próximo nível"}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }
}