import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import '../services/camera_service.dart';
import 'video_player_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<FileSystemEntity> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      final dirs = await CameraService.getVideoDirectories();
      final Map<String, FileSystemEntity> videoMap = {};

      for (final dir in dirs) {
        if (await dir.exists()) {
          final files = dir
              .listSync()
              .where((f) => f.path.endsWith('.mp4'))
              .toList();
          for (final f in files) {
            final fileName = path.basename(f.path);
            if (!videoMap.containsKey(fileName)) {
              videoMap[fileName] = f;
            }
          }
        }
      }

      final files = videoMap.values.toList();
      // Trier par date (plus récent en premier)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      setState(() {
        _videos = files;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _deleteVideo(int index) async {
    final fileName = path.basename(_videos[index].path);
    try {
      // 1. Supprimer le fichier référencé
      final file = File(_videos[index].path);
      if (await file.exists()) {
        await file.delete();
      }

      // 2. Supprimer aussi les copies dans d'autres répertoires s'ils existent
      final dirs = await CameraService.getVideoDirectories();
      for (final dir in dirs) {
        final otherFile = File(path.join(dir.path, fileName));
        if (await otherFile.exists()) {
          try {
            await otherFile.delete();
            if (Platform.isAndroid) {
              const platform = MethodChannel('com.mimo.calculatrice/media');
              await platform.invokeMethod('scanFile', {'path': otherFile.path});
            }
          } catch (_) {}
        }
      }

      setState(() {
        _videos.removeAt(index);
      });
    } catch (e) {
      debugPrint('Erreur suppression: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text('Fichiers & Galerie', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: _loadVideos,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _videos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucune vidéo',
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _videos.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final file = File(_videos[index].path);
                    final stat = file.statSync();
                    final fileName = path.basename(file.path);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(videoPath: file.path),
                            ),
                          );
                        },
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.play_circle_fill, color: Colors.orange, size: 32),
                        ),
                        title: Text(
                          fileName,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${_formatDate(stat.modified)}  •  ${_formatSize(stat.size)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.orange),
                              tooltip: 'Partager',
                              onPressed: () {
                                Share.shareXFiles(
                                  [XFile(file.path)],
                                  text: fileName,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF2C2C2E),
                                    title: const Text('Supprimer ?', style: TextStyle(color: Colors.white)),
                                    content: const Text(
                                      'Cette vidéo sera supprimée définitivement (de l\'application et de la galerie).',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _deleteVideo(index);
                                        },
                                        child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
