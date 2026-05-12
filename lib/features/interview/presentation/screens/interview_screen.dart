import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:amarnamovil/features/interview/data/data_sources/gemini_api_client.dart';
import 'package:amarnamovil/features/interview/data/data_sources/whisper_api_client.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class InterviewScreen extends StatefulWidget {
  final String? cvContext;

  const InterviewScreen({super.key, this.cvContext});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  // Services
  final GeminiChatService _geminiChatService = GeminiChatService();
  final WhisperService _whisperService = WhisperService();
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Controllers
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isRecording = false;
  String? _cvText;

  @override
  void initState() {
    super.initState();
    _cvText = widget.cvContext;
    _initializeInterview();
  }

  void _initializeInterview() {
    if (_cvText != null) {
      _sendMessageToAI("Analiza mi CV y hazme la primera pregunta para empezar la entrevista técnica.", hidden: true);
    } else {
      _sendMessageToAI("Soy un candidato sin CV a mano. Hazme una entrevista técnica general sobre desarrollo de software.", hidden: true);
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    
    _textController.clear();
    
    setState(() {
      _messages.add({
        "role": "user",
        "content": text.trim(),
        "timestamp": DateTime.now(),
      });
    });
    _scrollToBottom();

    _sendMessageToAI(text);
  }

  Future<void> _sendMessageToAI(String text, {bool hidden = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Build history for Gemini
      List<GeminiChatMessage> history = _messages
          .where((m) => m["role"] == "user" || m["role"] == "assistant")
          .map((m) => GeminiChatMessage(
                role: m["role"] == "user" ? "user" : "model",
                content: m["content"],
              ))
          .toList();

      final response = await _geminiChatService.getResponse(text, _cvText, history);

      setState(() {
        _messages.add({
          "role": "assistant",
          "content": response,
          "timestamp": DateTime.now(),
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "system",
          "content": "Error de conexión con Amarna: ${e.toString().replaceFirst('Exception: ', '')}",
          "timestamp": DateTime.now(),
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/recording.m4a';
      
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
    });

    if (path != null) {
      setState(() => _isLoading = true); 
      try {
        final text = await _whisperService.transcribeAudio(path);
        setState(() => _isLoading = false);
        
        if (text.isNotEmpty) {
          _handleSubmitted(text);
        }
      } catch (e) {
        setState(() {
           _isLoading = false;
           _messages.add({"role": "system", "content": "Error de voz: $e"});
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          children: [
            Text("Entrevista con Amarna", style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 18)),
            if (_isLoading)
               Text("Amarna está pensando...", style: GoogleFonts.lato(fontSize: 12, color: AppTheme.secondaryColor))
            else 
               Text("En línea", style: GoogleFonts.lato(fontSize: 12, color: Colors.green)),
          ],
        ),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (_isLoading)
             Padding(
               padding: const EdgeInsets.all(12.0),
               child: Row(
                 children: [
                   const CircleAvatar(radius: 12, backgroundColor: AppTheme.primaryColor, child: Icon(Icons.smart_toy, size: 14, color: Colors.white)),
                   const SizedBox(width: 8),
                   const Text("Amarna escribiendo...", style: TextStyle(color: Colors.grey, fontSize: 12)).animate().fade(duration: 500.ms, curve: Curves.easeInOut),
                 ],
               ),
             ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    bool isUser = msg['role'] == 'user';
    bool isSystem = msg['role'] == 'system';
    
    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
          child: Text(msg['content'], style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          msg['content'],
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            height: 1.4,
            fontSize: 15,
          ),
        ),
      ),
    ).animate().fade().slideY(begin: 0.2, end: 0, duration: 200.ms);
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
           BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: "Escribe un mensaje...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _handleSubmitted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            onLongPressCancel: () => _stopRecording(),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: _isRecording ? Colors.red : AppTheme.primaryColor,
              child: const Icon(Icons.mic, color: Colors.white),
            ).animate(target: _isRecording ? 1 : 0)
             .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 200.ms)
             .then(delay: 100.ms).shake(hz: 4, curve: Curves.easeInOut),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: AppTheme.primaryColor),
            onPressed: _textController.text.trim().isNotEmpty ? () => _handleSubmitted(_textController.text) : null,
          ),
        ],
      ),
    );
  }
}
