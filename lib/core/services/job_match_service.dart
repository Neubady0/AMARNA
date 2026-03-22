import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class JobMatchResult {
  final String vacanteId;
  final String titulo;
  final int porcentajeMatch;
  final String razonClave;

  JobMatchResult({
    required this.vacanteId,
    required this.titulo,
    required this.porcentajeMatch,
    required this.razonClave,
  });

  factory JobMatchResult.fromJson(Map<String, dynamic> json) {
    return JobMatchResult(
      vacanteId: json['vacante_id'] ?? '',
      titulo: json['titulo'] ?? '',
      porcentajeMatch: json['porcentaje_match'] ?? 0,
      razonClave: json['razon_clave'] ?? '',
    );
  }
}

class JobMatchResponse {
  final List<JobMatchResult> results;
  final String originalText;

  JobMatchResponse({required this.results, required this.originalText});

  factory JobMatchResponse.fromJson(Map<String, dynamic> json) {
    var list = json['results'] as List;
    return JobMatchResponse(
      results: list.map((i) => JobMatchResult.fromJson(i)).toList(),
      originalText: json['original_text'] ?? '',
    );
  }
}

class JobMatchService {
  // Use 172.17.31.80 for Android Emulator, localhost for others (iOS/Simulator/Web)
  // Assuming default FastAPI port 8000
  final String _baseUrl = 'http://172.17.31.80:8001/analizar-cv';

  Future<JobMatchResponse> analyzeCV(String filePath) async {
    var uri = Uri.parse(_baseUrl);
    var request = http.MultipartRequest('POST', uri);

    File file = File(filePath);
    if (!file.existsSync()) {
      throw Exception("Archivo no encontrado en $filePath");
    }

    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return JobMatchResponse.fromJson(jsonResponse);
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? "Error del servidor: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error al analizar CV: $e");
    }
  }
}
