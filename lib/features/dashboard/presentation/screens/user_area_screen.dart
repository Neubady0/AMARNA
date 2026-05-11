import 'package:amarnamovil/features/jobs/presentation/screens/job_offers_screen.dart';
import 'package:amarnamovil/features/training/presentation/screens/results_screen.dart';
import 'package:amarnamovil/features/interview/presentation/screens/interview_requests_screen.dart';
import 'package:amarnamovil/features/training/presentation/screens/training_screen.dart';
import 'package:flutter/material.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
class UserAreaScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserAreaScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("GestiÃ³n de Carrera"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hola, ${user['name'] ?? 'Candidato'}",
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ).animate().fadeIn().moveX(begin: -20, end: 0),
            Text(
              "Â¿QuÃ© quieres hacer hoy?",
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 32),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.85,
              children: <Widget>[
                _buildPremiumCard(
                  context,
                  icon: Icons.bar_chart_rounded,
                  title: 'Resultados',
                  subtitle: 'Mis mÃ©tricas',
                  color: Colors.purple.shade400,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultsScreen()));
                  },
                  delay: 200,
                ),
                _buildPremiumCard(
                  context,
                  icon: Icons.work_rounded,
                  title: 'Ofertas',
                  subtitle: 'Buscar empleo',
                  color: AppTheme.secondaryColor,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => JobOffersScreen(user: user)));
                  },
                  delay: 300,
                ),
                _buildPremiumCard(
                  context,
                  icon: Icons.mark_email_unread_rounded,
                  title: 'Solicitudes',
                  subtitle: 'Mis envÃ­os',
                  color: Colors.orange.shade400,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const InterviewRequestsScreen()));
                  },
                  delay: 400,
                ),
                _buildPremiumCard(
                  context,
                  icon: Icons.school_rounded,
                  title: 'Entrenar',
                  subtitle: 'SimulaciÃ³n IA',
                  color: Colors.teal.shade400,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TrainingScreen()));
                  },
                  delay: 500,
                ),
              ],
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
              color: Colors.black.withValues(alpha: 0.04),
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
                color: color.withValues(alpha: 0.15),
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

