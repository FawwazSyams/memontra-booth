import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/printer_service.dart';
import '../services/frame_service.dart';

class OutputScreen extends StatefulWidget {
  final String sessionId;
  final List<XFile> selectedPhotos;
  final String? frameImagePath;
  final List<double>? filterMatrix;
  final String? filterName;

  const OutputScreen({
    super.key,
    required this.sessionId,
    required this.selectedPhotos,
    this.frameImagePath,
    this.filterMatrix,
    this.filterName,
  });

  @override
  State<OutputScreen> createState() => _OutputScreenState();
}

class _OutputScreenState extends State<OutputScreen> {
  Timer? _countdownTimer;
  Timer? _gifTimer;

  int _countdown = 60;
  int _gifIndex = 0;
  bool _showStripPreview = true; // Toggle antara format 4R Double Strip dan Animasi GIF

  // Status dan State Printer Fisik
  Uint8List? _cachedPdfBytes;
  Printer? _detectedPrinter;
  bool _isPrinting = false;
  bool _isPrintFinished = false;
  double _printProgress = 0.0;
  String _printStatusMessage = 'Menyiapkan layout cetak 4R...';

  @override
  void initState() {
    super.initState();
    _startTimers();
    _initAndTriggerPrint();
  }

  void _startTimers() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown == 0) {
        _resetToHome();
      } else {
        setState(() => _countdown--);
      }
    });

    _gifTimer = Timer.periodic(const Duration(milliseconds: 550), (timer) {
      if (mounted && widget.selectedPhotos.isNotEmpty) {
        setState(() {
          _gifIndex = (_gifIndex + 1) % widget.selectedPhotos.length;
        });
      }
    });
  }

  /// Menyiapkan dokumen 4R dan langsung mengirim ke printer fisik (HP Ink Tank 115)
  Future<void> _initAndTriggerPrint() async {
    if (_isPrinting) return;
    setState(() {
      _isPrinting = true;
      _printProgress = 0.15;
      _printStatusMessage = 'Menyusun layout 4R double strip...';
    });

    try {
      // 1. Render kanvas 4R (2400 x 3600 px = 2 strip 1200x3600 kembar)
      final pngBytes = await PrinterService.generate4RDoubleStripImage(
        photos: widget.selectedPhotos,
        frameAssetPath: widget.frameImagePath ?? 'assets/frames/strip1.png',
        filterMatrix: widget.filterMatrix,
      );

      // Pastikan foto strip komposit ter-upload ke backend untuk softfile download pelanggan
      PrinterService.generateSingleStripJpeg(
        photos: widget.selectedPhotos,
        frameAssetPath: widget.frameImagePath ?? 'assets/frames/strip1.png',
        filterMatrix: widget.filterMatrix,
      ).then((singleStripBytes) {
        ApiService.uploadStrip(widget.sessionId, singleStripBytes);
      }).catchError((e) {
        debugPrint('Output background uploadStrip note: $e');
      });

      if (!mounted) return;
      setState(() {
        _printProgress = 0.40;
        _printStatusMessage = 'Membuat dokumen cetak ukuran 4R (4x6 in)...';
      });

      // 2. Generate PDF borderless 4R
      final pdfBytes = await PrinterService.generate4RPdfBytes(pngBytes);
      _cachedPdfBytes = pdfBytes;

      if (!mounted) return;
      setState(() {
        _printProgress = 0.65;
        _printStatusMessage = 'Mencari printer HP Ink Tank 115...';
      });

      // 3. Deteksi printer HP Ink Tank 115 atau printer default Windows
      if (kIsWeb) {
        if (!mounted) return;
        setState(() {
          _printProgress = 1.0;
          _isPrinting = false;
          _isPrintFinished = true;
          _printStatusMessage =
              'Mode Web aktif. Dokumen 4R siap dicetak (buka dialog printer atau jalankan versi Windows untuk direct print).';
        });
        return;
      }

      final printer = await PrinterService.findTargetPrinter(preferredName: '115');
      _detectedPrinter = printer;

      if (printer != null) {
        setState(() {
          _printProgress = 0.85;
          _printStatusMessage = 'Mengirim perintah cetak ke ${printer.name}...';
        });

        // 4. Kirim Direct Print ke printer
        final success = await PrinterService.directPrint4R(
          pdfBytes: pdfBytes,
          targetPrinter: printer,
          jobName: 'Memontra_4R_${widget.sessionId}',
        );

        if (!mounted) return;
        setState(() {
          _printProgress = 1.0;
          _isPrinting = false;
          if (success) {
            _isPrintFinished = true;
            _printStatusMessage =
                'Selesai dikirim ke ${printer.name}! Silakan ambil foto di baki printer.';
          } else {
            _isPrintFinished = true;
            _printStatusMessage =
                'Printer ${printer.name} siap. Klik "CETAK ULANG" jika belum tercetak.';
          }
        });
      } else {
        if (!mounted) return;
        setState(() {
          _printProgress = 1.0;
          _isPrinting = false;
          _isPrintFinished = false;
          _printStatusMessage =
              'Printer belum terdeteksi. Pastikan kabel USB HP Ink Tank 115 terhubung.';
        });
      }
    } catch (e) {
      debugPrint('Error printing workflow: $e');
      if (!mounted) return;
      setState(() {
        _printProgress = 1.0;
        _isPrinting = false;
        _printStatusMessage = 'Gunakan tombol dialog printer untuk mencetak.';
      });
    }
  }

  /// Cetak ulang langsung (Direct Print)
  Future<void> _reprintDirect() async {
    if (_cachedPdfBytes == null) {
      await _initAndTriggerPrint();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mengirim salinan cetak ke printer HP Ink Tank 115...'),
        backgroundColor: AppTheme.primary,
        duration: Duration(seconds: 2),
      ),
    );

    final ok = await PrinterService.directPrint4R(
      pdfBytes: _cachedPdfBytes!,
      targetPrinter: _detectedPrinter,
      jobName: 'Memontra_4R_Salinan_${widget.sessionId}',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Salinan berhasil dikirim ke printer!'
                : 'Silakan periksa sambungan kabel USB printer.',
          ),
          backgroundColor: ok ? AppTheme.success : Colors.redAccent,
        ),
      );
    }
  }

  /// Buka Dialog Cetak Windows bawaan (berguna untuk testing / atur margin / paper quality)
  Future<void> _openWindowsPrintDialog() async {
    if (_cachedPdfBytes == null) {
      await _initAndTriggerPrint();
    }
    if (_cachedPdfBytes != null) {
      await PrinterService.showPrintDialog4R(
        pdfBytes: _cachedPdfBytes!,
        jobName: 'Memontra_4R_${widget.sessionId}',
      );
    }
  }

  void _resetToHome() {
    _countdownTimer?.cancel();
    _gifTimer?.cancel();
    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _gifTimer?.cancel();
    super.dispose();
  }

  Widget _buildSingleFilteredPhoto(XFile photo) {
    Widget img = kIsWeb
        ? Image.network(photo.path, fit: BoxFit.cover)
        : Image.file(File(photo.path), fit: BoxFit.cover);

    if (widget.filterMatrix != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(widget.filterMatrix!),
        child: img,
      );
    }
    return img;
  }

  /// Widget 1 strip foto (3 foto + frame overlay)
  Widget _buildSingleStripView({
    required double width,
    required double height,
    required bool isGif,
  }) {
    final len = widget.selectedPhotos.length;
    final photo1 = isGif && len > 0
        ? widget.selectedPhotos[_gifIndex % len]
        : (len > 0 ? widget.selectedPhotos[0] : null);
    final photo2 = isGif && len > 0
        ? widget.selectedPhotos[(_gifIndex + 1) % len]
        : (len > 1 ? widget.selectedPhotos[1] : (len > 0 ? widget.selectedPhotos[0] : null));
    final photo3 = isGif && len > 0
        ? widget.selectedPhotos[(_gifIndex + 2) % len]
        : (len > 2 ? widget.selectedPhotos[2] : (len > 0 ? widget.selectedPhotos[0] : null));

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
          // Slot 1
          if (photo1 != null)
            Positioned(
              top: slot1Y,
              left: slotX,
              width: slotW,
              height: slotH,
              child: isGif
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: SizedBox(
                        key: ValueKey('slot1_${_gifIndex}_${photo1.path}'),
                        width: slotW,
                        height: slotH,
                        child: _buildSingleFilteredPhoto(photo1),
                      ),
                    )
                  : _buildSingleFilteredPhoto(photo1),
            ),

          // Slot 2
          if (photo2 != null)
            Positioned(
              top: slot2Y,
              left: slotX,
              width: slotW,
              height: slotH,
              child: isGif
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: SizedBox(
                        key: ValueKey('slot2_${_gifIndex}_${photo2.path}'),
                        width: slotW,
                        height: slotH,
                        child: _buildSingleFilteredPhoto(photo2),
                      ),
                    )
                  : _buildSingleFilteredPhoto(photo2),
            ),

          // Slot 3
          if (photo3 != null)
            Positioned(
              top: slot3Y,
              left: slotX,
              width: slotW,
              height: slotH,
              child: isGif
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: SizedBox(
                        key: ValueKey('slot3_${_gifIndex}_${photo3.path}'),
                        width: slotW,
                        height: slotH,
                        child: _buildSingleFilteredPhoto(photo3),
                      ),
                    )
                  : _buildSingleFilteredPhoto(photo3),
            ),

          // Frame Overlay Graphic
          if (widget.frameImagePath != null)
            Positioned.fill(
              child: FrameService.buildFrameOverlayWidget(
                widget.frameImagePath,
                fit: BoxFit.fill,
              ),
            ),
        ],
      ),
    );
  }

  /// Garis putus-putus tanda belah perforasi kertas 4R
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

  /// Lembar Utuh 4R (2 Strip Kembar Berdampingan)
  Widget _buildDoubleStrip4RPreview({required bool isGif}) {
    const double paperW = 390.0;
    const double paperH = 585.0;
    const double dividerW = 2.0;
    const double stripW = (paperW - dividerW) / 2; // 194.0 persis tanpa overflow
    const double stripH = paperH;

    return Container(
      width: paperW,
      height: paperH,
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
                // Strip Kiri
                _buildSingleStripView(
                  width: stripW,
                  height: stripH,
                  isGif: isGif,
                ),

                // Garis Perforasi / Belah Tengah
                _buildDashedDivider(height: stripH),

                // Strip Kanan (Kembar Identik)
                _buildSingleStripView(
                  width: stripW,
                  height: stripH,
                  isGif: isGif,
                ),
              ],
            ),

            // Badge Indikator GIF jika mode GIF aktif
            if (isGif)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: AppTheme.secondary,
                        size: 14,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'GIF BOOMERANG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String downloadUrl =
        '${ApiService.serverHost}/download/${widget.sessionId}';

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
                  // LEFT: Final Photo Strip or GIF Preview (Lembar 4R - 2 Strip Kembar)
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Toggle Switcher (Cetak 4R vs Animasi GIF)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => setState(() => _showStripPreview = true),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _showStripPreview
                                          ? AppTheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.photo_library_rounded,
                                          size: 18,
                                          color: _showStripPreview
                                              ? Colors.white
                                              : AppTheme.textDark,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Lembar Cetak 4R (2 Strip)',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _showStripPreview
                                                ? Colors.white
                                                : AppTheme.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => setState(() => _showStripPreview = false),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !_showStripPreview
                                          ? AppTheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.gif_rounded,
                                          size: 22,
                                          color: !_showStripPreview
                                              ? Colors.white
                                              : AppTheme.textDark,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Animasi GIF',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: !_showStripPreview
                                                ? Colors.white
                                                : AppTheme.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Preview Container Lembar 4R
                          SizedBox(
                            height: 585,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: _buildDoubleStrip4RPreview(
                                isGif: !_showStripPreview,
                              ),
                            ),
                          ).animate().fadeIn().scale(duration: 350.ms),

                          const SizedBox(height: 10),

                          // Keterangan perforasi / belah dua
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
                                  'Kertas 4R Perforasi (1 lembar terbagi 2 strip 2x6)',
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
                      ),
                    ),
                  ),

                  const SizedBox(width: 32),

                  // RIGHT: QR Download info & Print Progress
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Timer Top Right
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    color: AppTheme.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Kembali ke awal: 00:${_countdown.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ).animate().fadeIn(),

                        const Spacer(),

                        const Text(
                          'Unduh Foto Digital Kamu',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ).animate().fadeIn().slideY(begin: -0.15),
                        const SizedBox(height: 6),
                        const Text(
                          'Scan QR code dengan kamera HP untuk simpan foto strip dan GIF',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.textDark,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // QR Code Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F4C5C).withValues(alpha: 0.08),
                                blurRadius: 28,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              QrImageView(
                                data: downloadUrl,
                                version: QrVersions.auto,
                                size: 175,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Kode Sesi: ${widget.sessionId}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms).scale(),

                        const SizedBox(height: 22),

                        // Realistic Printing Status Card (Terhubung ke HP Ink Tank 115)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 22,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isPrintFinished
                                  ? AppTheme.success.withValues(alpha: 0.5)
                                  : AppTheme.primary.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F4C5C).withValues(alpha: 0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isPrintFinished
                                          ? AppTheme.success.withValues(alpha: 0.15)
                                          : AppTheme.primary.withValues(alpha: 0.12),
                                    ),
                                    child: Icon(
                                      _isPrintFinished
                                          ? Icons.check_circle_rounded
                                          : Icons.print_rounded,
                                      size: 26,
                                      color: _isPrintFinished
                                          ? AppTheme.success
                                          : AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isPrintFinished
                                              ? 'Pencetakan Selesai!'
                                              : 'Mencetak ke HP Ink Tank 115',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _printStatusMessage,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _isPrintFinished
                                                ? AppTheme.success
                                                : AppTheme.textDark
                                                    .withValues(alpha: 0.8),
                                            fontWeight: _isPrintFinished
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: _printProgress,
                                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                  color: _isPrintFinished
                                      ? AppTheme.success
                                      : AppTheme.primary,
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 350.ms),

                        const Spacer(),

                        // Bottom Actions Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _reprintDirect,
                                  icon: const Icon(Icons.print_outlined),
                                  label: const Text(
                                    'CETAK ULANG',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  tooltip: 'Buka Dialog / Pengaturan Printer Windows',
                                  onPressed: _openWindowsPrintDialog,
                                  icon: const Icon(
                                    Icons.settings_suggest_rounded,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),

                            ElevatedButton.icon(
                              onPressed: _resetToHome,
                              icon: const Text(
                                'SELESAI (SESI BARU)',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              label: const Icon(Icons.home_rounded),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(),
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
