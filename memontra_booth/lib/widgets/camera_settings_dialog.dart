import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import '../theme/app_theme.dart';

class CameraSettingsDialog extends StatefulWidget {
  final CameraDescription? currentCamera;
  final ValueChanged<CameraDescription>? onCameraChanged;

  const CameraSettingsDialog({
    super.key,
    this.currentCamera,
    this.onCameraChanged,
  });

  @override
  State<CameraSettingsDialog> createState() => _CameraSettingsDialogState();
}

class _CameraSettingsDialogState extends State<CameraSettingsDialog> {
  List<CameraDescription> _cameras = [];
  CameraDescription? _selectedCamera;
  CameraController? _previewController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    setState(() => _isLoading = true);
    final cameras = await CameraService.getAvailableCameras();

    CameraDescription? chosen = widget.currentCamera;
    if (chosen == null && cameras.isNotEmpty) {
      chosen = await CameraService.getSelectedCamera();
    }

    setState(() {
      _cameras = cameras;
      _selectedCamera = chosen ?? (cameras.isNotEmpty ? cameras.first : null);
      _isLoading = false;
    });

    if (_selectedCamera != null) {
      _initPreview(_selectedCamera!);
    }
  }

  Future<void> _initPreview(CameraDescription camera) async {
    await _previewController?.dispose();
    _previewController = null;

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _previewController = controller;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error init preview: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal mengakses preview kamera ini: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _saveAndApply() async {
    if (_selectedCamera == null) return;
    await CameraService.saveSelectedCameraName(_selectedCamera!.name);
    if (widget.onCameraChanged != null) {
      widget.onCameraChanged!(_selectedCamera!);
    }
    if (mounted) {
      Navigator.pop(context, _selectedCamera);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: AppTheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Perangkat Kamera',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Pilih webcam USB / DSLR untuk dipakai di booth',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_cameras.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tidak ada kamera yang terdeteksi. Hubungkan webcam USB atau periksa driver perangkat Anda.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Camera Selector Dropdown / Radio list
              const Text(
                'Daftar Kamera Terdeteksi:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CameraDescription>(
                    value: _selectedCamera,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: _cameras.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final cam = entry.value;
                      return DropdownMenuItem<CameraDescription>(
                        value: cam,
                        child: Text(
                          CameraService.formatCameraName(cam, idx),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (newCam) {
                      if (newCam != null && newCam != _selectedCamera) {
                        setState(() {
                          _selectedCamera = newCam;
                        });
                        _initPreview(newCam);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Live Preview Container
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                clipBehavior: Clip.antiAlias,
                child: _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    : (_previewController != null &&
                            _previewController!.value.isInitialized)
                        ? Center(
                            child: AspectRatio(
                              aspectRatio:
                                  _previewController!.value.aspectRatio,
                              child: CameraPreview(_previewController!),
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                            ),
                          ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _selectedCamera != null ? _saveAndApply : null,
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text(
                      'Terapkan & Jadikan Default',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buttonPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
