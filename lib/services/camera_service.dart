import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraService {
  CameraController? _controller;
  bool _isRecording = false;

  CameraController? get controller => _controller;
  bool get isRecording => _isRecording;

  /// Obtient les dossiers de stockage des vidéos selon la plateforme
  static Future<List<Directory>> getVideoDirectories() async {
    final List<Directory> dirs = [];

    // Sur Android : inclure DCIM/Calculatrice (Galerie Android) et Movies/Calculatrice
    if (Platform.isAndroid) {
      try {
        final dcim = Directory('/storage/emulated/0/DCIM/Calculatrice');
        if (!await dcim.exists()) await dcim.create(recursive: true);
        dirs.add(dcim);
      } catch (_) {}

      try {
        final movies = Directory('/storage/emulated/0/Movies/Calculatrice');
        if (!await movies.exists()) await movies.create(recursive: true);
        dirs.add(movies);
      } catch (_) {}
    }

    // Documents internes de l'application (iOS et secours Android)
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final internalDir = Directory(path.join(appDir.path, 'calculatrice_videos'));
      if (!await internalDir.exists()) await internalDir.create(recursive: true);
      dirs.add(internalDir);
    } catch (_) {}

    return dirs;
  }

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

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String savedResultPath = '';

      // Sur Android uniquement : copier directement dans DCIM/Calculatrice pour la Galerie
      if (Platform.isAndroid) {
        try {
          final dcimDir = Directory('/storage/emulated/0/DCIM/Calculatrice');
          if (!await dcimDir.exists()) {
            await dcimDir.create(recursive: true);
          }
          final String galleryPath = path.join(dcimDir.path, 'VID_$timestamp.mp4');
          final File galleryFile = await File(videoFile.path).copy(galleryPath);
          savedResultPath = galleryFile.path;
          debugPrint('Video enregistree dans Galerie DCIM: $galleryPath');

          // Notifier immédiatement le MediaScanner Android pour affichage instantané dans la Galerie
          try {
            const platform = MethodChannel('com.mimo.calculatrice/media');
            await platform.invokeMethod('scanFile', {'path': galleryPath});
          } catch (e) {
            debugPrint('Erreur scanFile MediaScanner: $e');
          }
        } catch (e) {
          debugPrint('Erreur sauvegarde DCIM: $e');
        }

        // Sauvegarder aussi une copie dans Movies/Calculatrice
        try {
          final moviesDir = Directory('/storage/emulated/0/Movies/Calculatrice');
          if (!await moviesDir.exists()) {
            await moviesDir.create(recursive: true);
          }
          final String moviesPath = path.join(moviesDir.path, 'VID_$timestamp.mp4');
          await File(videoFile.path).copy(moviesPath);
        } catch (_) {}
      }

      // Sauvegarde dans Documents (standard iOS et secours)
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videoDir = path.join(appDir.path, 'calculatrice_videos');
      await Directory(videoDir).create(recursive: true);

      final String internalSavedPath = path.join(videoDir, 'VID_$timestamp.mp4');
      final File savedFile = await File(videoFile.path).copy(internalSavedPath);
      debugPrint('Video sauvegardee: ${savedFile.path}');

      if (savedResultPath.isEmpty) {
        savedResultPath = savedFile.path;
      }

      return savedResultPath;
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
