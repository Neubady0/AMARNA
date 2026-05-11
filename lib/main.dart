import 'package:flutter/material.dart';
import 'package:amarnamovil/data/local/database_helper.dart';
import 'package:amarnamovil/features/auth/presentation/screens/login_screen.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:amarnamovil/features/auth/data/data_sources/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _insertInitialData(); // Insertar datos iniciales antes de ejecutar la app
  runApp(const AmarnaApp());
}

// FunciÃ³n para insertar ofertas de empleo iniciales si la base de datos estÃ¡ vacÃ­a
Future<void> _insertInitialData() async {
  final dbHelper = DatabaseHelper();
  final offers = await dbHelper.getAllJobOffers();

  if (offers.isEmpty) {
    await dbHelper.saveJobOffer({
      'title': 'Desarrollador Flutter Junior',
      'description': 'Buscamos un desarrollador Flutter junior apasionado por crear apps mÃ³viles y de escritorio. Experiencia con Dart y Flutter deseable.',
      'requirements': 'Conocimientos de Dart y Flutter, Git, Firebase. Ganas de aprender y trabajar en equipo.',
      'location': 'Remoto',
    });
    await dbHelper.saveJobOffer({
      'title': 'DiseÃ±ador UX/UI',
      'description': 'Necesitamos un diseÃ±ador UX/UI creativo para mejorar la experiencia de usuario de nuestras aplicaciones. Portfolio imprescindible.',
      'requirements': 'Figma, Sketch, Adobe XD. Experiencia en diseÃ±o de interfaces mÃ³viles y web. Conocimientos de usabilidad.',
      'location': 'Barcelona',
    });
    await dbHelper.saveJobOffer({
      'title': 'Especialista en IA y Machine Learning',
      'description': 'Puesto para experto en IA que nos ayude a desarrollar los mÃ³dulos de evaluaciÃ³n de entrevistas. Experiencia con Python y frameworks de ML.',
      'requirements': 'Python, TensorFlow, PyTorch. Experiencia en procesamiento de lenguaje natural y visiÃ³n por computador.',
      'location': 'Madrid',
    });
    debugPrint("Ofertas de empleo iniciales insertadas.");
  } else {
    debugPrint("La base de datos ya contiene ofertas de empleo.");
  }
}

class AmarnaApp extends StatelessWidget {
  const AmarnaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Amarna',
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    );
  }
}
