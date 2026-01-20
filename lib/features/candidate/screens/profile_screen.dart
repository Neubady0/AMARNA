import 'dart:io';
import 'package:amarnamovil/data/local/database_helper.dart';
import 'package:amarnamovil/features/candidate/screens/edit_profile_screen.dart';
import 'package:amarnamovil/features/candidate/screens/pdf_viewer_screen.dart';
import 'package:amarnamovil/features/candidate/screens/training_screen.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _currentUser;
  String? _cvFileName;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _updateCvFileName();
  }

  void _updateCvFileName() {
    if (_currentUser['cv_path'] != null && _currentUser['cv_path'].isNotEmpty) {
      _cvFileName = _currentUser['cv_path'].split(Platform.pathSeparator).last;
    } else {
      _cvFileName = null;
    }
  }

  Future<void> _pickAndSaveCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final cvPath = result.files.single.path!;
      final dbHelper = DatabaseHelper();

      await dbHelper.updateUserCv(_currentUser['id'], cvPath);

      setState(() {
        _currentUser['cv_path'] = cvPath;
        _updateCvFileName();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CV "$_cvFileName" guardado.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _viewCv() {
    if (_currentUser['cv_path'] != null && _currentUser['cv_path'].isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(filePath: _currentUser['cv_path']!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes subir un CV.')),
      );
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _currentUser),
      ),
    );

    if (result == true) {
      final dbHelper = DatabaseHelper();
      final updatedUser = await dbHelper.getUserById(_currentUser['id']);
      if (updatedUser != null) {
        setState(() {
          _currentUser = updatedUser;
          _updateCvFileName();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // User Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 80, bottom: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.9),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.35),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                   Container(
                     padding: const EdgeInsets.all(4),
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       border: Border.all(color: AppTheme.secondaryColor, width: 3),
                     ),
                     child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                                       ),
                   ),
                  const SizedBox(height: 16),
                  Text(
                    _currentUser['name'] ?? 'Usuario Amarna',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentUser['email'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: -0.2, end: 0),
            ),
            
            const SizedBox(height: 24),
            
            // Options List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.edit_note_rounded,
                    title: 'Datos Personales',
                    subtitle: 'Modifica tus datos profesionales y académicos',
                    color: Colors.blueAccent,
                    onTap: _navigateToEditProfile,
                    delay: 200,
                  ),
                  _buildProfileTile(
                    icon: Icons.picture_as_pdf_rounded,
                    title: 'CV Digital',
                    subtitle: _cvFileName ?? 'No hay CV subido',
                    color: Colors.redAccent,
                    onTap: _viewCv,
                    trailing: IconButton(
                      icon: const Icon(Icons.upload_file_rounded, color: AppTheme.secondaryColor),
                      onPressed: _pickAndSaveCv,
                    ),
                     delay: 300,
                  ),
                  _buildProfileTile(
                    icon: Icons.model_training_rounded,
                    title: 'Simulador',
                    subtitle: 'Entrena tus habilidades de entrevista',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TrainingScreen()),
                      );
                    },
                     delay: 400,
                  ),
                  
                  const SizedBox(height: 40),
                   SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Logout logic
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      icon: const Icon(Icons.logout, color: Colors.redAccent), 
                      label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title, 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
            overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1, end: 0);
  }
}

