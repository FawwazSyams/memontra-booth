import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';

import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'services/camera_service.dart';
import 'widgets/camera_settings_dialog.dart';
import 'screens/frame_selection.dart';

void main() {
  Animate.defaultDuration = const Duration(milliseconds: 400);

  runApp(const ProviderScope(child: MemontraApp()));
}

class MemontraApp extends StatelessWidget {
  const MemontraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memontra Booth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AttractScreen(),
    );
  }
}

class AttractScreen extends StatefulWidget {
  const AttractScreen({super.key});

  @override
  State<AttractScreen> createState() => _AttractScreenState();
}

class _AttractScreenState extends State<AttractScreen> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera([CameraDescription? customCamera]) async {
    try {
      final cameras = await CameraService.getAvailableCameras();
      if (cameras.isEmpty) return;

      final camera = customCamera ??
          await CameraService.getSelectedCamera() ??
          cameras.first;

      await _cameraController?.dispose();

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraReady = true;
        });
      } else {
        await controller.dispose();
      }
    } catch (e) {
      debugPrint('Live camera attract screen info: $e');
    }
  }

  Future<void> _openCameraSettings() async {
    final newCam = await showDialog<CameraDescription>(
      context: context,
      builder: (ctx) => CameraSettingsDialog(
        currentCamera: _cameraController?.description,
      ),
    );

    if (newCam != null && mounted) {
      _initCamera(newCam);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _onTapStart() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final sessionId = await ApiService.startSession();

    // Lepaskan kamera agar CountdownScreen memiliki akses penuh ke sensor kamera
    await _cameraController?.dispose();
    _cameraController = null;
    _isCameraReady = false;

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FrameSelectionScreen(sessionId: sessionId),
      ),
    );

    // Ketika kembali ke layar Attract, nyalakan kembali live camera
    if (mounted) {
      _initCamera();
    }
  }

  Widget _buildBackground() {
    if (_isCameraReady &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      final double cameraAspect = _cameraController!.value.aspectRatio;

      return Stack(
        fit: StackFit.expand,
        children: [
          // Live Camera Stream dengan aspect ratio natural (tanpa zoom berlebih)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 100 * cameraAspect,
                height: 100,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),

          // Lapisan tipis agar logo dan tombol tetap kontras dan terbaca jelas
          Container(
            color: Colors.black.withValues(alpha: 0.18),
          ),
        ],
      );
    }

    // Fallback jika kamera belum siap / offline
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.bgTeal,
            AppTheme.surfaceWhite,
            AppTheme.bgPeach,
          ],
          stops: [0.1, 0.5, 0.9],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: GestureDetector(
        onTap: _onTapStart,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // 1. Live Camera Background
            Positioned.fill(
              child: _buildBackground(),
            ),

            // 2. Main Content: Murni Logo dan Tombol (Tanpa GlassCard)
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: AppTheme.primary)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo Memontra Booth
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: size.width * 0.70,
                            maxHeight: size.height * 0.42,
                          ),
                          child: Image.asset(
                            'assets/icons/logo-booth-third.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text(
                              'MEMONTRA BOOTH',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.universal,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Tombol Tap to Start
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 44,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.buttonPrimary,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                color: AppTheme.universal,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Tap to Start',
                                style: TextStyle(
                                  fontSize: 26,
                                  color: AppTheme.universal,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .scale(
                              begin: const Offset(1.0, 1.0),
                              end: const Offset(1.04, 1.04),
                              duration: 1400.ms,
                              curve: Curves.easeInOut,
                            ),
                      ],
                    )
                      .animate()
                      .fadeIn(duration: 500.ms),
            ),

            // 3. Settings / Camera Selector Button (Top-Right)
            Positioned(
              top: 24,
              right: 24,
              child: SafeArea(
                child: IconButton(
                  onPressed: _openCameraSettings,
                  tooltip: 'Pengaturan Kamera',
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
