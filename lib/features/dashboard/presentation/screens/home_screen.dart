import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:amarnamovil/features/interview/data/data_sources/gemini_api_client.dart';
import 'package:amarnamovil/features/interview/data/data_sources/whisper_api_client.dart';
import 'package:amarnamovil/data/local/database_helper.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// MODEL
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
enum _Role { ai, user, system }

class _Msg {
  final _Role role;
  final String text;
  final DateTime time;
  const _Msg(this.role, this.text, this.time);
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// WIDGET
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Services
  final GeminiChatService _chatService = GeminiChatService();
  final WhisperService _whisperService = WhisperService();
  final AudioRecorder _recorder = AudioRecorder();

  // Controllers
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // State
  final List<_Msg> _messages = [];
  bool _isLoading = false;
  bool _isRecording = false;
  bool _interviewStarted = false;
  String _selectedMode = 'Amable';

  // Limits
  int _userTurns = 0;
  static const int _maxTurns = 5;
  bool _isDone = false;
  Map<String, dynamic>? _stats;

  // CV
  String? _cvText;

  @override
  void initState() {
    super.initState();
    _loadCv();
    _textCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _recorder.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // â”€â”€ CV loading â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _loadCv() async {
    // 1. From memory
    final mem = widget.user['cv_content'] as String?;
    if (mem != null && mem.isNotEmpty) { _cvText = mem; return; }
    // 2. From DB
    try {
      final db = DatabaseHelper();
      final row = await db.getUserById(widget.user['id'] as int);
      final dbContent = row?['cv_content'] as String?;
      if (dbContent != null && dbContent.isNotEmpty) {
        _cvText = dbContent;
        widget.user['cv_content'] = dbContent;
      }
    } catch (_) {}
  }

  // â”€â”€ Interview start â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _startInterview() async {
    await _loadCv(); // refresh in case user just came back from JobMatch
    setState(() {
      _messages.clear();
      _userTurns = 0;
      _isDone = false;
      _stats = null;
      _interviewStarted = true;
    });
    // AI speaks first
    String modeInstruction = _selectedMode == 'Amable' 
        ? 'Actúa con un tono amable, empático, constructivo y comprensivo durante toda la entrevista. Ayuda al candidato a sentirse cómodo.' 
        : 'Actúa con un tono agresivo, muy estricto, exigente, intimidante y pon bajo presión al candidato. Haz preguntas muy difíciles y sé crítico.';

    final prompt = _cvText != null && _cvText!.isNotEmpty
        ? 'Analiza el CV del candidato y hazle la primera pregunta para comenzar una entrevista técnica personalizada. $modeInstruction'
        : 'Soy un candidato sin CV disponible. Hazme la primera pregunta para comenzar una entrevista técnica general de desarrollo de software. $modeInstruction';
    await _sendToAI(prompt, hidden: true);
  }

  void _resetInterview() {
    setState(() {
      _messages.clear();
      _userTurns = 0;
      _isDone = false;
      _stats = null;
      _interviewStarted = false;
    });
  }

  // â”€â”€ Message handling â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _handleSubmit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading || _isDone) return;
    _textCtrl.clear();
    setState(() {
      _messages.add(_Msg(_Role.user, trimmed, DateTime.now()));
      _userTurns++;
    });
    _scrollDown();
    final isFinal = _userTurns >= _maxTurns;
    _sendToAI(trimmed, isFinal: isFinal);
  }

  Future<void> _sendToAI(String text, {bool hidden = false, bool isFinal = false}) async {
    setState(() => _isLoading = true);
    try {
      final history = _messages
          .where((m) => m.role == _Role.user || m.role == _Role.ai)
          .map((m) => GeminiChatMessage(
                role: m.role == _Role.user ? 'user' : 'model',
                content: m.text,
              ))
          .toList();

      final response = await _chatService.getResponse(text, _cvText, history, isFinal: isFinal);

      if (isFinal) {
        // Parse the stats JSON from the final response
        try {
          final decoded = jsonDecode(response) as Map<String, dynamic>;
          setState(() {
            _stats = decoded;
            _isDone = true;
          });
          await _saveLog();
        } catch (_) {
          // If not valid JSON just show the text
          setState(() {
            _messages.add(_Msg(_Role.ai, response, DateTime.now()));
            _isDone = true;
          });
          await _saveLog();
        }
      } else {
        setState(() => _messages.add(_Msg(_Role.ai, response, DateTime.now())));
      }
    } catch (e) {
      setState(() => _messages.add(_Msg(
            _Role.system,
            'Error de conexión: ${e.toString().replaceFirst('Exception: ', '')}',
            DateTime.now(),
          )));
    } finally {
      setState(() => _isLoading = false);
      _scrollDown();
    }
  }

  // â”€â”€ Voice â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/amarna_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path == null) return;
    setState(() => _isLoading = true);
    try {
      final transcript = await _whisperService.transcribeAudio(path);
      setState(() => _isLoading = false);
      if (transcript.isNotEmpty) _handleSubmit(transcript);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(_Msg(_Role.system, 'Error de voz: $e', DateTime.now()));
      });
    }
  }

  // â”€â”€ Persistence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _saveLog() async {
    try {
      final db = DatabaseHelper();
      await db.saveInterviewLog({
        'user_id': widget.user['id'],
        'interview_date': DateTime.now().toIso8601String(),
        'messages_json': jsonEncode(_messages.map((m) => {'role': m.role.name, 'content': m.text}).toList()),
        'stats_json': jsonEncode(_stats),
      });
    } catch (_) {}
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BUILD
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isDone && _stats != null
                ? _buildStatsView()
                : _interviewStarted
                    ? _buildChatView()
                    : _buildLandingView(),
          ),
          if (_interviewStarted && !_isDone) _buildInputBar(),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // HEADER
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHeader() {
    final hasCv = _cvText != null && _cvText!.isNotEmpty;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20, bottom: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.secondaryColor.withValues(alpha: 0.15),
              border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: AppTheme.secondaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Entrenador IA', style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: hasCv ? Colors.greenAccent : Colors.orange)),
                    const SizedBox(width: 6),
                    Text(
                      hasCv ? 'CV cargado · Modo $_selectedMode' : 'Sin CV · Modo $_selectedMode',
                      style: GoogleFonts.lato(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_interviewStarted && !_isDone)
            TextButton.icon(
              onPressed: _resetInterview,
              icon: const Icon(Icons.close_rounded, size: 16),
              label: Text('Terminar', style: GoogleFonts.lato(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
            ),
          if (!_interviewStarted)
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _startInterview,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text('Iniciar', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // LANDING VIEW
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildLandingView() {
    final hasCv = _cvText != null && _cvText!.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.secondaryColor.withValues(alpha: 0.3),
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                ]),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: AppTheme.secondaryColor, size: 44),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.95, end: 1.05, duration: 2.seconds, curve: Curves.easeInOut),
            const SizedBox(height: 28),
            Text(
              'Entrenador de Entrevistas',
              style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),
            Text(
              hasCv
                  ? 'La IA analizará tu CV y te hará 5 preguntas personalizadas.\nSelecciona el modo y pulsa Iniciar.'
                  : 'No se detectó un CV. Puedes subir uno en JobMatch o comenzar en modo general.\nSelecciona el modo y pulsa Iniciar.',
              style: GoogleFonts.lato(color: Colors.white54, fontSize: 14, height: 1.6),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
            // Mode selector
            _buildModeSelector(),
            const SizedBox(height: 32),
            // Tips chip row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: const [
                _TipChip(icon: Icons.format_list_numbered, label: '5 preguntas'),
                _TipChip(icon: Icons.mic_rounded, label: 'Voz o texto'),
                _TipChip(icon: Icons.bar_chart_rounded, label: 'Estadísticas al final'),
              ],
            ).animate().fadeIn(delay: 350.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeOption('Amable', Icons.sentiment_satisfied_alt_rounded, Colors.greenAccent),
          _buildModeOption('Agresivo', Icons.local_fire_department_rounded, Colors.redAccent),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildModeOption(String mode, IconData icon, Color color) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? color : Colors.white54),
            const SizedBox(width: 8),
            Text(
              mode,
              style: GoogleFonts.lato(
                color: isSelected ? color : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // CHAT VIEW
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildChatView() {
    return Container(
      color: Colors.white,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: _messages.length + (_isLoading ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == _messages.length) return _buildTypingIndicator();
          return _buildBubble(_messages[i]);
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: const Icon(Icons.smart_toy_rounded, size: 16, color: AppTheme.primaryColor),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFE5E5EA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6, height: 6,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF8E8E93)),
              ).animate(onPlay: (c) => c.repeat())
               .scaleXY(begin: 0.8, end: 1.2, delay: (i * 200).ms, duration: 600.ms, curve: Curves.easeInOut)
               .fade(begin: 0.5, end: 1, delay: (i * 200).ms, duration: 600.ms)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_Msg msg) {
    if (msg.role == _Role.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(msg.text, style: GoogleFonts.inter(color: Colors.orange.shade800, fontSize: 12)),
        ),
      );
    }
    final isUser = msg.role == _Role.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: const Icon(Icons.smart_toy_rounded, size: 16, color: AppTheme.primaryColor),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.inter(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15, height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // INPUT BAR
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildInputBar() {
    final canSend = _textCtrl.text.trim().isNotEmpty && !_isLoading;
    final remaining = _maxTurns - _userTurns;

    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7), // iOS background
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Grabando audio... suelta para enviar',
                style: GoogleFonts.inter(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 500.ms),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textCtrl,
                          enabled: !_isLoading,
                          maxLines: 5,
                          minLines: 1,
                          style: GoogleFonts.inter(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: _isRecording
                                ? 'Escuchando...'
                                : remaining == 0
                                    ? 'Última respuesta'
                                    : 'Mensaje de texto',
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 15),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onSubmitted: _handleSubmit,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4, bottom: 4),
                        child: canSend
                          ? GestureDetector(
                              onTap: () => _handleSubmit(_textCtrl.text),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF007AFF),
                                ),
                                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                              ).animate().scale(duration: 150.ms),
                            )
                          : GestureDetector(
                              onLongPressStart: (_) => _startRecording(),
                              onLongPressEnd: (_) => _stopRecording(),
                              onLongPressCancel: () => _stopRecording(),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                color: Colors.transparent,
                                child: Icon(Icons.mic_none_rounded, color: Colors.grey.shade500, size: 26),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$remaining de $_maxTurns turnos restantes',
              style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // STATS VIEW
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildStatsView() {
    final stats = _stats!;
    final comm = (stats['comunicacion'] ?? stats['communication'] ?? 0).toDouble();
    final tech = (stats['tecnico'] ?? stats['technical'] ?? 0).toDouble();
    final feedback = stats['feedback'] ?? stats['resumen'] ?? 'Entrevista completada.';

    return Container(
      color: const Color(0xFFF1F5F9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text('¡Entrevista completada!', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)).animate().fadeIn(),
            const SizedBox(height: 8),
            Text('Aquí tienes tu informe de rendimiento', style: GoogleFonts.lato(color: Colors.grey.shade500, fontSize: 13)).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 28),
            // Score cards
            Row(
              children: [
                Expanded(child: _buildScoreCard('Comunicación', comm, AppTheme.secondaryColor)),
                const SizedBox(width: 14),
                Expanded(child: _buildScoreCard('Técnico', tech, const Color(0xFF818CF8))),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 20),
            // Feedback
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Text('Feedback de Amarna', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  ]),
                  const SizedBox(height: 12),
                  Text(feedback.toString(), style: GoogleFonts.lato(color: Colors.grey.shade700, fontSize: 13, height: 1.6)),
                ],
              ),
            ).animate().fadeIn(delay: 350.ms),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetInterview,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('Nueva entrevista', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ).animate().fadeIn(delay: 450.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(String label, double score, Color color) {
    final pct = score.clamp(0, 100) / 100;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.lato(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 12),
          Text('${score.toStringAsFixed(0)}%', style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// TIP CHIP HELPER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _TipChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TipChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.secondaryColor, size: 14),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.lato(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
