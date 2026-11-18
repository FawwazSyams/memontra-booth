import 'dart:io';
import 'package:flutter/material.dart';
import '../services/frame_service.dart';
import '../theme/app_theme.dart';

class AddFrameDialog extends StatefulWidget {
  const AddFrameDialog({super.key});

  @override
  State<AddFrameDialog> createState() => _AddFrameDialogState();
}

class _AddFrameDialogState extends State<AddFrameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pathController = TextEditingController();
  final _hexColorController = TextEditingController(text: '#FFFFFF');

  final List<String> _availableCategories = [
    'Most Used',
    'Classic',
    'Vintage',
    'Trendy',
    'Cute & Fun',
    'Custom Event',
  ];

  final Set<String> _selectedCategories = {'Custom Event', 'Most Used'};

  // Preset warna background strip
  final List<Map<String, dynamic>> _presetColors = [
    {'name': 'Putih Bersih', 'hex': '#FFFFFF', 'color': Colors.white},
    {'name': 'Hitam Pekat', 'hex': '#000000', 'color': Colors.black},
    {'name': 'Cream Hangat', 'hex': '#FFF8EE', 'color': Color(0xFFFFF8EE)},
    {'name': 'Navy Gelap', 'hex': '#07101E', 'color': Color(0xFF07101E)},
    {'name': 'Peach Lembut', 'hex': '#FDE8E1', 'color': Color(0xFFFDE8E1)},
    {'name': 'Teal Anggun', 'hex': '#0F4C5C', 'color': Color(0xFF0F4C5C)},
    {'name': 'Emas Mewah', 'hex': '#F2A900', 'color': Color(0xFFF2A900)},
  ];

  Color _selectedBgColor = Colors.white;
  bool _isSaving = false;
  String? _previewImagePath;

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    _hexColorController.dispose();
    super.dispose();
  }

  void _onPathChanged(String value) {
    final cleanPath = value.trim().replaceAll('"', '').replaceAll("'", '');
    if (cleanPath.isNotEmpty && File(cleanPath).existsSync()) {
      setState(() {
        _previewImagePath = cleanPath;
      });
    } else {
      setState(() {
        _previewImagePath = null;
      });
    }
  }

  Future<void> _saveFrame() async {
    if (!_formKey.currentState!.validate()) return;

    final cleanPath =
        _pathController.text.trim().replaceAll('"', '').replaceAll("'", '');
    final file = File(cleanPath);

    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File gambar frame tidak ditemukan pada path tersebut.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newFrame = await FrameService.addCustomFrame(
        name: _nameController.text.trim(),
        sourceFilePath: cleanPath,
        categories: _selectedCategories.toList(),
        backgroundColor: FrameService.toHexColor(_selectedBgColor),
      );

      if (mounted) {
        Navigator.pop(context, newFrame);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan frame: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(32),
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
                    Icons.auto_awesome_rounded,
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
                        'Tambah Template Frame Baru',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Masukkan desain frame PNG transparan & pilih custom background',
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

            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form Fields (Left)
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Nama Frame
                            const Text(
                              'Nama Template Frame:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Contoh: Wedding Kevin & Sarah',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Nama frame wajib diisi';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // 2. Path File Frame
                            const Text(
                              'Lokasi File Frame PNG (1200x3600 px):',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _pathController,
                              onChanged: _onPathChanged,
                              decoration: InputDecoration(
                                hintText: 'Contoh: C:\\Desain\\frame_wedding.png',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                prefixIcon: const Icon(Icons.image_outlined),
                                helperText:
                                    'Salin path file PNG transparan dari Windows Explorer',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Path file frame wajib diisi';
                                }
                                final f = File(val.trim().replaceAll('"', ''));
                                if (!f.existsSync()) {
                                  return 'File tidak ditemukan di komputer Anda';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // 3. Custom Background Strip
                            const Text(
                              'Warna Background Strip (Di bawah frame):',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Preset color swatches
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _presetColors.map((preset) {
                                final isSelected =
                                    _selectedBgColor == preset['color'];
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedBgColor = preset['color'];
                                      _hexColorController.text = preset['hex'];
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: preset['color'],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primary
                                            : Colors.grey.shade400,
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: preset['color'],
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.black26,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          preset['name'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: preset['color'] == Colors.black ||
                                                    preset['color'] ==
                                                        const Color(0xFF07101E) ||
                                                    preset['color'] ==
                                                        const Color(0xFF0F4C5C)
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 16),

                            // 4. Kategori Frame
                            const Text(
                              'Kategori Frame:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: _availableCategories.map((cat) {
                                final isSelected =
                                    _selectedCategories.contains(cat);
                                return FilterChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedCategories.add(cat);
                                      } else {
                                        if (_selectedCategories.length > 1) {
                                          _selectedCategories.remove(cat);
                                        }
                                      }
                                    });
                                  },
                                  selectedColor:
                                      AppTheme.primary.withValues(alpha: 0.18),
                                  checkmarkColor: AppTheme.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.textDark,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Preview Box (Right)
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Live Preview Frame:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),

                            Container(
                              height: 380,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: _selectedBgColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade400),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _previewImagePath != null
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // Background Color Layer
                                        Container(color: _selectedBgColor),
                                        // Sample Mock Photos Behind Cutouts
                                        Column(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                margin: const EdgeInsets.all(12),
                                                color: Colors.grey.shade300,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                margin: const EdgeInsets.all(12),
                                                color: Colors.grey.shade300,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                margin: const EdgeInsets.all(12),
                                                color: Colors.grey.shade300,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Frame Overlay
                                        Image.file(
                                          File(_previewImagePath!),
                                          fit: BoxFit.contain,
                                          errorBuilder: (ctx, err, st) =>
                                              const Center(
                                            child: Text('Gagal muat gambar'),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(
                                              Icons.add_photo_alternate_outlined,
                                              size: 48,
                                              color: Colors.black38,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Ketik path gambar PNG di sebelah kiri untuk melihat preview',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black45,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Footer Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 14),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveFrame,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    _isSaving ? 'Menyimpan...' : 'Simpan Template Frame',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.buttonPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
