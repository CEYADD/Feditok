import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../../providers/feed_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitializing = true;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(_cameras![0], ResolutionPreset.high);
        await _controller!.initialize();
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isRecording) {
      final file = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      _openUploadDetailsModal(file.path);
    } else {
      await _controller!.startVideoRecording();
      setState(() => _isRecording = true);
    }
  }

  void _openUploadDetailsModal(String mediaPath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UploadDetailsModal(mediaPath: mediaPath),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Fotocamera Integrata'),
        backgroundColor: Colors.black,
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _controller != null && _controller!.value.isInitialized
              ? Stack(
                  children: [
                    Center(child: CameraPreview(_controller!)),
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Semantics(
                          button: true,
                          label: _isRecording ? 'Interrompi registrazione video' : 'Avvia registrazione video',
                          hint: 'Tocca due volte per registrare',
                          child: InkWell(
                            onTap: _toggleRecord,
                            customBorder: const CircleBorder(),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: _isRecording ? Colors.red : Colors.white,
                              child: Icon(
                                _isRecording ? Icons.stop : Icons.videocam,
                                color: _isRecording ? Colors.white : Colors.black,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Text(
                    'Fotocamera non disponibile su questo dispositivo.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
    );
  }
}

class UploadDetailsModal extends StatefulWidget {
  final String mediaPath;

  const UploadDetailsModal({super.key, required this.mediaPath});

  @override
  State<UploadDetailsModal> createState() => _UploadDetailsModalState();
}

class _UploadDetailsModalState extends State<UploadDetailsModal> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _taggedUsernames = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim().replaceAll('@', '');
    if (tag.isNotEmpty && !_taggedUsernames.contains(tag)) {
      setState(() {
        _taggedUsernames.add(tag);
        _tagController.clear();
      });
    }
  }

  void _submitUpload() {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un titolo per il contenuto.')),
      );
      return;
    }

    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    feedProvider.saveVideoLocally(widget.mediaPath, title);

    Navigator.pop(context); // Chiude il modal
    if (Navigator.canPop(context)) Navigator.pop(context); // Chiude eventuale fotocamera

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Caricato con successo! Titolo: "$title"${desc.isNotEmpty ? " ($desc)" : ""}, Tag: ${_taggedUsernames.join(", ")}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Dettagli Caricamento',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Titolo *',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Descrizione',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      labelText: 'Tagga una persona (@username)',
                      prefixIcon: const Icon(Icons.person_add_alt),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.purpleAccent, size: 32),
                  onPressed: _addTag,
                ),
              ],
            ),
            if (_taggedUsernames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _taggedUsernames
                    .map(
                      (tag) => Chip(
                        label: Text('@$tag'),
                        onDeleted: () {
                          setState(() => _taggedUsernames.remove(tag));
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitUpload,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Pubblica contenuto'),
            ),
          ],
        ),
      ),
    );
  }
}
