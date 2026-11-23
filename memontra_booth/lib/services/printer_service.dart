import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image/image.dart' as img;

class PrinterService {
  /// Ukuran kanvas 4R standar (4 x 6 inch pada 600 DPI = 2400 x 3600 px)
  /// Terdiri dari 2 strip berdampingan (masing-masing 1200 x 3600 px = 2x6 inch)
  static const double canvasWidth = 2400.0;
  static const double canvasHeight = 3600.0;
  static const double stripWidth = 1200.0;
  static const double stripHeight = 3600.0;

  // Koordinat slot foto pada masing-masing strip (lebar 1200, tinggi 3600)
  // Cutout frame di strip: x: 100..1100 (lebar ~1000), y: 198..1000, 1206..2007, 2211..3007
  static const double slotX = 90.0;
  static const double slotWidth = 1020.0;
  static const double slotHeight = 830.0;
  static const double slot1Y = 185.0;
  static const double slot2Y = 1190.0;
  static const double slot3Y = 2190.0;

  /// Render 4R Double Strip (2 strip identik berdampingan) menjadi byte PNG resolusi tinggi
  static Future<Uint8List> generate4RDoubleStripImage({
    required List<XFile> photos,
    required String frameAssetPath,
    List<double>? filterMatrix,
    Color? backgroundColor,
    bool drawPerforationGuide = true,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
    );

    // 1. Gambar background putih (kertas foto 4R / custom background)
    final bgPaint = Paint()..color = backgroundColor ?? Colors.white;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      bgPaint,
    );

    // 2. Decode foto-foto yang dipilih (maksimal 3 foto untuk 3 slot)
    final List<ui.Image?> decodedPhotos = [];
    for (int i = 0; i < 3; i++) {
      if (i < photos.length) {
        try {
          final bytes = await photos[i].readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frameInfo = await codec.getNextFrame();
          decodedPhotos.add(frameInfo.image);
        } catch (e) {
          debugPrint('Error decoding photo $i: $e');
          decodedPhotos.add(null);
        }
      } else {
        decodedPhotos.add(null);
      }
    }

    // 3. Siapkan Paint dengan ColorFilter jika ada filter yang dipilih
    final photoPaint = Paint();
    if (filterMatrix != null && filterMatrix.length == 20) {
      photoPaint.colorFilter = ColorFilter.matrix(filterMatrix);
    }

    // 4. Load asset gambar frame PNG (Asset atau File Kustom)
    ui.Image? frameImage = await _loadFrameImage(frameAssetPath);

    final slotYPositions = [slot1Y, slot2Y, slot3Y];

    // Helper untuk menggambar 1 strip lengkap (3 foto + frame overlay)
    void renderSingleStrip(double offsetX) {
      if (backgroundColor != null && backgroundColor != Colors.white) {
        final stripBg = Paint()..color = backgroundColor;
        canvas.drawRect(
          Rect.fromLTWH(offsetX, 0, stripWidth, stripHeight),
          stripBg,
        );
      }

      // Gambar 3 foto di bawah frame
      for (int i = 0; i < 3; i++) {
        final img = decodedPhotos[i];
        if (img != null) {
          final destRect = Rect.fromLTWH(
            offsetX + slotX,
            slotYPositions[i],
            slotWidth,
            slotHeight,
          );
          final srcRect = _calculateCoverSrcRect(
            img.width,
            img.height,
            slotWidth,
            slotHeight,
          );
          canvas.drawImageRect(img, srcRect, destRect, photoPaint);
        }
      }

      // Gambar Frame PNG di atas foto
      if (frameImage != null) {
        final frameSrc = Rect.fromLTWH(
          0,
          0,
          frameImage.width.toDouble(),
          frameImage.height.toDouble(),
        );
        final frameDest = Rect.fromLTWH(
          offsetX,
          0,
          stripWidth,
          stripHeight,
        );
        canvas.drawImageRect(frameImage, frameSrc, frameDest, Paint());
      }
    }

    // Strip 1: Sisi Kiri (x: 0 .. 1200)
    renderSingleStrip(0.0);

    // Strip 2: Sisi Kanan (x: 1200 .. 2400) - Identik (Twin Strip)
    renderSingleStrip(stripWidth);

    // 5. Garis panduan belah dua / perforasi (di tengah x: 1200)
    if (drawPerforationGuide) {
      final linePaint = Paint()
        ..color = const Color(0x33000000) // Abu-abu sangat tipis & halus
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      // Buat garis putus-putus halus (dashed line)
      const double dashHeight = 20.0;
      const double dashSpace = 20.0;
      double startY = 0.0;
      while (startY < canvasHeight) {
        canvas.drawLine(
          Offset(stripWidth, startY),
          Offset(stripWidth, startY + dashHeight),
          linePaint,
        );
        startY += dashHeight + dashSpace;
      }
    }

    // Selesaikan canvas dan hasilkan PNG bytes
    final picture = recorder.endRecording();
    final finalImage = await picture.toImage(
      canvasWidth.toInt(),
      canvasHeight.toInt(),
    );
    final byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }

  /// Generate 1 strip foto tunggal (1200 x 3600 px) untuk softfile download customer
  static Future<Uint8List> generateSingleStripImage({
    required List<XFile> photos,
    required String frameAssetPath,
    List<double>? filterMatrix,
    Color? backgroundColor,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, stripWidth, stripHeight),
    );

    // 1. Background strip
    final bgPaint = Paint()..color = backgroundColor ?? Colors.white;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, stripWidth, stripHeight),
      bgPaint,
    );

    // 2. Decode foto
    final List<ui.Image?> decodedPhotos = [];
    for (int i = 0; i < 3; i++) {
      if (i < photos.length) {
        try {
          final bytes = await photos[i].readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frameInfo = await codec.getNextFrame();
          decodedPhotos.add(frameInfo.image);
        } catch (e) {
          decodedPhotos.add(null);
        }
      } else {
        decodedPhotos.add(null);
      }
    }

    final photoPaint = Paint();
    if (filterMatrix != null && filterMatrix.length == 20) {
      photoPaint.colorFilter = ColorFilter.matrix(filterMatrix);
    }

    // 3. Frame Image
    final frameImage = await _loadFrameImage(frameAssetPath);
    final slotYPositions = [slot1Y, slot2Y, slot3Y];

    // Gambar 3 foto
    for (int i = 0; i < 3; i++) {
      final img = decodedPhotos[i];
      if (img != null) {
        final destRect = Rect.fromLTWH(
          slotX,
          slotYPositions[i],
          slotWidth,
          slotHeight,
        );
        final srcRect = _calculateCoverSrcRect(
          img.width,
          img.height,
          slotWidth,
          slotHeight,
        );
        canvas.drawImageRect(img, srcRect, destRect, photoPaint);
      }
    }

    // Gambar Frame Overlay
    if (frameImage != null) {
      final frameSrc = Rect.fromLTWH(
        0,
        0,
        frameImage.width.toDouble(),
        frameImage.height.toDouble(),
      );
      final frameDest = const Rect.fromLTWH(0, 0, stripWidth, stripHeight);
      canvas.drawImageRect(frameImage, frameSrc, frameDest, Paint());
    }

    final picture = recorder.endRecording();
    final finalImage = await picture.toImage(
      stripWidth.toInt(),
      stripHeight.toInt(),
    );
    final byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }

  /// Generate 1 strip foto tunggal terkompresi JPEG (~500KB) untuk upload softfile cepat & stabil
  static Future<Uint8List> generateSingleStripJpeg({
    required List<XFile> photos,
    required String frameAssetPath,
    List<double>? filterMatrix,
    Color? backgroundColor,
    int quality = 88,
  }) async {
    final pngBytes = await generateSingleStripImage(
      photos: photos,
      frameAssetPath: frameAssetPath,
      filterMatrix: filterMatrix,
      backgroundColor: backgroundColor,
    );

    try {
      final decodedImage = img.decodeImage(pngBytes);
      if (decodedImage != null) {
        final jpgBytes = img.encodeJpg(decodedImage, quality: quality);
        debugPrint(
          'Single strip JPEG size: ${(jpgBytes.length / 1024).toStringAsFixed(1)} KB (PNG sebelumnya ${(pngBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB)',
        );
        return Uint8List.fromList(jpgBytes);
      }
    } catch (e) {
      debugPrint('Error re-encoding strip to JPEG: $e');
    }

    return pngBytes;
  }

  /// Helper untuk memuat gambar frame baik dari Flutter Assets maupun File Sistem Windows
  static Future<ui.Image?> _loadFrameImage(String framePath) async {
    try {
      Uint8List bytes;
      if (framePath.startsWith('assets/')) {
        final byteData = await rootBundle.load(framePath);
        bytes = byteData.buffer.asUint8List();
      } else {
        final file = File(framePath);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        } else {
          debugPrint('Frame $framePath tidak ditemukan di disk, fallback ke assets');
          final byteData = await rootBundle.load('assets/frames/strip1.png');
          bytes = byteData.buffer.asUint8List();
        }
      }
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    } catch (e) {
      debugPrint('Error loading frame image: $e');
      return null;
    }
  }

  /// Hitung Rect sumber foto agar pas dengan mode BoxFit.cover (tidak distorsi / gepeng)
  static Rect _calculateCoverSrcRect(
    int imgW,
    int imgH,
    double destW,
    double destH,
  ) {
    final double imgRatio = imgW / imgH;
    final double destRatio = destW / destH;

    if (imgRatio > destRatio) {
      // Gambar asli lebih lebar: crop sisi kiri & kanan
      final double cropW = imgH * destRatio;
      final double cropX = (imgW - cropW) / 2.0;
      return Rect.fromLTWH(cropX, 0, cropW, imgH.toDouble());
    } else {
      // Gambar asli lebih tinggi: crop atas & bawah
      final double cropH = imgW / destRatio;
      final double cropY = (imgH - cropH) / 2.0;
      return Rect.fromLTWH(0, cropY, imgW.toDouble(), cropH);
    }
  }

  /// Buat dokumen PDF ukuran 4R (4 x 6 inch borderless)
  static Future<Uint8List> generate4RPdfBytes(Uint8List imageBytes) async {
    final pdf = pw.Document();

    // Ukuran 4R: 4 x 6 inchi
    final pageFormat = PdfPageFormat(
      4.0 * PdfPageFormat.inch,
      6.0 * PdfPageFormat.inch,
      marginAll: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(
              pw.MemoryImage(imageBytes),
              fit: pw.BoxFit.fill,
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  /// Ambil daftar printer yang terpasang di Windows
  static Future<List<Printer>> getInstalledPrinters() async {
    if (kIsWeb) {
      // Di Web / Chrome, browser tidak mengizinkan akses langsung hardware printer
      return [];
    }
    try {
      return await Printing.listPrinters();
    } catch (e) {
      debugPrint('Error listing printers: $e');
      return [];
    }
  }

  /// Cari printer HP Ink Tank 115 atau printer default
  static Future<Printer?> findTargetPrinter({String? preferredName}) async {
    final printers = await getInstalledPrinters();
    if (printers.isEmpty) return null;

    if (preferredName != null && preferredName.isNotEmpty) {
      for (final p in printers) {
        if (p.name.toLowerCase().contains(preferredName.toLowerCase())) {
          return p;
        }
      }
    }

    // Cari printer dengan kata kunci "115" atau "HP Ink Tank" atau "HP"
    for (final p in printers) {
      final nameLower = p.name.toLowerCase();
      if (nameLower.contains('115') ||
          (nameLower.contains('hp') && nameLower.contains('ink tank'))) {
        return p;
      }
    }

    for (final p in printers) {
      if (p.name.toLowerCase().contains('hp')) {
        return p;
      }
    }

    // Fallback ke printer default Windows
    for (final p in printers) {
      if (p.isDefault) {
        return p;
      }
    }

    return printers.first;
  }

  /// Cetak langsung ke printer (Direct Print tanpa dialog popup)
  static Future<bool> directPrint4R({
    required Uint8List pdfBytes,
    Printer? targetPrinter,
    String jobName = 'Memontra_4R_Print',
  }) async {
    if (kIsWeb) {
      // Pada browser Web, direct print dialihkan ke layoutPdf bawaan browser
      return await showPrintDialog4R(pdfBytes: pdfBytes, jobName: jobName);
    }
    try {
      final printer = targetPrinter ?? await findTargetPrinter();
      if (printer == null) {
        debugPrint('Tidak ada printer yang ditemukan untuk direct print.');
        return false;
      }

      final pageFormat = PdfPageFormat(
        4.0 * PdfPageFormat.inch,
        6.0 * PdfPageFormat.inch,
        marginAll: 0,
      );

      return await Printing.directPrintPdf(
        printer: printer,
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: jobName,
        format: pageFormat,
      );
    } catch (e) {
      debugPrint('Direct print error: $e');
      return false;
    }
  }

  /// Tampilkan Dialog Cetak Windows (berguna saat setup awal untuk atur kertas 4x6 / Glossy)
  static Future<bool> showPrintDialog4R({
    required Uint8List pdfBytes,
    String jobName = 'Memontra_4R_Print',
  }) async {
    try {
      final pageFormat = PdfPageFormat(
        4.0 * PdfPageFormat.inch,
        6.0 * PdfPageFormat.inch,
        marginAll: 0,
      );

      return await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: jobName,
        format: pageFormat,
      );
    } catch (e) {
      debugPrint('Layout print error: $e');
      return false;
    }
  }
}
