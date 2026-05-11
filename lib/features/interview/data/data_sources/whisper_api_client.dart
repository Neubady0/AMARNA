import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// Transcripción de voz a texto usando el modelo Gemini de Google
/// a través del backend FastAPI en el puerto 8001.
class WhisperService {
  // Mismo backend que el resto de servicios – ya no necesitamos el servidor Whisper en 5000
  final String _baseUrl = 'http://172.17.31.80:8001/transcribir-audio';

  Future<String> transcribeAudio(String audioPath) async {
    final audioFile = File(audioPath);
    if (!audioFile.existsSync()) {
      throw Exception('Archivo de audio no encontrado en $audioPath');
    }

    var uri = Uri.parse(_baseUrl);
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', audioPath));

    try {
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Tiempo de espera agotado al transcribir'),
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final text = json['text'] as String? ?? '';
        if (text.isEmpty) throw Exception('Gemini no devolvió texto');
        return text;
      } else {
        final detail = jsonDecode(response.body)['detail'] ?? response.body;
        throw Exception('Error del servidor (${response.statusCode}): $detail');
      }
    } catch (e) {
      throw Exception('Transcripción fallida: $e');
    }
  }
}
