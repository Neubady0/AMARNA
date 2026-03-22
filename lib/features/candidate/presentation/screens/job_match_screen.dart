import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:amarnamovil/core/services/job_match_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amarnamovil/data/local/database_helper.dart';

class JobMatchScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const JobMatchScreen({super.key, required this.user});

  @override
  State<JobMatchScreen> createState() => _JobMatchScreenState();
}

class _JobMatchScreenState extends State<JobMatchScreen> {
  final JobMatchService _jobMatchService = JobMatchService();
  bool _isLoading = false;
  List<JobMatchResult> _results = [];
  String? _errorMessage;
  String? _selectedFileName;

  Future<void> _pickAndAnalyzeCV() async {
    setState(() {
      _errorMessage = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isLoading = true;
        _selectedFileName = result.files.single.name;
        _results = [];
      });

      try {
        final filePath = result.files.single.path!;
        final response = await _jobMatchService.analyzeCV(filePath);
        
        // Almacenar automáticamente el CV en SQLite
        final dbHelper = DatabaseHelper();
        await dbHelper.updateUserCv(widget.user['id'], filePath, response.originalText);
        
        setState(() {
          _results = response.results;
          _isLoading = false;
        });
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Currículum guardado y vinculado a tu cuenta')),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'JobMatch AI',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _results.isEmpty
                      ? _buildEmptyState()
                      : _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.psychology_outlined, size: 48, color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            "Analiza tu CV con IA",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Sube tu currículum y descubre qué ofertas encajan mejor con tu perfil profesional.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickAndAnalyzeCV,
            icon: const Icon(Icons.upload_file),
            label: Text(_isLoading ? "Procesando..." : "Seleccionar CV"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
          ).animate(target: _isLoading ? 1 : 0).shimmer(),
          if (_selectedFileName != null && !_isLoading) ...[
            const SizedBox(height: 12),
            Text(
              "Archivo: $_selectedFileName",
              style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 24),
          Text(
            "Nuestra IA está analizando tu CV...",
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            "Esto puede tardar unos segundos",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_history_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Sin resultados aún",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Sube un archivo para empezar la búsqueda de matches.",
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return _buildMatchCard(result, index);
      },
    );
  }

  Widget _buildMatchCard(JobMatchResult result, int index) {
    Color matchColor = _getMatchColor(result.porcentajeMatch);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: matchColor.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.titulo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Oportunidad de Carrera",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: matchColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${result.porcentajeMatch}% Match",
                          style: TextStyle(
                            color: matchColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        "¿Por qué encajas?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.razonClave,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Action to apply or view details
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Ver Vacante", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 150).ms).fadeIn().slideY(begin: 0.2, end: 0);
  }

  Color _getMatchColor(int percentage) {
    if (percentage >= 80) return Colors.green.shade600;
    if (percentage >= 50) return Colors.orange.shade600;
    return Colors.red.shade400;
  }
}
