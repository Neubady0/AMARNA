import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class JobMatchResult {
  final String vacanteId;
  final String titulo;
  final int porcentajeMatch;
  final String razonClave;
  final List<String> gaps;
  final List<Map<String, String>> improvementPlan;

  JobMatchResult({
    required this.vacanteId,
    required this.titulo,
    required this.porcentajeMatch,
    required this.razonClave,
    required this.gaps,
    required this.improvementPlan,
  });

  factory JobMatchResult.fromJson(Map<String, dynamic> json) {
    // Mock data for gaps
    List<String> defaultGaps = [
      "Experiencia previa en roles similares (recomendado >2 años).",
      "Conocimientos avanzados en arquitecturas escalables.",
      "Manejo avanzado de herramientas de CI/CD.",
    ];

    // Mock data for improvement plan
    List<Map<String, String>> defaultPlan = [
      {
        "day": "Día 1-2",
        "title": "Arquitectura y Patrones",
        "description": "Repasa patrones de diseño fundamentales y arquitectura hexagonal o Clean Architecture para proyectos grandes."
      },
      {
        "day": "Día 3-4",
        "title": "Integración Continua",
        "description": "Configura un pipeline de CI/CD básico (por ejemplo con GitHub Actions) para automatizar tests y build."
      },
      {
        "day": "Día 5-7",
        "title": "Proyecto Práctico y Portfolio",
        "description": "Desarrolla una pequeña prueba de concepto (PoC) aplicando lo aprendido y añádela a tu repositorio de GitHub."
      }
    ];

    return JobMatchResult(
      vacanteId: json['vacante_id'] ?? '',
      titulo: json['titulo'] ?? '',
      porcentajeMatch: json['porcentaje_match'] ?? 0,
      razonClave: json['razon_clave'] ?? '',
      gaps: json['gaps'] != null ? List<String>.from(json['gaps']) : defaultGaps,
      improvementPlan: json['improvement_plan'] != null 
          ? List<Map<String, String>>.from(json['improvement_plan'].map((x) => Map<String, String>.from(x))) 
          : defaultPlan,
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
  // Usar la IP WiFi del PC para dispositivos físicos Android
  // Wi-Fi: 172.23.30.47  |  Ethernet: 172.17.31.80
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
