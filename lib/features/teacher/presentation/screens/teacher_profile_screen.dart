import 'package:flutter/material.dart';
import 'package:amarnamovil/features/candidate/presentation/screens/edit_profile_screen.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TeacherProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const TeacherProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Perfil del Profesor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
             Center(
               child: Column(
                 children: [
                   const CircleAvatar(
                     radius: 50,
                     backgroundColor: AppTheme.secondaryColor,
                     child: Icon(Icons.person, size: 50, color: Colors.white),
                   ).animate().scale(),
                   const SizedBox(height: 16),
                   Text(
                     user['name'] ?? 'Profesor',
                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                   ),
                   Text(
                     user['email'] ?? '',
                     style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                   ),
                 ],
               ),
             ),
             const SizedBox(height: 40),
            _buildActionTile(
              context,
              icon: Icons.edit_note_rounded,
              title: 'Modificar Datos Personales',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)),
                );
              },
            ),
             const SizedBox(height: 20),
             SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                     Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.redAccent)),
                   style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    ).animate().slideX();
  }
}

