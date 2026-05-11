import 'package:flutter/material.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:amarnamovil/features/dashboard/presentation/screens/home_screen.dart';
import 'package:amarnamovil/features/profile/presentation/screens/profile_screen.dart';
import 'package:amarnamovil/features/jobs/presentation/screens/job_match_screen.dart';
import 'package:amarnamovil/features/dashboard/presentation/screens/tips_screen.dart';
import 'package:amarnamovil/features/dashboard/presentation/screens/stats_screen.dart';

class AiMenuScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const AiMenuScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leadingWidth: 150,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Amarna',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(user: user)),
                );
              },
              child: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  user['name'] != null ? user['name'][0].toUpperCase() : 'U',
                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Asistente de Inteligencia Artificial",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn().moveX(begin: -20, end: 0),
            const SizedBox(height: 8),
            Text(
              "Elige una de las herramientas de IA para impulsar tu carrera.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildPremiumCard(
                    context,
                    title: 'Entrenador IA',
                    subtitle: 'Simula entrevistas en modo chat.',
                    icon: Icons.chat_bubble_outline,
                    color: AppTheme.secondaryColor,
                    delay: 200,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
                      );
                    },
                  ),
                  _buildPremiumCard(
                    context,
                    title: 'JobMatch AI',
                    subtitle: 'Compara tu CV con las ofertas.',
                    icon: Icons.work_outline,
                    color: Colors.purple.shade400,
                    delay: 300,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => JobMatchScreen(user: user)),
                      );
                    },
                  ),
                  _buildPremiumCard(
                    context,
                    title: 'Consejos IA',
                    subtitle: 'Mejora con feedback personalizado.',
                    icon: Icons.lightbulb_outline,
                    color: Colors.orange.shade400,
                    delay: 400,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TipsScreen(user: user)),
                      );
                    },
                  ),
                  _buildPremiumCard(
                    context,
                    title: 'MÃ©tricas',
                    subtitle: 'EstadÃ­sticas globales de tu perfil.',
                    icon: Icons.insert_chart_outlined,
                    color: Colors.teal.shade400,
                    delay: 500,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StatsScreen(user: user)),
                      );
                    },
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
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int delay,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, end: 0),
    );
  }
}
