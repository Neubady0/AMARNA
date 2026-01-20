import 'package:amarnamovil/features/admin/screens/create_job_offer_screen.dart';
import 'package:amarnamovil/features/admin/screens/create_simulation_screen.dart';
import 'package:amarnamovil/features/admin/screens/parameterization_screen.dart';
import 'package:amarnamovil/features/admin/screens/teacher_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminAreaScreen extends StatelessWidget {
  const AdminAreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Zona de Administrador'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_active_outlined), onPressed: (){}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          _buildAdminTile(
            context,
            icon: Icons.video_call_rounded,
            title: 'Crear Simulacro',
            subtitle: 'Configura entrevistas simuladas',
            color: Colors.blueAccent,
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const CreateSimulationScreen())
              );
            },
            delay: 100,
          ),
          _buildAdminTile(
            context,
            icon: Icons.add_business_rounded,
            title: 'Crear Oferta Laboral',
            subtitle: 'Publica nuevas vacantes',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const CreateJobOfferScreen())
              );
            },
            delay: 200,
          ),
          _buildAdminTile(
            context,
            icon: Icons.tune_rounded,
            title: 'Parametrizar Valores',
            subtitle: 'Ajusta umbrales y reglas',
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const ParameterizationScreen())
              );
            },
            delay: 300,
          ),
          _buildAdminTile(
            context,
            icon: Icons.query_stats_rounded,
            title: 'Resultados y Comparativa',
            subtitle: 'Analiza el desempeño de alumnos',
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const TeacherResultsScreen())
              );
            },
            delay: 400,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1, end: 0);
  }
}

