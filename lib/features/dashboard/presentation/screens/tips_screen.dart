import 'package:flutter/material.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class TipsScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const TipsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo simulando una interacción previa con la IA
    final List<Map<String, String>> sampleTips = [
      {
        'title': 'Fortalece tu sección de Tecnologías',
        'content': 'La IA detectó que mencionas Python pero no especificas frameworks. Añade FastAPI o Django para mejorar tu visibilidad en un 25%.',
        'icon': '💻',
        'category': 'Curriculum',
      },
      {
        'title': 'Tono de voz en Entrevistas',
        'content': 'En tu última simulación, tu tono fue excelente, pero hablas un poco rápido. Intenta pausar 1 segundo tras cada pregunta técnica.',
        'icon': '🗣️',
        'category': 'Entrevista',
      },
      {
        'title': 'Palabras clave faltantes',
        'content': 'Para los puestos de Backend que te interesan, te falta incluir "Docker" y "CI/CD" en tu CV. Son requisitos en el 80% de las ofertas.',
        'icon': '🔍',
        'category': 'Análisis',
      },
      {
        'title': 'Estructura de logros',
        'content': 'En lugar de listar tareas, usa el método STAR (Situación, Tarea, Acción, Resultado) para tus proyectos de DAM.',
        'icon': '📈',
        'category': 'Curriculum',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Consejos de Amarna',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: sampleTips.length,
        itemBuilder: (context, index) {
          final tip = sampleTips[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    tip['icon']!,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tip['category']!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tip['title']!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tip['content']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }
}
