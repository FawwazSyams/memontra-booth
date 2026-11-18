import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/add_frame_dialog.dart';
import '../services/frame_service.dart';
import 'payment.dart';

class FrameSelectionScreen extends StatefulWidget {
  final String sessionId;
  const FrameSelectionScreen({super.key, required this.sessionId});

  @override
  State<FrameSelectionScreen> createState() => _FrameSelectionScreenState();
}

class _FrameSelectionScreenState extends State<FrameSelectionScreen> {
  List<Map<String, dynamic>> _allFrames = [];
  bool _isLoadingFrames = true;

  final List<String> _categories = [
    'Most Used',
    'Custom Event',
    'Classic',
    'Vintage',
    'Trendy',
    'Cute & Fun',
  ];

  int _selectedCategoryIndex = 0;
  int? _selectedFrameId;
  String? _selectedLayoutType;
  String? _selectedImagePath;
  String? _selectedFrameName;
  Color? _selectedBackgroundColor;

  // Active Timer (60s countdown)
  int _secondsRemaining = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadFrames();
    _startTimer();
  }

  Future<void> _loadFrames() async {
    final frames = await FrameService.loadAllFrames();
    if (mounted) {
      setState(() {
        _allFrames = frames;
        _isLoadingFrames = false;
        if (_allFrames.isNotEmpty && _selectedFrameId == null) {
          _setSelection(_allFrames[0]);
        }
      });
    }
  }

  Future<void> _openAddFrameDialog() async {
    _countdownTimer?.cancel();
    final newFrame = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AddFrameDialog(),
    );

    if (newFrame != null) {
      await _loadFrames();
      setState(() {
        _setSelection(newFrame);
        _selectedCategoryIndex = _categories.indexOf('Custom Event');
        if (_selectedCategoryIndex == -1) _selectedCategoryIndex = 0;
      });
    }

    _startTimer();
  }

  Future<void> _deleteFrame(Map<String, dynamic> frame) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Frame Kustom?'),
        content: Text('Apakah Anda yakin ingin menghapus "${frame['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FrameService.deleteCustomFrame(frame['id'] as int);
      await _loadFrames();
    }
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
          _goToNext();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredFrames {
    final selectedCat = _categories[_selectedCategoryIndex];
    if (selectedCat == 'Most Used') {
      return _allFrames;
    }
    return _allFrames.where((f) {
      final cats = f['categories'] as List<String>;
      return cats.contains(selectedCat);
    }).toList();
  }

  void _setSelection(Map<String, dynamic> frame) {
    setState(() {
      _selectedFrameId = frame['id'] as int;
      _selectedLayoutType = frame['layout_type'] as String;
      _selectedImagePath = frame['image_path'] as String;
      _selectedFrameName = frame['name'] as String;
      _selectedBackgroundColor =
          FrameService.parseHexColor(frame['background_color'] as String?);
    });
  }

  Widget _buildFrameImage(String path, {BoxFit fit = BoxFit.contain}) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (ctx, err, st) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.broken_image, size: 40)),
        ),
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (ctx, err, st) => Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.broken_image, size: 40)),
      ),
    );
  }

  void _goToNext() {
    if (_selectedFrameId == null) return;
    _countdownTimer?.cancel();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          sessionId: widget.sessionId,
          layoutType: _selectedLayoutType!,
          frameImagePath: _selectedImagePath!,
        ),
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
    final displayedFrames = _filteredFrames;

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
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 28.0),
              child: Column(
                children: [
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          _countdownTimer?.cancel();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: AppTheme.textDark,
                        iconSize: 26,
                        tooltip: 'Kembali',
                      ),

                      Column(
                        children: const [
                          Text(
                            'Pick Your Template',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pilih frame favorit untuk foto strip kamu',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ).animate().fadeIn().slideY(begin: -0.15),

                      // Functional Countdown Timer & Add Frame Button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _openAddFrameDialog,
                            icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                            label: const Text(
                              'TAMBAH FRAME',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.buttonPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                          ).animate().fadeIn(),

                          const SizedBox(width: 14),

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
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                ),
                              ],
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
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Main Content Area
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Categories Sidebar
                        Container(
                          width: 210,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F4C5C).withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _categories.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final isSelected = index == _selectedCategoryIndex;
                              final catName = _categories[index];

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryIndex = index;
                                    // If current selection is not in filtered list, auto-select first
                                    final currentFiltered = _filteredFrames;
                                    if (currentFiltered.isNotEmpty &&
                                        !currentFiltered.any((f) => f['id'] == _selectedFrameId)) {
                                      _setSelection(currentFiltered.first);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.bgPeach.withValues(alpha: 0.6)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    border: isSelected
                                        ? Border.all(
                                            color: AppTheme.buttonPrimary.withValues(alpha: 0.4),
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        catName,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? AppTheme.textDark
                                              : AppTheme.textDark.withValues(alpha: 0.75),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 18,
                                          color: AppTheme.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ).animate().fadeIn(delay: 150.ms),

                        const SizedBox(width: 24),

                        // Frame Grid
                        Expanded(
                          flex: 5,
                          child: GlassCard(
                            padding: const EdgeInsets.all(20),
                            borderRadius: BorderRadius.circular(24),
                            child: _isLoadingFrames
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppTheme.primary,
                                    ),
                                  )
                                : displayedFrames.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Tidak ada frame di kategori ini.',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                      )
                                : GridView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.65,
                                    ),
                                    itemCount: displayedFrames.length,
                                    itemBuilder: (context, index) {
                                      final frame = displayedFrames[index];
                                      final isSelected =
                                          _selectedFrameId == frame['id'];

                                      return GestureDetector(
                                        onTap: () => _setSelection(frame),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
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
                                                    : Colors.black.withValues(alpha: 0.06),
                                                blurRadius: isSelected ? 14 : 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: _buildFrameImage(frame['image_path']),
                                                ),
                                              ),

                                              // Custom Frame Badge & Delete Button
                                              if (frame['is_custom'] == true)
                                                Positioned(
                                                  top: 8,
                                                  left: 8,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.primary,
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Text(
                                                          'KUSTOM',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      InkWell(
                                                        onTap: () => _deleteFrame(frame),
                                                        child: Container(
                                                          padding: const EdgeInsets.all(4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.red.withValues(alpha: 0.9),
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(
                                                            Icons.delete_outline_rounded,
                                                            color: Colors.white,
                                                            size: 14,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                              // Selected Checkmark Badge
                                              if (isSelected)
                                                Positioned(
                                                  top: 10,
                                                  right: 10,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: const BoxDecoration(
                                                      color: AppTheme.primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                  ).animate().scale(
                                                        duration: 150.ms,
                                                        curve: Curves.easeOutBack,
                                                      ),
                                                ),

                                              // Frame Name Label at bottom
                                              Positioned(
                                                bottom: 8,
                                                left: 8,
                                                right: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                    horizontal: 10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.95),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(
                                                      color: Colors.grey.withValues(alpha: 0.2),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    frame['name'],
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.w600,
                                                      color: AppTheme.textDark,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(width: 24),

                        // Right Preview
                        Expanded(
                          flex: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F4C5C).withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Preview Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.visibility_outlined,
                                      size: 20,
                                      color: AppTheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedFrameName ?? 'Live Preview',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgTeal.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '3 Poses • Vertical Strip',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Expanded(
                                  child: _selectedImagePath == null
                                      ? const Center(
                                          child: Text('Pilih salah satu frame'),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: _selectedBackgroundColor ?? Colors.white,
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: _buildFrameImage(_selectedImagePath!),
                                        ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 250.ms),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bottom Navigation Buttons
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
                          'BACK',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ).animate().fadeIn(),

                      ElevatedButton.icon(
                        onPressed: _goToNext,
                        icon: const Text(
                          'NEXT',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        label: const Icon(Icons.arrow_forward_rounded),
                      ).animate().fadeIn(),
                    ],
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
