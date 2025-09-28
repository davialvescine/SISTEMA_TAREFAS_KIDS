// lib/core/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = _supabase.auth.currentUser;

    // Escutar mudanças de autenticação
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  // Login com email e senha
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        notifyListeners();
        return true;
      }

      return false;
    } on AuthException catch (e) {
      _setError(_getErrorMessage(e.message));
      return false;
    } catch (e) {
      _setError('Erro ao fazer login. Tente novamente.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Registro com email e senha - VERSÃO CORRIGIDA
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Passo 1: Criar usuário no Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name}, // Metadados do usuário
      );

      if (response.user != null) {
        // Passo 2: Criar registro na tabela users
        // IMPORTANTE: Usar upsert ao invés de insert para evitar erro de duplicação
        try {
          await _supabase
              .from('users')
              .upsert({
                'id': response.user!.id,
                'email': email,
                'name': name,
              })
              .select()
              .single();

          _user = response.user;
          notifyListeners();
          return true;
        } catch (dbError) {
          // Se falhar ao criar na tabela users, fazer login automático
          // pois o usuário já foi criado no Auth
          print('Aviso: Erro ao criar perfil na tabela users: $dbError');

          // Tentar fazer login automático
          final loginResult = await signInWithEmail(
            email: email,
            password: password,
          );

          if (loginResult) {
            // Se login funcionou, tentar criar o registro novamente
            try {
              await _supabase
                  .from('users')
                  .upsert({
                    'id': _supabase.auth.currentUser!.id,
                    'email': email,
                    'name': name,
                  })
                  .select()
                  .single();
            } catch (e) {
              print('Aviso: Perfil será criado no próximo login');
            }
          }

          return loginResult;
        }
      }

      _setError('Erro ao criar conta. Tente novamente.');
      return false;
    } on AuthException catch (e) {
      _setError(_getErrorMessage(e.message));
      return false;
    } catch (e) {
      _setError('Erro inesperado: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError('Erro ao fazer logout.');
    }
  }

  // Resetar senha
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } on AuthException catch (e) {
      _setError(_getErrorMessage(e.message));
      return false;
    } catch (e) {
      _setError('Erro ao enviar email de recuperação.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verificar e criar perfil se necessário (útil para usuários que já existem)
  Future<void> ensureUserProfile() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      try {
        // Verificar se o perfil existe
        final profile = await _supabase
            .from('users')
            .select()
            .eq('id', currentUser.id)
            .maybeSingle();

        // Se não existe, criar
        if (profile == null) {
          await _supabase
              .from('users')
              .upsert({
                'id': currentUser.id,
                'email': currentUser.email,
                'name': currentUser.userMetadata?['name'] ??
                    currentUser.email?.split('@')[0] ??
                    'Usuário',
              })
              .select()
              .single();
        }
      } catch (e) {
        print('Erro ao verificar/criar perfil: $e');
      }
    }
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

  String _getErrorMessage(String message) {
    // Traduzir mensagens de erro comuns
    if (message.contains('Invalid login credentials')) {
      return 'Email ou senha incorretos';
    }
    if (message.contains('Email not confirmed')) {
      return 'Por favor, confirme seu email antes de fazer login';
    }
    if (message.contains('User already registered')) {
      return 'Este email já está cadastrado';
    }
    if (message.contains('duplicate key')) {
      return 'Usuário já existe. Tente fazer login.';
    }
    return message;
  }
}
