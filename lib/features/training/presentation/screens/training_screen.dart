import 'package:flutter/material.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador de Entrevistas'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam_rounded, size: 64, color: AppTheme.secondaryColor),
            ).animate().scale(delay: 200.ms),
            const SizedBox(height: 24),
            Text(
              'Entrenamiento Guiado',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Aquí podrás simular entrevistas con videos guiados y preguntas interactivas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text("Iniciar Simulación (Demo)"),
            ),
          ],
        ).animate().fadeIn(),
      ),
    );
  }
}
