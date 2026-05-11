import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:amarnamovil/features/jobs/data/data_sources/job_match_api_client.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amarnamovil/data/local/database_helper.dart';
import 'package:path_provider/path_provider.dart';

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
  String? _originalText;
  late Map<String, dynamic> _editableUser;

  // Camera
  CameraController? _cameraController;
  bool _isCameraOpen = false;
  bool _isCameraInitialized = false;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    _editableUser = Map<String, dynamic>.from(widget.user);
    _initCameras();
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('Error loading cameras: $e');
    }
  }

  Future<void> _openCamera() async {
    if (_cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontrÃ³ ninguna cÃ¡mara')),
        );
      }
      return;
    }
    final back = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );
    _cameraController = CameraController(back, ResolutionPreset.high, enableAudio: false);
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() { _isCameraOpen = true; _isCameraInitialized = true; });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _takePictureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      setState(() => _isLoading = true);
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/cv_capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final xFile = await _cameraController!.takePicture();
      final file = File(xFile.path);
      await file.copy(path);
      setState(() {
        _isCameraOpen = false;
        _isCameraInitialized = false;
        _selectedFileName = 'Foto del CV';
        _results = [];
        _errorMessage = null;
      });
      await _cameraController?.dispose();
      _cameraController = null;
      await _analyzeFile(path);
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = e.toString(); });
    }
  }

  void _closeCamera() {
    _cameraController?.dispose();
    _cameraController = null;
    setState(() { _isCameraOpen = false; _isCameraInitialized = false; });
  }

  Future<void> _pickAndAnalyzeCV() async {
    setState(() => _errorMessage = null);
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
      await _analyzeFile(result.files.single.path!);
    }
  }

  Future<void> _analyzeFile(String filePath) async {
    try {
      final response = await _jobMatchService.analyzeCV(filePath);
      final dbHelper = DatabaseHelper();
      await dbHelper.updateUserCv(_editableUser['id'], filePath, response.originalText);
      _editableUser['cv_path'] = filePath;
      _editableUser['cv_content'] = response.originalText;
      try {
        widget.user['cv_path'] = filePath;
        widget.user['cv_content'] = response.originalText;
      } catch (_) {}
      setState(() { _results = response.results; _isLoading = false; _originalText = response.originalText; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text('CV guardado y vinculado a tu cuenta'),
            ]),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() { _errorMessage = e.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCameraOpen && _isCameraInitialized) {
      return _buildCameraView();
    }
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
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
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // CAMERA VIEW
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildCameraView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview full screen
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            ),
            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _closeCamera,
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'FotografÃ­a tu CV',
                      style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            // Guide frame
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.82,
                height: MediaQuery.of(context).size.height * 0.55,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.secondaryColor, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Corner decorations
                    ..._buildCornerDecorations(),
                  ],
                ),
              ),
            ),
            // Hint text
            Positioned(
              top: MediaQuery.of(context).size.height * 0.28,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: Text('Encuadra el CV dentro del marco', style: GoogleFonts.lato(color: Colors.white70, fontSize: 13)),
                ),
              ),
            ),
            // Bottom capture button
            Positioned(
              bottom: 32,
              left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _takePictureAndAnalyze,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppTheme.secondaryColor, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate(onPlay: (loop) => loop.repeat(reverse: true))
                 .scaleXY(begin: 1.0, end: 1.05, duration: 1.seconds, curve: Curves.easeInOut),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerDecorations() {
    const size = 20.0;
    const thick = 3.0;
    final color = AppTheme.secondaryColor;
    return [
      // TL
      Positioned(top: -1, left: -1,
        child: Container(width: size, height: thick, color: color)),
      Positioned(top: -1, left: -1,
        child: Container(width: thick, height: size, color: color)),
      // TR
      Positioned(top: -1, right: -1,
        child: Container(width: size, height: thick, color: color)),
      Positioned(top: -1, right: -1,
        child: Container(width: thick, height: size, color: color)),
      // BL
      Positioned(bottom: -1, left: -1,
        child: Container(width: size, height: thick, color: color)),
      Positioned(bottom: -1, left: -1,
        child: Container(width: thick, height: size, color: color)),
      // BR
      Positioned(bottom: -1, right: -1,
        child: Container(width: size, height: thick, color: color)),
      Positioned(bottom: -1, right: -1,
        child: Container(width: thick, height: size, color: color)),
    ];
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // MAIN HEADER
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 56, left: 24, right: 24, bottom: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, Color(0xFF1E3A5F)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.secondaryColor, size: 14),
                const SizedBox(width: 6),
                Text('Potenciado por IA', style: GoogleFonts.lato(color: AppTheme.secondaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 14),
          Text(
            'JobMatch AI',
            style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 6),
          Text(
            'Sube tu currÃ­culum y descubre quÃ© ofertas encajan con tu perfil.',
            style: GoogleFonts.lato(color: Colors.white60, fontSize: 13, height: 1.5),
          ).animate().fadeIn(delay: 140.ms),
          const SizedBox(height: 24),

          // Upload options row
          Row(
            children: [
              Expanded(
                child: _buildUploadButton(
                  icon: Icons.upload_file_rounded,
                  label: 'Subir archivo',
                  sublabel: 'PDF / imagen',
                  color: AppTheme.secondaryColor,
                  onTap: _isLoading ? null : _pickAndAnalyzeCV,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildUploadButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Usar cÃ¡mara',
                  sublabel: 'Fotografiar CV',
                  color: const Color(0xFF818CF8),
                  onTap: _isLoading ? null : _openCamera,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15, end: 0),

          // Status info
          if (_selectedFileName != null && !_isLoading) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_selectedFileName!, style: GoogleFonts.lato(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)),
              ],
            ).animate().fadeIn(),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage!, style: GoogleFonts.lato(color: Colors.redAccent, fontSize: 12))),
                ],
              ),
            ).animate().fadeIn(),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.white10 : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(sublabel, style: GoogleFonts.lato(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // LOADING / EMPTY / RESULTS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppTheme.primaryColor.withValues(alpha: 0.1), AppTheme.secondaryColor.withValues(alpha: 0.1)]),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppTheme.secondaryColor, strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 24),
          Text('Analizando tu CV...', style: GoogleFonts.playfairDisplay(color: AppTheme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Nuestra IA estÃ¡ buscando los mejores matches', style: GoogleFonts.lato(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildEmptyState() {
    if (_originalText != null && _originalText!.isNotEmpty) {
      // Processed but no job matches found
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade400, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'CV procesado correctamente, pero no se encontraron matches con las vacantes actuales.',
                      style: GoogleFonts.lato(color: Colors.orange.shade700, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 20),
            Text('Contenido extraÃ­do', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Text(
                _originalText!,
                style: GoogleFonts.lato(color: Colors.grey.shade700, fontSize: 13, height: 1.7),
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
              ),
              child: Icon(Icons.work_history_outlined, size: 50, color: Colors.grey.shade300),
            ).animate().scale(delay: 100.ms, duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text('Sin resultados aÃºn', style: GoogleFonts.playfairDisplay(color: Colors.grey.shade400, fontSize: 20, fontWeight: FontWeight.bold)).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 10),
            Text(
              'Sube un PDF, una imagen de tu CV\no usa la cÃ¡mara para fotografiarlo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(color: Colors.grey.shade400, fontSize: 14, height: 1.6),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      itemCount: _results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Text('${_results.length} matches encontrados', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const Spacer(),
                Icon(Icons.auto_awesome, color: Colors.amber.shade600, size: 18),
              ],
            ),
          );
        }
        final result = _results[index - 1];
        return _buildMatchCard(result, index - 1);
      },
    );
  }

  Widget _buildMatchCard(JobMatchResult result, int index) {
    final matchColor = _getMatchColor(result.porcentajeMatch);
    final pct = result.porcentajeMatch.clamp(0, 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: matchColor.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Color top bar
            Container(height: 4, decoration: BoxDecoration(gradient: LinearGradient(colors: [matchColor, matchColor.withValues(alpha: 0.4)]))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Work icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: matchColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.business_center_rounded, color: matchColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(result.titulo, style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 2),
                            Text('Oportunidad de Carrera', style: GoogleFonts.lato(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      ),
                      // Match badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: matchColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$pct%',
                          style: GoogleFonts.playfairDisplay(color: matchColor, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(matchColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Compatibilidad con el puesto', style: GoogleFonts.lato(color: Colors.grey.shade400, fontSize: 11)),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  // Why you fit
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: Colors.amber.shade600),
                      const SizedBox(width: 8),
                      Text('Â¿Por quÃ© encajas?', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(result.razonClave, style: GoogleFonts.lato(color: Colors.grey.shade600, fontSize: 13, height: 1.5, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: matchColor.withValues(alpha: 0.08),
                        foregroundColor: matchColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Ver Vacante', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 120).ms).fadeIn().slideY(begin: 0.2, end: 0);
  }

  Color _getMatchColor(int percentage) {
    if (percentage >= 80) return Colors.green.shade500;
    if (percentage >= 50) return Colors.orange.shade500;
    return Colors.red.shade400;
  }
}
