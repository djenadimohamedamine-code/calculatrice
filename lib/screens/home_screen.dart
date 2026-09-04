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
      final path = await _cameraService!.stopRecording();
      setState(() {
        _isRecording = false;
      });
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vidéo sauvegardée !'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      final started = await _cameraService!.startRecording();
      setState(() {
        _isRecording = started;
      });
      if (mounted && started) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enregistrement en cours...'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
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
            // === Barre de contrôle vidéo ===
            _buildVideoControlBar(),

            // === Aperçu caméra (miniature) ===
            if (_cameraInitialized) _buildCameraPreview(),

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (_isRecording)
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            _isRecording ? 'REC' : 'Prêt',
            style: TextStyle(
              color: _isRecording ? Colors.red : Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _cameraInitialized ? _toggleRecording : null,
            icon: Icon(
              _isRecording ? Icons.stop : Icons.videocam,
              size: 20,
            ),
            label: Text(_isRecording ? 'Arrêter' : 'Filmer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRecording ? Colors.red.shade700 : Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      height: 80,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isRecording ? Colors.red : Colors.grey.shade700,
          width: _isRecording ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: _cameraService != null
            ? CameraPreview(_cameraService!.controller!)
            : const Center(
                child: Text('Caméra non disponible', style: TextStyle(color: Colors.grey)),
              ),
      ),
    );
  }
}
