import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../widgets/calculator_widget.dart';
import 'notes_screen.dart';
import 'clock_screen.dart';
import 'browser_screen.dart';

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
  
  final List<Widget> _screens = [
    const CalculatorWidget(),
    const NotesScreen(),
    const ClockScreen(),
    const BrowserScreen(),
  ];

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

  Future<void> _toggleRecording() async {
    if (_cameraService == null) return;

    if (_isRecording) {
      await _cameraService!.stopRecording();
      setState(() {
        _isRecording = false;
      });
      // Plus aucun pop-up visuel pour une discrétion totale
    } else {
      final started = await _cameraService!.startRecording();
      setState(() {
        _isRecording = started;
      });
      // Idem, pas de rouge ni d'alerte
    }
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
      body: SafeArea(
        child: Column(
          children: [
            // === Barre de contrôle vidéo discrète (MIMO) ===
            _buildVideoControlBar(),

            // === Caméra cachée (1 pixel, invisible) ===
            if (_cameraInitialized) _buildHiddenCameraPreview(),

            // === Contenu principal dynamique ===
            Expanded(
              // IndexedStack permet de garder les écrans en mémoire quand on change d'onglet
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildVideoControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: const Color(0xFF1C1C1E),
      child: Row(
        children: [
          // Bouton discret "Mimo" pour lancer/arrêter l'enregistrement
          GestureDetector(
            onTap: _cameraInitialized ? _toggleRecording : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                'MIMO',
                style: TextStyle(
                  // Un léger changement de couleur pour savoir que ça tourne
                  // (Passe de gris foncé à blanc cassé, indétectable pour les autres)
                  color: _isRecording ? Colors.white70 : Colors.grey.shade700,
                  fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 2.0,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHiddenCameraPreview() {
    // On cache complètement la caméra dans un espace de 1 pixel invisible.
    // L'opacité à 0.01 assure que Flutter continue de rendre le flux vidéo
    // et que le buffer ne s'arrête pas, sans rien afficher à l'utilisateur.
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
