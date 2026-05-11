import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerScreen extends StatelessWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visor de CV'),
      ),
      body: PDFView(
        filePath: filePath,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: false,
        onError: (error) {
          debugPrint(error.toString());
          // Opcional: mostrar un mensaje al usuario
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar el PDF: $error')),
          );
        },
      ),
    );
  }
}
