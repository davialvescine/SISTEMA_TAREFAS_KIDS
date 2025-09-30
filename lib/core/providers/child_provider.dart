import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/child_model.dart';
import '../models/activity_model.dart';
import '../utils/level_system.dart';
import 'dart:developer';

class ChildProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<ChildModel> _children = [];
  ChildModel? _selectedChild;
  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ChildModel> get children => _children;
  ChildModel? get selectedChild => _selectedChild;
  List<ActivityModel> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Estatísticas da família
  int get totalFamilyPoints =>
      _children.fold(0, (sum, child) => sum + child.totalPoints);
  int get totalFamilyStars =>
      _children.fold(0, (sum, child) => sum + child.stars);
  double get totalFamilyMoney =>
      _children.fold(0.0, (sum, child) => sum + child.realMoney);

  ChildProvider() {
    loadChildren();
  }

  // Carregar todas as crianças do usuário
  Future<void> loadChildren() async {
    try {
      _setLoading(true);
      _clearError();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _setError('Usuário não autenticado');
        return;
      }

      final response = await _supabase
          .from('children')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _children = (response as List)
          .map((json) => ChildModel.fromJson(json))
          .toList();

      // Se tiver crianças e nenhuma selecionada, seleciona a primeira
      if (_children.isNotEmpty && _selectedChild == null) {
        _selectedChild = _children.first;
      }

      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar crianças: $e');
      log('Erro loadChildren: $e', name: 'ChildProvider');
    } finally {
      _setLoading(false);
    }
  }

  // Adicionar nova criança
  Future<bool> addChild({
    required String name,
    required String color,
    DateTime? birthDate,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final userId = _supabase.auth.currentUser?.id;
      log('UserId atual: $userId', name: 'ChildProvider');

      if (userId == null) {
        _setError('Usuário não autenticado');
        log('ERRO: Usuário não autenticado', name: 'ChildProvider');
        return false;
      }

      log('Tentando inserir criança com dados: name=$name, color=$color, userId=$userId', name: 'ChildProvider');

      // Dados mínimos necessários primeiro
      final insertData = {
        'user_id': userId,
        'name': name,
        'color': color,
      };

      // Adicionar campos opcionais apenas se tiverem valor
      if (birthDate != null) {
        insertData['birth_date'] = birthDate.toIso8601String();
      }

      log('Dados para inserção: $insertData', name: 'ChildProvider');

      dynamic response;

      try {
        response = await _supabase
            .from('children')
            .insert(insertData)
            .select()
            .single();

        log('Inserção bem-sucedida!', name: 'ChildProvider');
      } catch (insertError) {
        log('Erro específico na inserção: $insertError', name: 'ChildProvider');

        // Tentar inserção alternativa sem select
        try {
          await _supabase.from('children').insert(insertData);

          // Buscar a criança recém-criada
          response = await _supabase
              .from('children')
              .select()
              .eq('user_id', userId)
              .eq('name', name)
              .order('created_at', ascending: false)
              .limit(1)
              .single();

          log('Busca após inserção bem-sucedida', name: 'ChildProvider');
        } catch (alternativeError) {
          log('Erro na tentativa alternativa: $alternativeError', name: 'ChildProvider');
          rethrow;
        }
      }

      log('Resposta do Supabase: $response', name: 'ChildProvider');

      final newChild = ChildModel.fromJson(response);
      _children.insert(0, newChild);

      // Se for a primeira criança, seleciona automaticamente
      if (_children.length == 1) {
        _selectedChild = newChild;
      }

      notifyListeners();
      return true;

    } on PostgrestException catch (e) {
      _setError('Erro do banco: ${e.message}');
      log('PostgrestException: ${e.message}, código: ${e.code}, detalhes: ${e.details}', name: 'ChildProvider');
      return false;
    } catch (e, stackTrace) {
      _setError('Erro ao adicionar criança: $e');
      log('Erro addChild: $e', name: 'ChildProvider', error: e, stackTrace: stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Atualizar criança
  Future<bool> updateChild({
    required String childId,
    String? name,
    String? color,
    DateTime? birthDate,
    String? avatarUrl,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (color != null) updates['color'] = color;
      if (birthDate != null) updates['birth_date'] = birthDate.toIso8601String();
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      final response = await _supabase
          .from('children')
          .update(updates)
          .eq('id', childId)
          .select()
          .single();

      final updatedChild = ChildModel.fromJson(response);

      // Atualiza na lista local
      final index = _children.indexWhere((c) => c.id == childId);
      if (index != -1) {
        _children[index] = updatedChild;
      }

      // Se for a criança selecionada, atualiza também
      if (_selectedChild?.id == childId) {
        _selectedChild = updatedChild;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao atualizar criança: $e');
      log('Erro updateChild: $e', name: 'ChildProvider');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Deletar criança
  Future<bool> deleteChild(String childId) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.from('children').delete().eq('id', childId);

      // Remove da lista local
      _children.removeWhere((c) => c.id == childId);

      // Se era a selecionada, seleciona outra
      if (_selectedChild?.id == childId) {
        _selectedChild = _children.isNotEmpty ? _children.first : null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao deletar criança: $e');
      log('Erro deleteChild: $e', name: 'ChildProvider');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Selecionar criança
  void selectChild(ChildModel child) {
    _selectedChild = child;
    loadActivities(child.id);
    notifyListeners();
  }

  // Carregar atividades da criança
  Future<void> loadActivities(String childId) async {
    try {
      final response = await _supabase
          .from('activities')
          .select('*')
          .eq('child_id', childId)
          .order('completed_at', ascending: false)
          .limit(50);

      _activities = (response as List)
          .map((json) => ActivityModel.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      log('Erro loadActivities: $e', name: 'ChildProvider');
    }
  }

  // Marcar tarefa como completa
  Future<bool> completeTask({
    required String childId,
    required String taskId,
    required String taskName,
    required int points,
    required String type,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Inserir atividade
      await _supabase.from('activities').insert({
        'child_id': childId,
        'task_id': taskId,
        'task_name': taskName,
        'points': points,
        'type': type,
      });

      // Recarregar criança para pegar pontos atualizados
      await loadChildren();
      await loadActivities(childId);

      // Verificar se subiu de nível
      final child = _children.firstWhere((c) => c.id == childId);
      final oldLevel = LevelSystem.getCurrentLevel(child.totalPoints - points);
      final newLevel = LevelSystem.getCurrentLevel(child.totalPoints);

      if (newLevel.level > oldLevel.level) {
        // Retorna true indicando que subiu de nível
        return true;
      }

      return false;
    } catch (e) {
      _setError('Erro ao marcar tarefa: $e');
      log('Erro completeTask: $e', name: 'ChildProvider');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Converter pontos em estrelas
  Future<bool> convertPointsToStars(String childId, int starsToAdd) async {
    try {
      _setLoading(true);
      _clearError();

      final child = _children.firstWhere((c) => c.id == childId);
      final pointsNeeded = starsToAdd * 10; // 10 pontos = 1 estrela

      if (child.currentPoints < pointsNeeded) {
        _setError('Pontos insuficientes');
        return false;
      }

      // Atualizar no banco
      await _supabase.from('children').update({
        'current_points': child.currentPoints - pointsNeeded,
        'stars': child.stars + starsToAdd,
      }).eq('id', childId);

      // Recarregar
      await loadChildren();
      return true;
    } catch (e) {
      _setError('Erro ao converter pontos: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Converter estrelas em dinheiro
  Future<bool> convertStarsToMoney(String childId, double moneyToAdd) async {
    try {
      _setLoading(true);
      _clearError();

      final child = _children.firstWhere((c) => c.id == childId);
      final starsNeeded = (moneyToAdd / 0.15).round(); // 20 estrelas = R$ 3

      if (child.stars < starsNeeded) {
        _setError('Estrelas insuficientes');
        return false;
      }

      // Atualizar no banco
      await _supabase.from('children').update({
        'stars': child.stars - starsNeeded,
        'real_money': child.realMoney + moneyToAdd,
      }).eq('id', childId);

      // Recarregar
      await loadChildren();
      return true;
    } catch (e) {
      _setError('Erro ao converter estrelas: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sacar dinheiro
  Future<bool> withdrawMoney(String childId, double amount) async {
    try {
      _setLoading(true);
      _clearError();

      final child = _children.firstWhere((c) => c.id == childId);

      if (child.realMoney < amount) {
        _setError('Saldo insuficiente');
        return false;
      }

      // Registrar saque como atividade especial
      await _supabase.from('activities').insert({
        'child_id': childId,
        'task_name': 'Saque realizado',
        'points': 0,
        'type': 'negative',
        'description': 'Saque de R\$ ${amount.toStringAsFixed(2)}',
      });

      // Atualizar saldo
      await _supabase.from('children').update({
        'real_money': child.realMoney - amount,
      }).eq('id', childId);

      // Recarregar
      await loadChildren();
      return true;
    } catch (e) {
      _setError('Erro ao sacar dinheiro: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Obter estatísticas da criança
  Map<String, dynamic> getChildStats(String childId) {
    final child = _children.firstWhere((c) => c.id == childId);
    final childActivities = _activities.where((a) => a.childId == childId).toList();

    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(today.year, today.month, 1);

    final todayActivities = childActivities.where((a) {
      final actDate = a.completedAt;
      return actDate.day == today.day &&
          actDate.month == today.month &&
          actDate.year == today.year;
    }).toList();

    final weekActivities = childActivities.where((a) {
      return a.completedAt.isAfter(startOfWeek);
    }).toList();

    final monthActivities = childActivities.where((a) {
      return a.completedAt.isAfter(startOfMonth);
    }).toList();

    final todayPoints = todayActivities.fold(0, (sum, a) => sum + a.points);
    final weekPoints = weekActivities.fold(0, (sum, a) => sum + a.points);
    final monthPoints = monthActivities.fold(0, (sum, a) => sum + a.points);

    return {
      'totalPoints': child.totalPoints,
      'currentPoints': child.currentPoints,
      'stars': child.stars,
      'realMoney': child.realMoney,
      'level': LevelSystem.getCurrentLevel(child.totalPoints),
      'levelProgress': LevelSystem.getLevelProgress(child.totalPoints),
      'pointsToNextLevel': LevelSystem.getPointsToNextLevel(child.totalPoints),
      'todayPoints': todayPoints,
      'weekPoints': weekPoints,
      'monthPoints': monthPoints,
      'todayTasks': todayActivities.length,
      'weekTasks': weekActivities.length,
      'monthTasks': monthActivities.length,
      'age': child.age,
    };
  }

  // Configurar realtime subscription
  void setupRealtimeSubscription() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Escutar mudanças nas crianças
    _supabase
        .from('children')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((List<Map<String, dynamic>> data) {
      _children = data.map((json) => ChildModel.fromJson(json)).toList();

      // Atualizar criança selecionada se necessário
      if (_selectedChild != null) {
        final updated = _children.firstWhere(
          (c) => c.id == _selectedChild!.id,
          orElse: () => _selectedChild!,
        );
        _selectedChild = updated;
      }

      notifyListeners();
    });
  }

  // Métodos auxiliares
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}