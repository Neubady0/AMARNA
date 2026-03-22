import 'dart:convert';
import 'package:http/http.dart' as http;

class OllamaService {
  final String _baseUrl = 'http://172.17.31.80:11434/api/chat'; // Android Emulator
  // Use localhost for iOS/Desktop: 'http://localhost:11434/api/chat';

  List<Map<String, String>> messages = [];

  // System prompt setup
  void initializeChat(String? cvText) {
    messages.clear();
    String systemContent = """
Eres Amarna, un reclutador técnico experto.
      
CONTEXTO DEL CANDIDATO (CV):
"${cvText ?? "No CV provided."}"
      
INSTRUCCIONES:
- Usa el CV anterior para hacer preguntas específicas.
- Si el CV está vacío, pregunta por su experiencia general.
- Mantén un tono profesional y levemente inquisitivo.
- NO inventes datos que no estén en el CV.
    """;
    
    messages.add({
      "role": "system",
      "content": systemContent
    });
  }

  Future<Stream<String>> streamResponse(String userMessage) async {
    // Add user message to history
    messages.add({"role": "user", "content": userMessage});

    final payload = {
      "model": "llama3", // Adjust model name as needed
      "messages": messages,
      "stream": true
    };

    final request = http.Request('POST', Uri.parse(_baseUrl));
    request.body = jsonEncode(payload);
    
    try {
      final response = await http.Client().send(request);
      
      return response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .map((line) {
            try {
               final json = jsonDecode(line);
               if (json['message'] != null && json['message']['content'] != null) {
                 return json['message']['content'] as String;
               }
               return '';
            } catch (e) {
              return ''; 
            }
          });
    } catch (e) {
      throw Exception('Failed to connect to Ollama: $e');
    }
  }

  void addToHistory(String role, String content) {
    if (role == 'assistant') {
       // Check if last message was assistant to append? 
       // For simplicity, just add. Logic might be needed to append stream result.
       messages.add({"role": role, "content": content});
    }
  }
}
