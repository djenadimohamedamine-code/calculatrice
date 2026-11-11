import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forcer le mode portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Sur Android : demander les permissions nécessaires pour caméra, micro et stockage
  if (Platform.isAndroid) {
    try {
      await [
        Permission.camera,
        Permission.microphone,
        Permission.storage,
        Permission.videos,
      ].request();
    } catch (e) {
      debugPrint('Erreur demande permissions: $e');
    }
  }

  // Recuperer les cameras disponibles
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Erreur camera: ${e.description}');
  }

  runApp(const CalculatriceApp());
}

class CalculatriceApp extends StatelessWidget {
  const CalculatriceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculatrice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        colorScheme: ColorScheme.dark(
          primary: Colors.orange,
          secondary: Colors.orangeAccent,
          surface: const Color(0xFF2C2C2E),
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(cameras: cameras),
    );
  }
}
