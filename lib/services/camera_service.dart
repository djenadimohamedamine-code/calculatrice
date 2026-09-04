import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraService {
  CameraController? _controller;
  bool _isRecording = false;

  CameraController? get controller => _controller;
  bool get isRecording => _isRecording;

  /// Initialise la camera
  Future<bool> initialize(CameraDescription camera) async {
    try {
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      debugPrint('Camera initialisee avec succes');
      return true;
    } catch (e) {
      debugPrint('Erreur initialisation camera: $e');
      return false;
    }
  }

  /// Demarre l'enregistrement video
  Future<bool> startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('Camera non initialisee');
      return false;
    }

    if (_isRecording) {
      debugPrint('Enregistrement deja en cours');
      return false;
    }

    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      debugPrint('Enregistrement demarre');
      return true;
    } catch (e) {
      debugPrint('Erreur demarrage enregistrement: $e');
      return false;
    }
  }

  /// Arrete l'enregistrement et retourne le chemin du fichier
  Future<String?> stopRecording() async {
    if (_controller == null || !_isRecording) {
      return null;
    }

    try {
      final XFile videoFile = await _controller!.stopVideoRecording();
      _isRecording = false;

      // Sauvegarder dans le repertoire Documents
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videoDir = path.join(appDir.path, 'calculatrice_videos');
      await Directory(videoDir).create(recursive: true);

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String savedPath = path.join(videoDir, 'VID_$timestamp.mp4');

      final File savedFile = await File(videoFile.path).copy(savedPath);
      debugPrint('Video sauvegardee: ${savedFile.path}');

      return savedFile.path;
    } catch (e) {
      debugPrint('Erreur arret enregistrement: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Libere les ressources de la camera
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isRecording = false;
  }
}
