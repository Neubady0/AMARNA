import 'package:flutter/material.dart';
import 'package:amarnamovil/features/candidate/screens/profile_screen.dart';
import 'package:amarnamovil/features/candidate/screens/user_area_screen.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Hola, ${user['name'] ?? 'Candidato'}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Tooltip(
              message: 'Mi Perfil',
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen(user: user)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.secondaryColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    backgroundImage: user['cv_path'] != null 
                        ? AssetImage('assets/images/avatar_placeholder.png') as ImageProvider // Placeholder for now
                        : null,
                    child: user['cv_path'] == null 
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                  ),
                ),
              ),
            ),
          ).animate().scale(delay: 200.ms),
        ],
      ),
      body: UserAreaScreen(user: user),
    );
  }
}
