// lib/presentation/screens/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  final bool isFirstTime;

  const SplashScreen({super.key, required this.isFirstTime});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final authProvider = context.read<AuthProvider>();

      if (widget.isFirstTime) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else if (authProvider.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B5CF6),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 60,
                color: Color(0xFF8B5CF6),
              ),
            ).animate().fadeIn(duration: 600.ms).scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 24),
            Text(
              'Tarefas Kids',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                  ),
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(
                  begin: 0.3,
                  end: 0,
                  curve: Curves.easeOutQuad,
                ),
            const SizedBox(height: 8),
            Text(
              'Tornando tarefas divertidas!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
            ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
