class ConversionSettingsModel {
  final String id;
  final String userId;
  final int pointsToStars; // Quantos pontos = 1 estrela
  final int starsToMoney; // Quantas estrelas = X reais
  final double moneyPerConversion; // Valor em reais por conversão
  final bool allowMoneyConversion; // Permitir conversão para dinheiro real
  final DateTime updatedAt;

  ConversionSettingsModel({
    required this.id,
    required this.userId,
    this.pointsToStars = 10, // Padrão: 10 pontos = 1 estrela
    this.starsToMoney = 20, // Padrão: 20 estrelas = R$ 3
    this.moneyPerConversion = 3.0,
    this.allowMoneyConversion = false,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'points_to_stars': pointsToStars,
        'stars_to_money': starsToMoney,
        'money_per_conversion': moneyPerConversion,
        'allow_money_conversion': allowMoneyConversion,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ConversionSettingsModel.fromJson(Map<String, dynamic> json) =>
      ConversionSettingsModel(
        id: json['id'],
        userId: json['user_id'],
        pointsToStars: json['points_to_stars'] ?? 10,
        starsToMoney: json['stars_to_money'] ?? 20,
        moneyPerConversion: json['money_per_conversion'] != null
            ? (json['money_per_conversion'] as num).toDouble()
            : 3.0,
        allowMoneyConversion: json['allow_money_conversion'] ?? false,
        updatedAt: DateTime.parse(json['updated_at']),
      );

  ConversionSettingsModel copyWith({
    int? pointsToStars,
    int? starsToMoney,
    double? moneyPerConversion,
    bool? allowMoneyConversion,
    DateTime? updatedAt,
  }) {
    return ConversionSettingsModel(
      id: id,
      userId: userId,
      pointsToStars: pointsToStars ?? this.pointsToStars,
      starsToMoney: starsToMoney ?? this.starsToMoney,
      moneyPerConversion: moneyPerConversion ?? this.moneyPerConversion,
      allowMoneyConversion: allowMoneyConversion ?? this.allowMoneyConversion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Métodos auxiliares para conversão

  // Converte pontos para estrelas
  int convertPointsToStars(int points) {
    return (points / pointsToStars).floor();
  }

  // Calcula quantos pontos sobram após conversão
  int getRemainingPoints(int points) {
    return points % pointsToStars;
  }

  // Converte estrelas para dinheiro
  double convertStarsToMoney(int stars) {
    final conversions = (stars / starsToMoney).floor();
    return conversions * moneyPerConversion;
  }

  // Calcula quantas estrelas sobram após conversão
  int getRemainingStars(int stars) {
    return stars % starsToMoney;
  }

  // Calcula quanto vale em reais (sem fazer conversão)
  double calculateMoneyValue(int stars) {
    return (stars / starsToMoney) * moneyPerConversion;
  }

  // Texto explicativo da taxa de conversão
  String get pointsToStarsRate => '$pointsToStars pontos = 1 estrela';
  String get starsToMoneyRate =>
      '$starsToMoney estrelas = R\$ ${moneyPerConversion.toStringAsFixed(2)}';
}