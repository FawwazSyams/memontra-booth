import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FrameService {
  static const String _configFile = 'custom_frames.json';
  static const String _themeConfigFile = 'kiosk_theme_settings.json';

  static final List<Map<String, dynamic>> defaultFrames = [
    {
      'id': 1,
      'name': 'Deep Blue Stars',
      'image_path': 'assets/frames/strip1.png',
      'layout_type': 'strip_vertical_3',
      'categories': ['Most Used', 'Classic', 'Trendy'],
      'background_color': '#07101E',
      'is_custom': false,
    },
    {
      'id': 2,
      'name': 'White Elegance',
      'image_path': 'assets/frames/strip2.png',
      'layout_type': 'strip_vertical_3',
      'categories': ['Most Used', 'Classic', 'Cute & Fun'],
      'background_color': '#FFFFFF',
      'is_custom': false,
    },
    {
      'id': 3,
      'name': 'Golden Sunset',
      'image_path': 'assets/frames/strip3.png',
      'layout_type': 'strip_vertical_3',
      'categories': ['Most Used', 'Vintage', 'Trendy'],
      'background_color': '#FFF8EE',
      'is_custom': false,
    },
    {
      'id': 4,
      'name': 'Vintage Retro',
      'image_path': 'assets/frames/strip1.png',
      'layout_type': 'strip_vertical_3',
      'categories': ['Vintage', 'Cute & Fun'],
      'background_color': '#2C1810',
      'is_custom': false,
    },
  ];

  /// Ambil direktori penyimpanan data lokal untuk Windows / Desktop
  static Directory _getStorageDir() {
    try {
      if (!kIsWeb && Platform.isWindows) {
        final appData = Platform.environment['APPDATA'];
        if (appData != null && appData.isNotEmpty) {
          final dir = Directory('$appData/MemontraBooth');
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          return dir;
        }
      }
    } catch (e) {
      debugPrint('Error getting storage dir: $e');
    }
    return Directory.current;
  }

  /// Folder khusus untuk menampung gambar frame kustom dari pengguna
  static Directory _getCustomFramesDir() {
    final baseDir = _getStorageDir();
    final customDir = Directory('${baseDir.path}/custom_frames');
    if (!customDir.existsSync()) {
      customDir.createSync(recursive: true);
    }
    return customDir;
  }

  /// Muat seluruh frame (kombinasi bawaan + kustom buatan pengguna)
  static Future<List<Map<String, dynamic>>> loadAllFrames() async {
    final List<Map<String, dynamic>> all = List.from(defaultFrames);

    if (kIsWeb) return all;

    try {
      final file = File('${_getStorageDir().path}/$_configFile');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        for (final item in jsonList) {
          if (item is Map<String, dynamic>) {
            // Pastikan file gambar frame kustom masih ada di disk
            final path = item['image_path'] as String?;
            if (path != null && File(path).existsSync()) {
              all.add(item);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading custom frames: $e');
    }

    return all;
  }

  /// Tambah template frame baru dari desain pengguna (file PNG)
  static Future<Map<String, dynamic>> addCustomFrame({
    required String name,
    required String sourceFilePath,
    required List<String> categories,
    String? backgroundColor,
    String layoutType = 'strip_vertical_3',
  }) async {
    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      throw Exception('File frame tidak ditemukan: $sourceFilePath');
    }

    // Salin file ke folder custom_frames agar permanen
    final framesDir = _getCustomFramesDir();
    final ext = sourceFilePath.split('.').last;
    final filename =
        'frame_${DateTime.now().millisecondsSinceEpoch}_${name.replaceAll(RegExp(r'\W+'), '_')}.$ext';
    final targetPath = '${framesDir.path}/$filename';

    await sourceFile.copy(targetPath);

    final newId = DateTime.now().millisecondsSinceEpoch;
    final newFrame = {
      'id': newId,
      'name': name,
      'image_path': targetPath,
      'layout_type': layoutType,
      'categories': categories.isNotEmpty ? categories : ['Custom Event'],
      'background_color': backgroundColor ?? '#FFFFFF',
      'is_custom': true,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Simpan ke custom_frames.json
    final file = File('${_getStorageDir().path}/$_configFile');
    List<dynamic> existingList = [];
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        existingList = jsonDecode(content);
      } catch (_) {}
    }

    existingList.add(newFrame);
    await file.writeAsString(jsonEncode(existingList));

    return newFrame;
  }

  /// Hapus template frame kustom
  static Future<bool> deleteCustomFrame(int id) async {
    try {
      final file = File('${_getStorageDir().path}/$_configFile');
      if (!await file.exists()) return false;

      final content = await file.readAsString();
      final List<dynamic> existingList = jsonDecode(content);

      final toRemove = existingList.firstWhere(
        (f) => f['id'] == id,
        orElse: () => null,
      );

      if (toRemove != null) {
        final path = toRemove['image_path'] as String?;
        if (path != null) {
          final imgFile = File(path);
          if (await imgFile.exists()) {
            await imgFile.delete();
          }
        }

        existingList.removeWhere((f) => f['id'] == id);
        await file.writeAsString(jsonEncode(existingList));
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting custom frame: $e');
    }
    return false;
  }

  /// Format Color dari string Hex (#RRGGBB)
  static Color parseHexColor(String? hexString, {Color defaultColor = Colors.white}) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    try {
      String formatted = hexString.replaceAll('#', '');
      if (formatted.length == 6) {
        formatted = 'FF$formatted';
      }
      return Color(int.parse(formatted, radix: 16));
    } catch (_) {
      return defaultColor;
    }
  }

  /// Konversi Color ke string Hex (#RRGGBB)
  static String toHexColor(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  // =========================================================================
  // KIOSK THEME & CUSTOM BACKGROUND SETTINGS
  // =========================================================================

  /// Ambil konfigurasi tema background tampilan booth
  static Future<Map<String, dynamic>> loadThemeSettings() async {
    final defaultSettings = {
      'theme_name': 'Default Teal & Peach',
      'custom_wallpaper_path': null,
      'primary_color': '#0F4C5C',
      'accent_color': '#F2A900',
    };

    if (kIsWeb) return defaultSettings;

    try {
      final file = File('${_getStorageDir().path}/$_themeConfigFile');
      if (await file.exists()) {
        final content = await file.readAsString();
        return Map<String, dynamic>.from(jsonDecode(content));
      }
    } catch (e) {
      debugPrint('Error reading theme settings: $e');
    }

    return defaultSettings;
  }

  /// Simpan konfigurasi tema background tampilan booth
  static Future<void> saveThemeSettings(Map<String, dynamic> settings) async {
    if (kIsWeb) return;
    try {
      final file = File('${_getStorageDir().path}/$_themeConfigFile');
      await file.writeAsString(jsonEncode(settings));
    } catch (e) {
      debugPrint('Error saving theme settings: $e');
    }
  }
}
