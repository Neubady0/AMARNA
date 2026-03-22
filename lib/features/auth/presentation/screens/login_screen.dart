import 'package:amarnamovil/data/local/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:amarnamovil/features/candidate/presentation/screens/ai_menu_screen.dart';
import 'package:amarnamovil/features/teacher/presentation/screens/teacher_dashboard_screen.dart';
import 'package:amarnamovil/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:amarnamovil/features/auth/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final _authService = AuthService();
  bool _canBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    // We check for stored credentials. We don't strictly enforce biometric support
    // here anymore because the user requested a direct "button" login.
    // However, secure storage availability is still required.
    final creds = await _authService.getCredentials();
    if (creds != null) {
      if (mounted) {
        setState(() {
          _canBiometric = true; // Renaming this variable would be better refactoring, but keeping for minimal diff
        });
      }
    }
  }

  Future<void> _attemptFastLogin() async {
    // Direct login using stored credentials without biometric prompt
    // as requested by user ("que con eso ya te entre directo")
    final creds = await _authService.getCredentials();
    if (creds != null) {
      await _processLogin(creds['email']!, creds['password']!);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      await _processLogin(_emailController.text, _passwordController.text);
    }
  }

  Future<void> _processLogin(String email, String password) async {
    final dbHelper = DatabaseHelper();
    final user = await dbHelper.getUser(email, password);

    if (user != null) {
      // Save credentials for fast login
      await _authService.saveCredentials(email, password);

      if (!mounted) return;
      if (user['role'] == 'Usuario') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AiMenuScreen(user: user)),
        );
      } else if (user['role'] == 'Profesor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TeacherDashboardScreen(user: user)),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid email or password'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              labelStyle: const TextStyle(color: Colors.white60),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              labelStyle: const TextStyle(color: Colors.white60),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_isPasswordVisible,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.secondaryColor,
                                foregroundColor: AppTheme.primaryColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _login,
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ),

                          if (_canBiometric) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.secondaryColor,
                                  side: const BorderSide(color: AppTheme.secondaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _attemptFastLogin,
                                icon: const Icon(Icons.flash_on),
                                label: const Text('Inicio Rápido (Guardado)'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(text: "¿No tienes cuenta? "),
                          TextSpan(
                            text: "Regístrate",
                            style: TextStyle(
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
