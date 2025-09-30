class ChildModel {
  final String id;
  final String userId;
  final String name;
  final String? avatarUrl;
  final String color;
  final DateTime? birthDate;
  final int currentPoints;
  final int totalPoints;
  final int stars;
  final double realMoney;
  final int level;
  final Map<String, dynamic>? settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChildModel({
    required this.id,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.color,
    this.birthDate,
    this.currentPoints = 0,
    this.totalPoints = 0,
    this.stars = 0,
    this.realMoney = 0.0,
    this.level = 1,
    this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'avatar_url': avatarUrl,
        'color': color,
        'birth_date': birthDate?.toIso8601String(),
        'current_points': currentPoints,
        'total_points': totalPoints,
        'stars': stars,
        'real_money': realMoney,
        'level': level,
        'settings': settings,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ChildModel.fromJson(Map<String, dynamic> json) => ChildModel(
        id: json['id'],
        userId: json['user_id'],
        name: json['name'],
        avatarUrl: json['avatar_url'],
        color: json['color'],
        birthDate: json['birth_date'] != null
            ? DateTime.parse(json['birth_date'])
            : null,
        currentPoints: json['current_points'] ?? 0,
        totalPoints: json['total_points'] ?? 0,
        stars: json['stars'] ?? 0,
        realMoney: (json['real_money'] ?? 0.0).toDouble(),
        level: json['level'] ?? 1,
        settings: json['settings'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  ChildModel copyWith({
    String? name,
    String? avatarUrl,
    String? color,
    DateTime? birthDate,
    int? currentPoints,
    int? totalPoints,
    int? stars,
    double? realMoney,
    int? level,
    Map<String, dynamic>? settings,
    DateTime? updatedAt,
  }) {
    return ChildModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      color: color ?? this.color,
      birthDate: birthDate ?? this.birthDate,
      currentPoints: currentPoints ?? this.currentPoints,
      totalPoints: totalPoints ?? this.totalPoints,
      stars: stars ?? this.stars,
      realMoney: realMoney ?? this.realMoney,
      level: level ?? this.level,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Método auxiliar para calcular idade
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }
}