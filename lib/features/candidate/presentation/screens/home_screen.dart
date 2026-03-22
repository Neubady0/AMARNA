import 'package:flutter/material.dart';
import 'package:amarnamovil/features/candidate/presentation/screens/profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async'; // For timer
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:amarnamovil/features/candidate/presentation/screens/interview_screen.dart';
import 'package:amarnamovil/core/services/gemini_chat_service.dart';
import 'package:amarnamovil/core/services/whisper_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:amarnamovil/data/local/database_helper.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; // {role: 'ai'|'user', text: String}
  final GeminiChatService _geminiChatService = GeminiChatService();
  final WhisperService _whisperService = WhisperService();
  final AudioRecorder _recorder = AudioRecorder();
  
  bool _isLoading = false;
  bool _isRecording = false;
  
  // Interview State
  bool _isInterviewActive = false;
  bool _isAiSpeaking = false;
  
  // Camera State
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  String? _persistentCvContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStoredCv();
  }

  Future<void> _loadStoredCv() async {
    try {
      final dbHelper = DatabaseHelper();
      final user = await dbHelper.getUserById(widget.user['id']);
      if (user != null && user['cv_content'] != null && user['cv_content'].toString().isNotEmpty) {
        setState(() {
          _persistentCvContext = user['cv_content'];
        });
        debugPrint("CV de persistencia cargado para el contexto de la IA.");
      }
    } catch (e) {
      debugPrint("Error al cargar CV de persistencia: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _messageController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Release camera resource when app is in background
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed && _isInterviewActive) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        final cameras = await availableCameras();
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false, // We handle audio separately ideally, or just preview video
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } catch (e) {
        debugPrint('Error initializing camera: $e');
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al acceder a la cámara')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se requieren permisos de cámara para la entrevista')),
        );
      }
    }
  }

  void _startInterview() async {
    final String? cvPath = widget.user['cv_path'];
    final bool hasCV = cvPath != null && cvPath.isNotEmpty; // Simplistic check

    if (hasCV) {
      try {
        // Case B: Existing CV
        // Only works if file exists locally. If remote URL, need http get.
        // Assuming local path for now based on context.
        if (File(cvPath).existsSync()) {
            String text = await ReadPdfText.getPDFtext(cvPath);
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InterviewScreen(cvContext: text)),
              );
            }
        } else {
           _showInterviewSetupDialog(); // File not found, fallback
        }
      } catch (e) {
        debugPrint("Error reading existing CV: $e");
        _showInterviewSetupDialog();
      }
    } else {
      // Case A: No CV
      _showInterviewSetupDialog();
    }
  }

  void _showInterviewSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Personaliza tu entrevista', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        content: const Text(
          "¿Quieres subir tu CV ahora para que la IA te haga preguntas específicas, o prefieres una entrevista general?",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // "Modo General"
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InterviewScreen(cvContext: null)),
              );
            },
            child: const Text('Modo General', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // "Subir PDF"
              await _pickAndStartInterview();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Subir PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndStartInterview() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        String path = result.files.single.path!;
        String text = await ReadPdfText.getPDFtext(path);
        
        if (mounted) {
           Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => InterviewScreen(cvContext: text))
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _endInterview() {
    setState(() {
      _isInterviewActive = false;
      _isCameraInitialized = false;
    });
    _cameraController?.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _messageController.clear();
      _isLoading = true;
    });

    try {
      // Build history for the backend
      List<GeminiChatMessage> history = _messages
          .where((m) => m['role'] == 'ai' || m['role'] == 'user')
          .map((m) => GeminiChatMessage(
                role: m['role'] == 'user' ? 'user' : 'model',
                content: m['text'],
              ))
          .toList();

      final response = await _geminiChatService.getResponse(text, _persistentCvContext, history);

      if (mounted) {
        setState(() {
          _isAiSpeaking = true;
          _messages.add({
            'role': 'ai',
            'text': response,
          });
          _isLoading = false;
        });
        
        // Stop visualizer after a few seconds
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _isAiSpeaking = false);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add({
            'role': 'ai',
            'text': 'Error Amarna: ${e.toString().replaceFirst('Exception: ', '')}',
          });
        });
      }
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _recorder.stop();
        setState(() {
          _isRecording = false;
        });

        if (path != null) {
          setState(() => _isLoading = true);
          final text = await _whisperService.transcribeAudio(path);
          setState(() {
            _messageController.text = text;
            _isLoading = false;
          });
        }
      } else {
        // Request Permissions
        if (await _recorder.hasPermission()) {
          // Automatic camera activation if not active
          if (!_isInterviewActive) {
            _startInterview();
          }

          final directory = await getTemporaryDirectory();
          final path = '${directory.path}/recording.m4a';
          
          const config = RecordConfig(); // Default config
          await _recorder.start(config, path: path);
          
          setState(() {
            _isRecording = true;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permiso de micrófono denegado')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error in recording: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Amarna',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          if (!_isInterviewActive)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen(user: widget.user)),
                  );
                },
                child: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    widget.user['name'] != null ? widget.user['name'][0].toUpperCase() : 'U',
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Secondary header for Interview control
              if (!_isInterviewActive)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: _startInterview,
                      icon: const Icon(Icons.play_arrow_rounded, size: 24),
                      label: const Text("PREPARAR ENTREVISTA"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: AppTheme.secondaryColor.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    border: Border(bottom: BorderSide(color: Colors.red.withValues(alpha: 0.1))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.circle, size: 10, color: Colors.red).animate(onPlay: (loop) => loop.repeat()).fadeIn(duration: 500.ms).fadeOut(delay: 500.ms),
                      const SizedBox(width: 8),
                      Text("ENTREVISTA EN CURSO - GRABANDO", 
                        style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _endInterview,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text("TERMINAR", style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              
              // Chat Area
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 100),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isAi = msg['role'] == 'ai';
                          final isLast = index == _messages.length - 1;

                          return Column(
                            crossAxisAlignment: isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                            children: [
                              Align(
                                alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(16),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                  decoration: BoxDecoration(
                                    color: isAi ? Colors.white : AppTheme.primaryColor,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: isAi ? Radius.zero : const Radius.circular(20),
                                      bottomRight: isAi ? const Radius.circular(20) : Radius.zero,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    msg['text'],
                                    style: TextStyle(
                                      color: isAi ? Colors.black87 : Colors.white,
                                      fontSize: 16,
                                      height: 1.5,
                                      fontWeight: isAi ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                              if (isAi && isLast && _isAiSpeaking)
                                 Padding(
                                   padding: const EdgeInsets.only(left: 8.0, bottom: 16),
                                   child: Row(
                                     children: [
                                       _buildAudioVisualizerBar(1),
                                       const SizedBox(width: 4),
                                       _buildAudioVisualizerBar(2),
                                       const SizedBox(width: 4),
                                       _buildAudioVisualizerBar(3),
                                     ],
                                   ),
                                 ),
                              
                              if (isLast && _isLoading)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text("IA escribiendo...", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic)).animate().fade(),
                                ),
                            ],
                          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
                        },
                      ),
              ),
              
              // Input Area
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: "Escribe tu respuesta...",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: _isRecording 
                            ? Colors.red.withValues(alpha: 0.2) 
                            : AppTheme.secondaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: _isRecording ? Border.all(color: Colors.red, width: 2) : null,
                      ),
                      child: IconButton(
                        onPressed: _toggleRecording,
                        icon: Icon(
                          _isRecording ? Icons.mic : Icons.mic_rounded, 
                          color: _isRecording ? Colors.red : AppTheme.primaryColor
                        ),
                        tooltip: _isRecording ? 'Detener y transcribir' : 'Grabar respuesta',
                      ),
                    ).animate(target: _isRecording ? 1 : 0)
                     .scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2), duration: 1.seconds, curve: Curves.easeInOut)
                     .then()
                     .scale(begin: const Offset(1.2, 1.2), end: const Offset(1,1), duration: 1.seconds),
                    
                    const SizedBox(width: 8),

                    IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send_rounded, color: AppTheme.primaryColor),
                      tooltip: 'Enviar',
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Active Mode: Video Overlay (Camera)
          if (_isInterviewActive && _isCameraInitialized && _cameraController != null)
            Positioned(
              top: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10),
                    ],
                  ),
                  child: Stack(
                    children: [
                       CameraPreview(_cameraController!),
                       Positioned(
                         bottom: 8,
                         right: 8,
                         child: Container(
                           width: 12,
                           height: 12,
                           decoration: const BoxDecoration(
                             color: Colors.red,
                             shape: BoxShape.circle,
                           ),
                         ).animate(onPlay: (loop) => loop.repeat()).fadeIn().fadeOut(delay: 500.ms),
                       )
                    ],
                  ),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.1,
            child: Image.asset(
              'assets/icon/app_icon.png', // Assuming this exists, fallback to icon if not
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.psychology, size: 100, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Hola, soy tu entrenador de entrevistas.",
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ).animate().fadeIn().moveY(begin: 10, end: 0),
          const SizedBox(height: 8),
          Text(
            "Sube tu CV para personalizar la sesión\no empieza una práctica general.",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
  
  Widget _buildAudioVisualizerBar(int index) {
     return Container(
       width: 4,
       height: 20,
       decoration: BoxDecoration(
         color: AppTheme.secondaryColor,
         borderRadius: BorderRadius.circular(2),
       ),
     ).animate(onPlay: (loop) => loop.repeat(reverse: true))
      .scaleY(begin: 0.5, end: 1.5, duration: Duration(milliseconds: 300 * index), curve: Curves.easeInOut);
  }
}
