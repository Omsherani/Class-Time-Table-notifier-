import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:class_alarm/services/ocr_service.dart';
import 'package:class_alarm/services/timetable_parser.dart';


class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final OCRService _ocrService = OCRService();
  final TimetableParser _parser = TimetableParser();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _processImage(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final text = await _ocrService.recognizeText(image.path);
      if (text.trim().isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMessage = "We couldn't detect any text from this image. Try uploading a clearer screenshot.";
        });
        return;
      }

      final classes = _parser.parse(text);
      if (classes.isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMessage = "We couldn't identify class times from this image. Try uploading a clearer timetable screenshot.";
        });
        return;
      }

      setState(() => _isProcessing = false);

      if (mounted) {
        Navigator.pushNamed(context, '/verify', arguments: classes);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'OCR processing failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Timetable'),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Processing image...',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Running OCR to detect classes',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Icon(
                    Icons.school_outlined,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to Class Alarm',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Import your timetable to automatically\nset alarms for every class.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),

                  if (_errorMessage != null) ...[
                    Card(
                      color: colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: colorScheme.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: colorScheme.onErrorContainer),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Upload from gallery
                  _actionCard(
                    context,
                    icon: Icons.photo_library_outlined,
                    title: 'Upload Timetable Screenshot',
                    subtitle: 'Select from your photo gallery',
                    onTap: () => _processImage(ImageSource.gallery),
                  ),
                  const SizedBox(height: 12),

                  // Camera
                  _actionCard(
                    context,
                    icon: Icons.camera_alt_outlined,
                    title: 'Take Timetable Photo',
                    subtitle: 'Capture your timetable with camera',
                    onTap: () => _processImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 12),

                  // Manual entry
                  _actionCard(
                    context,
                    icon: Icons.edit_note_outlined,
                    title: 'Enter Class Manually',
                    subtitle: 'Add classes one by one',
                    onTap: () => Navigator.pushNamed(context, '/add_edit_class'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
