import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  static const String _configFile = 'camera_settings.json';
  static List<CameraDescription> _cachedCameras = [];
  static String? _selectedCameraName;

  /// Ambil path file konfigurasi kamera
  static File _getConfigFile() {
    try {
      if (!kIsWeb && Platform.isWindows) {
        final appData = Platform.environment['APPDATA'];
        if (appData != null && appData.isNotEmpty) {
          final dir = Directory('$appData/MemontraBooth');
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          return File('${dir.path}/$_configFile');
        }
      }
    } catch (e) {
      debugPrint('Error getting APPDATA path: $e');
    }
    return File(_configFile);
  }

  /// Load nama kamera tersimpan dari disk
  static Future<String?> loadSavedCameraName() async {
    if (kIsWeb) return null;
    try {
      final file = _getConfigFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        _selectedCameraName = data['selected_camera_name'] as String?;
        return _selectedCameraName;
      }
    } catch (e) {
      debugPrint('Error reading camera settings: $e');
    }
    return null;
  }

  /// Simpan nama kamera pilihan ke disk
  static Future<void> saveSelectedCameraName(String cameraName) async {
    _selectedCameraName = cameraName;
    if (kIsWeb) return;
    try {
      final file = _getConfigFile();
      await file.writeAsString(
        jsonEncode({
          'selected_camera_name': cameraName,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );
      debugPrint('Camera setting saved: $cameraName');
    } catch (e) {
      debugPrint('Error saving camera setting: $e');
    }
  }

  /// Dapatkan daftar semua kamera yang terpasang
  static Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      _cachedCameras = await availableCameras();
      return _cachedCameras;
    } catch (e) {
      debugPrint('Error fetching available cameras: $e');
      return [];
    }
  }

  /// Dapatkan kamera yang saat ini dipilih atau rekomendasi terbaik
  static Future<CameraDescription?> getSelectedCamera() async {
    final cameras = await getAvailableCameras();
    if (cameras.isEmpty) return null;

    // 1. Cek dari setting yang tersimpan
    final savedName = _selectedCameraName ?? await loadSavedCameraName();
    if (savedName != null) {
      try {
        final matched = cameras.firstWhere(
          (c) => c.name.toLowerCase() == savedName.toLowerCase(),
        );
        return matched;
      } catch (_) {
        debugPrint('Saved camera "$savedName" not found, picking fallback');
      }
    }

    // 2. Prioritaskan kamera eksternal (Webcam USB, Cam Link, dsb.)
    // Pada Windows, kamera bawaan laptop biasanya mengandung kata 'integrated' / 'internal' / 'front'
    final externalCamera = cameras.firstWhere(
      (c) {
        final name = c.name.toLowerCase();
        final isBuiltin = name.contains('integrated') ||
            name.contains('internal') ||
            name.contains('facetime') ||
            name.contains('bawaan');
        return !isBuiltin || c.lensDirection == CameraLensDirection.external;
      },
      orElse: () => cameras.first,
    );

    return externalCamera;
  }

  /// Format nama kamera agar ramah dibaca pengguna di dialog
  static String formatCameraName(CameraDescription camera, int index) {
    final rawName = camera.name;
    if (rawName.isEmpty) return 'Kamera #${index + 1}';

    String type = '';
    final lower = rawName.toLowerCase();
    if (lower.contains('integrated') || lower.contains('internal')) {
      type = ' (Laptop Bawaan)';
    } else if (lower.contains('usb') ||
        lower.contains('webcam') ||
        lower.contains('cam link') ||
        camera.lensDirection == CameraLensDirection.external) {
      type = ' (Eksternal / USB)';
    }

    return '$rawName$type';
  }
}
