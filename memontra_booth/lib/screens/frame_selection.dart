import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'payment.dart';

class FrameSelectionScreen extends StatefulWidget {
  final String sessionId;
  const FrameSelectionScreen({super.key, required this.sessionId});

  @override
  State<FrameSelectionScreen> createState() => _FrameSelectionScreenState();
}

class _FrameSelectionScreenState extends State<FrameSelectionScreen> {
  final List<Map<String, dynamic>> _allFrames = [
    {
      'id': 1,
      'name': 'Deep Blue Stars',
      'image_path': 'assets/frames/strip1.png',
      'layout_type': 'strip_vertical_3',
      'categories': ['Most Used', 'Classic', 'Trendy'],
    },
    {
      'id': 2,
      'name': 'White Elegance',
      'image_path': 'assets/frames/strip2.png',
      'layout_type': 'strip_vertical_3',
      'categories': ['Most Used', 'Classic', 'Cute & Fun'],
    },
    {
      'id': 3,
      'name': 'Golden Sunset',
      'image_path': 'assets/frames/strip3.png',
      'layout_type': 'strip_vertical_3',
      'categories': ['Most Used', 'Vintage', 'Trendy'],
    },
    {
      'id': 4,
      'name': 'Vintage Retro',
      'image_path': 'assets/frames/strip1.png',
      'layout_type': 'strip_vertical_3',
      'categories': ['Vintage', 'Cute & Fun'],
    },
  ];

  final List<String> _categories = [
    'Most Used',
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

  // Active Timer (60s countdown)
  int _secondsRemaining = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    if (_allFrames.isNotEmpty) {
      _setSelection(_allFrames[0]);
    }
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
    });
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

                      // Functional Countdown Timer
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
                            child: displayedFrames.isEmpty
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
                                                  child: Image.asset(
                                                    frame['image_path'],
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context, error, stackTrace) =>
                                                        Container(
                                                      color: Colors.grey[200],
                                                      child: const Center(
                                                        child: Icon(Icons.image, size: 40),
                                                      ),
                                                    ),
                                                  ),
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
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: Image.asset(
                                            _selectedImagePath!,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Container(
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: Text('Preview'),
                                              ),
                                            ),
                                          ),
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
