import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class WhisperService {
  // Use 172.17.31.80 for Android Emulator, localhost for others
  final String _baseUrl = 'http://172.17.31.80:5000/transcribe'; 
  
  Future<String> transcribeAudio(String audioPath) async {
    var uri = Uri.parse(_baseUrl);
    var request = http.MultipartRequest('POST', uri);
    
    if (File(audioPath).existsSync()) {
      request.files.add(await http.MultipartFile.fromPath('file', audioPath));
    } else {
      throw Exception("Audio file not found at $audioPath");
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('text')) {
          return jsonResponse['text'];
        } else {
           throw Exception("Backend returned no text");
        }
      } else {
        throw Exception("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Transcribe failed: $e");
    }
  }
}
