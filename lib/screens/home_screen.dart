import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../widgets/calculator_widget.dart';
import 'notes_screen.dart';
import 'clock_screen.dart';
import 'browser_screen.dart';
import 'gallery_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomeScreen({super.key, required this.cameras});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  CameraService? _cameraService;
  bool _isRecording = false;
  bool _cameraInitialized = false;
  
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;

    CameraDescription? backCamera;
    for (final camera in widget.cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        backCamera = camera;
        break;
      }
    }
    backCamera ??= widget.cameras.first;

    _cameraService = CameraService();
    final success = await _cameraService!.initialize(backCamera);

    if (mounted) {
      setState(() {
        _cameraInitialized = success;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraService == null || !_cameraInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _cameraService?.dispose();
      setState(() => _cameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  /// Appui long sur "=" : lancer/arrêter l'enregistrement
  Future<void> _toggleRecording() async {
    if (_cameraService == null) return;

    if (_isRecording) {
      await _cameraService!.stopRecording();
      setState(() {
        _isRecording = false;
      });
      // 2 vibrations = arrêté et sauvegardé
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
    } else {
      final started = await _cameraService!.startRecording();
      setState(() {
        _isRecording = started;
      });
      if (started) {
        // 1 vibration = enregistrement lancé
        await HapticFeedback.heavyImpact();
      }
    }
  }

  /// Code secret 1408 + "=" : ouvrir la galerie cachée
  void _openSecretGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GalleryScreen()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Caméra cachée (invisible)
            if (_cameraInitialized) _buildHiddenCameraPreview(),

            // Contenu principal
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  CalculatorWidget(
                    onSecretTrigger: _toggleRecording,
                    onSecretCode: _openSecretGallery,
                  ),
                  const NotesScreen(),
                  const ClockScreen(),
                  const BrowserScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      // Barre de navigation toujours visible en bas
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1C1C1E),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Calculatrice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notes),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Horloge',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: 'Web',
          ),
        ],
      ),
    );
  }

  Widget _buildHiddenCameraPreview() {
    return SizedBox(
      width: 1,
      height: 1,
      child: Opacity(
        opacity: 0.01,
        child: _cameraService != null
            ? CameraPreview(_cameraService!.controller!)
            : const SizedBox(),
      ),
    );
  }
}
