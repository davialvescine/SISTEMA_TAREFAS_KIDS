class RedemptionModel {
  final String id;
  final String childId;
  final String? rewardId;
  final String? rewardTitle;
  final int? costPoints;
  final int? costStars;
  final double? costMoney;
  final DateTime redeemedAt;

  RedemptionModel({
    required this.id,
    required this.childId,
    this.rewardId,
    this.rewardTitle,
    this.costPoints,
    this.costStars,
    this.costMoney,
    required this.redeemedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'child_id': childId,
        'reward_id': rewardId,
        'reward_title': rewardTitle,
        'cost_points': costPoints,
        'cost_stars': costStars,
        'cost_money': costMoney,
        'redeemed_at': redeemedAt.toIso8601String(),
      };

  factory RedemptionModel.fromJson(Map<String, dynamic> json) =>
      RedemptionModel(
        id: json['id'],
        childId: json['child_id'],
        rewardId: json['reward_id'],
        rewardTitle: json['reward_title'],
        costPoints: json['cost_points'],
        costStars: json['cost_stars'],
        costMoney: json['cost_money'] != null
            ? (json['cost_money'] as num).toDouble()
            : null,
        redeemedAt: DateTime.parse(json['redeemed_at']),
      );

  // Método auxiliar para qual moeda foi usada
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