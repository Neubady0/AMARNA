import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiChatMessage {
  final String role;
  final String content;

  GeminiChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {
    'role': role,
    'content': content,
  };
}

class GeminiChatService {
  // Use 172.17.31.80 for Android Emulator, localhost for others
  final String _baseUrl = 'http://172.17.31.80:8000/chat';

  Future<String> getResponse(String message, String? context, List<GeminiChatMessage> history) async {
    final url = Uri.parse(_baseUrl);
    
    final body = jsonEncode({
      'message': message,
      'context': context ?? '',
      'history': history.map((m) => m.toJson()).toList(),
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] as String;
      } else {
        throw Exception("Error del servidor (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      throw Exception("Error al conectar con el Chatbot: $e");
    }
  }
}
