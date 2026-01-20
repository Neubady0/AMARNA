import 'package:amarnamovil/features/candidate/screens/job_offers_screen.dart';
import 'package:amarnamovil/features/candidate/screens/results_screen.dart';
import 'package:amarnamovil/features/candidate/screens/interview_requests_screen.dart';
import 'package:amarnamovil/features/candidate/screens/training_screen.dart';
import 'package:flutter/material.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UserAreaScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserAreaScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Panel de Control",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn().moveX(begin: -20, end: 0),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: <Widget>[
                  _buildPremiumCard(
                    context,
                    icon: Icons.bar_chart_rounded,
                    title: 'Resultados',
                    subtitle: 'Ver mis métricas',
                    color: Colors.purple.shade400,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ResultsScreen()),
                      );
                    },
                    delay: 100,
                  ),
                  _buildPremiumCard(
                    context,
                    icon: Icons.work_rounded,
                    title: 'Ofertas',
                    subtitle: 'Buscar empleo',
                    color: AppTheme.secondaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => JobOffersScreen(user: user)),
                      );
                    },
                    delay: 200,
                  ),
                  _buildPremiumCard(
                    context,
                    icon: Icons.mark_email_unread_rounded,
                    title: 'Solicitudes',
                    subtitle: 'Peticiones de entrevista',
                    color: Colors.orange.shade400,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const InterviewRequestsScreen()),
                      );
                    },
                    delay: 300,
                  ),
                  _buildPremiumCard(
                    context,
                    icon: Icons.school_rounded,
                    title: 'Entrenar',
                    subtitle: 'Simular entrevista',
                    color: Colors.teal.shade400,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TrainingScreen()),
                      );
                    },
                    delay: 400,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, end: 0),
    );
  }
}

