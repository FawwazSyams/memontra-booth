import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/printer_service.dart';
import '../services/frame_service.dart';
import 'output.dart';

class ReviewScreen extends StatefulWidget {
  final String sessionId;
  final String layoutType;
  final String frameImagePath;
  final List<XFile> photos;
  final List<XFile> allPhotos;

  const ReviewScreen({
    super.key,
    required this.sessionId,
    required this.layoutType,
    required this.frameImagePath,
    required this.photos,
    required this.allPhotos,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _isProcessing = false;
  int _secondsRemaining = 60;
  Timer? _countdownTimer;

  final List<Map<String, dynamic>> _filters = [
    {
      'name': 'Original',
      'matrix': <double>[
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ],
    },
    {
      'name': 'Natural Glow',
      'matrix': <double>[
        1.08, 0, 0, 0, 8,
        0, 1.08, 0, 0, 8,
        0, 0, 1.08, 0, 8,
        0, 0, 0, 1, 0,
      ],
    },
    {
      'name': 'Cool Tone',
      'matrix': <double>[
        0.92, 0, 0, 0, 0,
        0, 1.0, 0, 0, 8,
        0, 0, 1.18, 0, 16,
        0, 0, 0, 1, 0,
      ],
    },
    {
      'name': 'Warm Film',
      'matrix': <double>[
        1.18, 0.08, 0.08, 0, 0,
        0.08, 1.0, 0.08, 0, 0,
        0.08, 0.08, 0.82, 0, 0,
        0, 0, 0, 1, 0,
      ],
    },
    {
      'name': 'Vintage 90s',
      'matrix': <double>[
        0.9, 0.45, 0.1, 0, 0,
        0.28, 0.82, 0.1, 0, 0,
        0.18, 0.28, 0.52, 0, 0,
        0, 0, 0, 1, 0,
      ],
    },
    {
      'name': 'Classic B&W',
      'matrix': <double>[
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0, 0, 0, 1, 0,
      ],
    },
  ];

  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
          _printAndFinish();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _printAndFinish() async {
    if (_isProcessing) return;
    _countdownTimer?.cancel();

    setState(() => _isProcessing = true);

    // Kirim SEMUA foto dari sesi ini ke server (bukan cuma 3 foto doang)
    final photosToUpload = widget.allPhotos.isNotEmpty ? widget.allPhotos : widget.photos;
    for (int i = 0; i < photosToUpload.length; i++) {
      try {
        await ApiService.uploadPhoto(
          widget.sessionId,
          photosToUpload[i],
          i + 1,
        );
      } catch (e) {
        debugPrint('Upload photo background note: $e');
      }
    }

    // Render dan upload Hasil Foto Strip + Frame (Komposit Final) untuk softfile download
    try {
      final stripBytes = await PrinterService.generateSingleStripJpeg(
        photos: widget.photos,
        frameAssetPath: widget.frameImagePath,
        filterMatrix: _filters[_selectedFilterIndex]['matrix'],
      );
      await ApiService.uploadStrip(widget.sessionId, stripBytes);
    } catch (e) {
      debugPrint('Upload composite strip photo note: $e');
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OutputScreen(
          sessionId: widget.sessionId,
          selectedPhotos: widget.photos,
          frameImagePath: widget.frameImagePath,
          filterMatrix: _filters[_selectedFilterIndex]['matrix'],
          filterName: _filters[_selectedFilterIndex]['name'],
        ),
      ),
    );
  }

  Widget _buildPhoto(XFile photo) {
    Widget img = kIsWeb
        ? Image.network(photo.path, fit: BoxFit.cover)
        : Image.file(File(photo.path), fit: BoxFit.cover);

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_filters[_selectedFilterIndex]['matrix']),
      child: img,
    );
  }

  Widget _buildSingleStripView({
    required double width,
    required double height,
    required List<XFile> photos,
    required String frameImagePath,
  }) {
    final slotX = width * (90 / 1200);
    final slotW = width * (1020 / 1200);
    final slotH = height * (830 / 3600);
    final slot1Y = height * (185 / 3600);
    final slot2Y = height * (1190 / 3600);
    final slot3Y = height * (2190 / 3600);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Photo Slot 1 (Top)
          if (photos.isNotEmpty)
            Positioned(
              top: slot1Y,
              left: slotX,
              width: slotW,
              height: slotH,
              child: _buildPhoto(photos[0]),
            ),

          // Photo Slot 2 (Middle)
          if (photos.length > 1)
            Positioned(
              top: slot2Y,
              left: slotX,
              width: slotW,
              height: slotH,
              child: _buildPhoto(photos[1]),
            ),

          // Photo Slot 3 (Bottom)
          if (photos.length > 2)
            Positioned(
              top: slot3Y,
              left: slotX,
              width: slotW,
              height: slotH,
              child: _buildPhoto(photos[2]),
            ),

          // Frame Overlay Graphic
          Positioned.fill(
            child: FrameService.buildFrameOverlayWidget(
              frameImagePath,
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider({required double height}) {
    return SizedBox(
      width: 2,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxHeight / 16).floor();
          return Column(
            children: List.generate(
              count > 0 ? count : 1,
              (index) => Container(
                width: 2,
                height: 8,
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.grey.withValues(alpha: 0.35),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Ukuran preview lembar 4R (rasio 4:6 = 2:3) dengan 2 strip kembar 2x6
    const double paperPreviewW = 390.0;
    const double paperPreviewH = 585.0;
    const double dividerW = 2.0;
    const double stripPreviewW = (paperPreviewW - dividerW) / 2; // 194.0 persis tanpa overflow
    const double stripPreviewH = paperPreviewH;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
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
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
              child: Row(
                children: [
                  // LEFT: Live Photo Strip Preview (Lembar 4R - 2 Strip Kembar)
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: paperPreviewW,
                            height: paperPreviewH,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F4C5C).withValues(alpha: 0.18),
                                  blurRadius: 32,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Row(
                                    children: [
                                      // Strip 1: Sisi Kiri
                                      _buildSingleStripView(
                                        width: stripPreviewW,
                                        height: stripPreviewH,
                                        photos: widget.photos,
                                        frameImagePath: widget.frameImagePath,
                                      ),

                                      // Garis Perforasi / Belah Tengah
                                      _buildDashedDivider(height: stripPreviewH),

                                      // Strip 2: Sisi Kanan (Kembar Identik)
                                      _buildSingleStripView(
                                        width: stripPreviewW,
                                        height: stripPreviewH,
                                        photos: widget.photos,
                                        frameImagePath: widget.frameImagePath,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Keterangan 4R Double Strip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.content_cut_rounded,
                                  size: 15,
                                  color: AppTheme.primary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Format Cetak 4R (1 Lembar = 2 Strip Kembar)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn().slideY(begin: 0.15),
                    ),
                  ),

                  const SizedBox(width: 32),

                  // RIGHT: Add Filter UI Controls
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with Back button and Active Timer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                _countdownTimer?.cancel();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text(
                                'GANTI FOTO',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),

                            // Active Timer Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _secondsRemaining <= 10
                                      ? AppTheme.error
                                      : AppTheme.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    color: _secondsRemaining <= 10
                                        ? AppTheme.error
                                        : AppTheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTimer(_secondsRemaining),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: _secondsRemaining <= 10
                                          ? AppTheme.error
                                          : AppTheme.textDark,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Pilih Efek Filter',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sentuh filter untuk melihat pratinjau strip foto secara langsung',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textDark,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Filters Grid
                        Expanded(
                          child: GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 18,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: _filters.length,
                            itemBuilder: (context, index) {
                              final isSelected = index == _selectedFilterIndex;
                              final filter = _filters[index];

                              return GestureDetector(
                                onTap: () => setState(() => _selectedFilterIndex = index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : Colors.white,
                                      width: isSelected ? 4 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? AppTheme.primary.withValues(alpha: 0.25)
                                            : Colors.black.withValues(alpha: 0.05),
                                        blurRadius: isSelected ? 14 : 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(14),
                                          ),
                                          child: ColorFiltered(
                                            colorFilter: ColorFilter.matrix(filter['matrix']),
                                            child: widget.photos.isNotEmpty
                                                ? (kIsWeb
                                                    ? Image.network(
                                                        widget.photos[0].path,
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                      )
                                                    : Image.file(
                                                        File(widget.photos[0].path),
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                      ))
                                                : Container(color: Colors.grey[200]),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10.0,
                                          horizontal: 8.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (isSelected)
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                size: 16,
                                                color: AppTheme.primary,
                                              ),
                                            if (isSelected) const SizedBox(width: 4),
                                            Text(
                                              filter['name'],
                                              style: TextStyle(
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                color: AppTheme.textDark,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Bottom Action Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _isProcessing
                                ? Row(
                                    children: const [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      SizedBox(width: 14),
                                      Text(
                                        'Menyiapkan Cetakan...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                    ],
                                  )
                                : ElevatedButton.icon(
                                    onPressed: _printAndFinish,
                                    icon: const Text(
                                      'CETAK FOTO SEKARANG',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    label: const Icon(Icons.print_rounded),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 36,
                                        vertical: 18,
                                      ),
                                    ),
                                  ).animate().fadeIn(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
