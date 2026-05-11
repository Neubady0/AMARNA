import 'package:flutter/material.dart';
import 'package:amarnamovil/features/dashboard/presentation/screens/main_shell.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amarnamovil/features/auth/presentation/bloc/microsoft_login_cubit.dart';
import 'package:amarnamovil/features/auth/presentation/bloc/microsoft_login_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  void _quickStart() {
    final mockUser = {
      'id': 1,
      'email': 'invitado@amarna.com',
      'password': '',
      'role': 'Usuario',
      'name': 'Invitado'
    };
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainShell(user: mockUser)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
      child: Scaffold(
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: AppTheme.errorColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            } else if (state is AuthSuccess) {
              final user = {
                'id': 999,
                'email': state.email,
                'password': 'sso',
                'role': 'Usuario',
                'name': state.name
              };
              
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainShell(user: user)),
              );
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                // Background Gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF1E293B),
                      ],
                    ),
                  ),
                ),
                // Decorative Circles
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Logo/Title
                        Text(
                          'Amarna',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppTheme.secondaryColor,
                            letterSpacing: 1.5,
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0),
                        const SizedBox(height: 8),
                        Text(
                          'Tu carrera, al siguiente nivel',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 48),

                        // Login Card
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2F2F2F), // Color oscuro para Microsoft
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: state is AuthLoading ? null : () {
                                    context.read<AuthCubit>().login();
                                  },
                                  icon: state is AuthLoading 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.window, color: Colors.white), // Ícono representativo de Windows/Microsoft
                                  label: Text(
                                    state is AuthLoading ? 'Iniciando...' : 'Login con Microsoft',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.secondaryColor,
                                    foregroundColor: AppTheme.primaryColor,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: state is AuthLoading ? null : _quickStart,
                                  icon: const Icon(Icons.flash_on),
                                  label: const Text(
                                    'Iniciar Rápido',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
