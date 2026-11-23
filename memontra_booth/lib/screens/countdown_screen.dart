import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/camera_service.dart';
import '../widgets/camera_settings_dialog.dart';
import 'photo_selection.dart';

class CountdownScreen extends StatefulWidget {
  final String sessionId;
  final String layoutType;
  final String frameImagePath;

  const CountdownScreen({
    super.key,
    required this.sessionId,
    required this.layoutType,
    required this.frameImagePath,
  });

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isSimulatedCamera = false;

  final List<XFile> _capturedPhotos = [];
  bool _isCapturing = false;
  int _countdown = -1; // -1: standby, 1-3: counting down for shutter
  bool _showFlash = false;

  // Session Timer (2 minutes = 120 seconds)
  int _sessionTimeRemaining = 120;
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera([CameraDescription? customCamera]) async {
    try {
      final cameras = await CameraService.getAvailableCameras();
      if (cameras.isEmpty) {
        debugPrint('Kamera hardware tidak ditemukan, beralih ke Mode Simulator.');
        _enableSimulatedCamera();
        return;
      }

      final camera = customCamera ??
          await CameraService.getSelectedCamera() ??
          cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          );

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
          _isSimulatedCamera = false;
        });
        if (_sessionTimer == null) {
          _startSessionTimer();
        }
      } else {
        await controller.dispose();
      }
    } catch (e) {
      debugPrint('Error init camera countdown: $e');
      _enableSimulatedCamera();
    }
  }

  Future<void> _openCameraSettings() async {
    if (_isCapturing) return;
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

  void _enableSimulatedCamera() {
    if (mounted) {
      setState(() {
        _isCameraReady = true;
        _isSimulatedCamera = true;
      });
      _startSessionTimer();
    }
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_sessionTimeRemaining > 0) {
          _sessionTimeRemaining--;
        } else {
          timer.cancel();
          _finishSession();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    // Countdown 3.. 2.. 1..
    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;
    setState(() {
      _countdown = 0;
      _showFlash = true; // Trigger visual flash
    });

    // Shutter Flash Effect
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _showFlash = false);
      }
    });

    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final photo = await _cameraController!.takePicture();
        if (mounted) {
          setState(() {
            _capturedPhotos.add(photo);
          });
        }
      } else {
        // Simulated capture fallback
        final simPhoto = await _createSimulatedPhoto(_capturedPhotos.length + 1);
        if (mounted) {
          setState(() {
            _capturedPhotos.add(simPhoto);
          });
        }
      }
    } catch (e) {
      debugPrint('Gagal ambil foto: $e');
    }

    if (mounted) {
      setState(() {
        _isCapturing = false;
        _countdown = -1;
      });
    }
  }

  Future<XFile> _createSimulatedPhoto(int index) async {
    try {
      final byteData = await rootBundle.load('assets/icons/logo-booth-fourth.png');
      final bytes = byteData.buffer.asUint8List();

      if (!kIsWeb) {
        final tempFile = File('${Directory.systemTemp.path}/sim_photo_${widget.sessionId}_$index.png');
        await tempFile.writeAsBytes(bytes);
        return XFile(tempFile.path);
      } else {
        return XFile.fromData(bytes, name: 'sim_photo_$index.png');
      }
    } catch (_) {
      return XFile('assets/icons/logo-booth-fourth.png');
    }
  }

  void _finishSession() {
    _sessionTimer?.cancel();

    if (_capturedPhotos.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ambil minimal 3 foto untuk strip fotomu!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoSelectionScreen(
          sessionId: widget.sessionId,
          layoutType: widget.layoutType,
          frameImagePath: widget.frameImagePath,
          allPhotos: _capturedPhotos,
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (_isCameraReady &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      return CameraService.buildResponsiveCameraPreview(_cameraController!);
    } else if (_isSimulatedCamera) {
      return Container(
        color: const Color(0xFF1E293B),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.face_retouching_natural_rounded,
                      size: 90,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Posisikan Wajah Kamu di Sini',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kamera siap. Tap tombol shutter di bawah untuk memotret',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _ViewfinderGridPainter(),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full Screen Live Camera View (Cermin photobooth layar penuh)
          Positioned.fill(
            child: _buildCameraView(),
          ),

          // 2. Soft Gradient Vignette (Memastikan teks dan tombol tetap berkontras tinggi)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0.0, 0.22, 0.70, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. Shutter Flash Overlay
          if (_showFlash)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showFlash ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(color: Colors.white),
                ),
              ),
            ),

          // 4. Center Countdown Overlay (3, 2, 1)
          if (_isCapturing && _countdown > 0)
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.88),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$_countdown',
                    style: const TextStyle(
                      fontSize: 110,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate(key: ValueKey(_countdown)).scale(
                    duration: 350.ms,
                    curve: Curves.elasticOut,
                  ),
            ),

          // 5. Foreground Content (Header, Thumbnails, Buttons)
          SafeArea(
            child: Column(
              children: [
                // Top Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Get Ready to Pose!',
                            style: TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: Colors.black87, blurRadius: 10),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  'Foto Terambil: ${_capturedPhotos.length} pose',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (_isSimulatedCamera) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppTheme.secondary.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: const Text(
                                    'Camera Demo Mode',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      // Session Timer & Camera Switch Button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _isCapturing ? null : _openCameraSettings,
                            tooltip: 'Pilih Kamera',
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Icon(
                                Icons.cameraswitch_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _sessionTimeRemaining <= 30
                                    ? AppTheme.error
                                    : Colors.white.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: _sessionTimeRemaining <= 30
                                      ? AppTheme.error
                                      : AppTheme.secondary,
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(_sessionTimeRemaining),
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: _sessionTimeRemaining <= 30
                                        ? AppTheme.error
                                        : Colors.white,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ).animate(
                            onPlay: (controller) => controller.repeat(reverse: true),
                          ).scale(
                            duration: _sessionTimeRemaining <= 15 ? 400.ms : 2.seconds,
                            begin: const Offset(1.0, 1.0),
                            end: Offset(
                              _sessionTimeRemaining <= 15 ? 1.06 : 1.02,
                              _sessionTimeRemaining <= 15 ? 1.06 : 1.02,
                            ),
                            curve: Curves.easeInOut,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Thumbnails of Captured Photos Strip
                if (_capturedPhotos.isNotEmpty)
                  Container(
                    height: 76,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: _capturedPhotos.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final photo = _capturedPhotos[index];
                        return Container(
                          width: 60,
                          height: 76,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? Image.network(photo.path, fit: BoxFit.cover)
                                : Image.file(File(photo.path), fit: BoxFit.cover),
                          ),
                        ).animate().scale(duration: 200.ms);
                      },
                    ),
                  ),

                // Bottom Controls Row
                Padding(
                  padding: const EdgeInsets.only(bottom: 28, left: 40, right: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Finish / Next Button
                      SizedBox(
                        width: 220,
                        child: _capturedPhotos.length >= 3
                            ? ElevatedButton.icon(
                                onPressed: _finishSession,
                                icon: const Icon(Icons.check_circle_rounded),
                                label: Text(
                                  'PILIH FOTO (${_capturedPhotos.length})',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  elevation: 4,
                                ),
                              ).animate().fadeIn()
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Ambil minimal 3 pose\n(${_capturedPhotos.length} / 3 foto)',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),

                      // Shutter Button
                      GestureDetector(
                        onTap: _isCapturing ? null : _takePicture,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCapturing
                                ? Colors.grey
                                : AppTheme.buttonPrimary,
                            border: Border.all(color: Colors.white, width: 6),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.buttonPrimary.withValues(alpha: 0.6),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                      ).animate().scale(),

                      // Spacer to balance layout
                      const SizedBox(width: 220),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    // Rule of thirds lines
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
