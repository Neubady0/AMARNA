import 'package:flutter/material.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CreateJobOfferScreen extends StatelessWidget {
  const CreateJobOfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Oferta Laboral'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildInput(label: "Título del Puesto", icon: Icons.work_outline),
            const SizedBox(height: 16),
            _buildInput(label: "Ubicación", icon: Icons.location_on_outlined),
            const SizedBox(height: 16),
            _buildInput(label: "Descripción", icon: Icons.description_outlined, maxLines: 5),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Oferta publicada (Simulada)')),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                icon: const Icon(Icons.publish_rounded),
                label: const Text("Publicar Oferta"),
              ),
            ),
          ],
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildInput({required String label, required IconData icon, int maxLines = 1}) {
    return TextFormField(
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}
