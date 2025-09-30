class RewardModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final int? costPoints;
  final int? costStars;
  final double? costMoney;
  final String? icon;
  final bool isActive;
  final DateTime createdAt;

  RewardModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.costPoints,
    this.costStars,
    this.costMoney,
    this.icon,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'cost_points': costPoints,
        'cost_stars': costStars,
        'cost_money': costMoney,
        'icon': icon,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  factory RewardModel.fromJson(Map<String, dynamic> json) => RewardModel(
        id: json['id'],
        userId: json['user_id'],
        title: json['title'],
        description: json['description'],
        costPoints: json['cost_points'],
        costStars: json['cost_stars'],
        costMoney: json['cost_money'] != null
            ? (json['cost_money'] as num).toDouble()
            : null,
        icon: json['icon'],
        isActive: json['is_active'] ?? true,
        createdAt: DateTime.parse(json['created_at']),
      );

  RewardModel copyWith({
    String? title,
    String? description,
    int? costPoints,
    int? costStars,
    double? costMoney,
    String? icon,
    bool? isActive,
  }) {
    return RewardModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      costPoints: costPoints ?? this.costPoints,
      costStars: costStars ?? this.costStars,
      costMoney: costMoney ?? this.costMoney,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  // Método auxiliar para verificar qual moeda usa
  String get costType {
    if (costPoints != null && costPoints! > 0) return 'points';
    if (costStars != null && costStars! > 0) return 'stars';
    if (costMoney != null && costMoney! > 0) return 'money';
    return 'free';
  }

  // Método auxiliar para formatar o custo
  String get costFormatted {
    if (costPoints != null && costPoints! > 0) return '$costPoints pontos';
    if (costStars != null && costStars! > 0) return '$costStars estrelas';
    if (costMoney != null && costMoney! > 0) {
      return 'R\$ ${costMoney!.toStringAsFixed(2)}';
    }
    return 'Grátis';
  }
}