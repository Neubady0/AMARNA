import 'package:flutter/material.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ParameterizationScreen extends StatelessWidget {
  const ParameterizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración y Parámetros'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildParamTile("Titubeos máximos", "5 por minuto", Icons.record_voice_over_rounded),
          _buildParamTile("Tiempo de respuesta ideal", "30-60 segundos", Icons.timer_rounded),
          _buildParamTile("Palabras prohibidas", "Uhm, Eh, Bueno...", Icons.block_rounded),
          _buildParamTile("Umbral de confianza", "85%", Icons.verified_user_rounded),
        ].animate(interval: 100.ms).fadeIn().slideX(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildParamTile(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
        trailing: const Icon(Icons.edit_rounded, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
