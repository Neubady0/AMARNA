import 'dart:io';
import 'package:amarnamovil/data/local/database_helper.dart';
import 'package:amarnamovil/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:amarnamovil/features/profile/presentation/screens/pdf_viewer_screen.dart';
import 'package:amarnamovil/features/training/presentation/screens/training_screen.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:amarnamovil/features/jobs/data/data_sources/job_match_api_client.dart';
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
    _currentUser = Map<String, dynamic>.from(widget.user);
    _updateCvFileName();
    _loadFreshUserData();
  }

  Future<void> _loadFreshUserData() async {
    final dbHelper = DatabaseHelper();
    final freshUser = await dbHelper.getUserById(_currentUser['id']);
    if (freshUser != null && mounted) {
      setState(() {
        _currentUser = Map<String, dynamic>.from(freshUser);
        _updateCvFileName();
      });
    }
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
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null) {
      final cvPath = result.files.single.path!;
      
      setState(() {
        _cvFileName = "Analizando...";
      });

      try {
        final jobMatchService = JobMatchService();
        final response = await jobMatchService.analyzeCV(cvPath);
        
        final dbHelper = DatabaseHelper();
        await dbHelper.updateUserCv(_currentUser['id'], cvPath, response.originalText);

        setState(() {
          _currentUser['cv_path'] = cvPath;
          _currentUser['cv_content'] = response.originalText;
          _updateCvFileName();
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CV "$_cvFileName" analizado y guardado.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        setState(() {
          _updateCvFileName();
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar CV: $e'), backgroundColor: Colors.red),
        );
      }
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
                    AppTheme.primaryColor.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.35),
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
                    subtitle: 'Modifica tus datos profesionales y acadÃ©micos',
                    color: Colors.blueAccent,
                    onTap: _navigateToEditProfile,
                    delay: 200,
                  ),
                  
                  const SizedBox(height: 24),
                  _buildCvSection(),
                  const SizedBox(height: 24),

                  _buildJobOfferSection(),
                  const SizedBox(height: 24),

                  _buildLinksSection(),
                  const SizedBox(height: 24),

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
                      label: const Text("Cerrar SesiÃ³n", style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
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

  Future<void> _deleteCv() async {
    final dbHelper = DatabaseHelper();
    // Assuming empty string or null clears it. 
    // If table allows NULL, passing null is better, else empty string.
    // I'll update to empty string to be safe.
    await dbHelper.updateUserCv(_currentUser['id'], "", "");

    setState(() {
      _currentUser['cv_path'] = "";
      _currentUser['cv_content'] = "";
      _cvFileName = null;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CV eliminado.'), backgroundColor: Colors.redAccent),
    );
  }

  Widget _buildCvSection() {
    final hasCv = _cvFileName != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8),
          child: Text(
            "Tu CurrÃ­culum",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        GestureDetector(
          onTap: hasCv ? _viewCv : _pickAndSaveCv,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hasCv ? Colors.white : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: hasCv 
                  ? Border.all(color: Colors.transparent) 
                  : Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5), width: 2, style: BorderStyle.solid), // Should be dashed ideally
              boxShadow: hasCv 
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
                  : [],
            ),
            child: hasCv
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _cvFileName!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "Documento PDF",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _deleteCv,
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                        tooltip: "Eliminar CV",
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 40, color: AppTheme.primaryColor),
                      const SizedBox(height: 12),
                      const Text(
                        "Sube tu CV (PDF o Imagen)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Toca para analizar y vincular a la IA",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
        if (hasCv && _currentUser['cv_content'] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "CV vinculado como contexto para la IA",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
        ],
      ],
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildJobOfferSection() {
    final hasJobOffer = _currentUser['job_offer_url'] != null && _currentUser['job_offer_url'].toString().isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8),
          child: Text(
            "Oferta de Trabajo Objetivo",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        GestureDetector(
          onTap: () => _showInputDialog('job_offer_url', 'Enlace a la oferta de trabajo', 'Pega el enlace de InfoJobs, LinkedIn...'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hasJobOffer ? Colors.white : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: hasJobOffer 
                  ? Border.all(color: Colors.transparent) 
                  : Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5), width: 2, style: BorderStyle.solid),
              boxShadow: hasJobOffer 
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
                  : [],
            ),
            child: hasJobOffer
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.work_outline_rounded, color: Colors.blue, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Oferta Vinculada",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _currentUser['job_offer_url'],
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _updateUserField('job_offer_url', ''),
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                        tooltip: "Eliminar Oferta",
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.link_rounded, size: 40, color: AppTheme.primaryColor),
                      const SizedBox(height: 12),
                      const Text(
                        "Pega la Oferta de Trabajo",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Toca para añadir el enlace (LinkedIn, InfoJobs...)",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildLinksSection() {
    final hasGithub = _currentUser['github_url'] != null && _currentUser['github_url'].toString().isNotEmpty;
    final hasPortfolio = _currentUser['portfolio_url'] != null && _currentUser['portfolio_url'].toString().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8),
          child: Text(
            "Portafolio y Proyectos",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        
        // GitHub Tile
        _buildLinkTile(
          title: "Perfil de GitHub",
          subtitle: hasGithub ? _currentUser['github_url'] : "Añade tu enlace a GitHub",
          icon: Icons.code_rounded,
          color: Colors.black87,
          isSet: hasGithub,
          onTap: () => _showInputDialog('github_url', 'Enlace de GitHub', 'https://github.com/tu_usuario'),
          onDelete: () => _updateUserField('github_url', ''),
        ),
        const SizedBox(height: 12),
        // Portfolio Tile
        _buildLinkTile(
          title: "Portafolio / Web",
          subtitle: hasPortfolio ? _currentUser['portfolio_url'] : "Añade tu web o portafolio",
          icon: Icons.web_rounded,
          color: Colors.purple,
          isSet: hasPortfolio,
          onTap: () => _showInputDialog('portfolio_url', 'Enlace de tu Portafolio', 'https://tuweb.com'),
          onDelete: () => _updateUserField('portfolio_url', ''),
        ),
      ],
    ).animate().fadeIn(delay: 380.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildLinkTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSet,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return GestureDetector(
      onTap: isSet ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSet ? null : Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          boxShadow: isSet 
              ? [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Text(
            subtitle, 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: isSet ? Colors.grey.shade600 : Colors.grey.shade400, fontSize: 13),
          ),
          trailing: isSet 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                    onPressed: onTap,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    onPressed: onDelete,
                  ),
                ],
              )
            : const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  Future<void> _showInputDialog(String field, String title, String hintText) async {
    final controller = TextEditingController(text: _currentUser[field] ?? '');
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _updateUserField(field, controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserField(String field, String value) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateUserProfile(_currentUser['id'], {field: value});
    
    setState(() {
      _currentUser[field] = value;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Guardado correctamente.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            color: Colors.grey.withValues(alpha: 0.05),
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
            color: color.withValues(alpha: 0.1),
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

