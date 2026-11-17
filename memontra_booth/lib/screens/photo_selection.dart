import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';
import 'countdown_screen.dart';
import 'review.dart';

class PhotoSelectionScreen extends StatefulWidget {
  final String sessionId;
  final String layoutType;
  final String frameImagePath;
  final List<XFile> allPhotos;

  const PhotoSelectionScreen({
    super.key,
    required this.sessionId,
    required this.layoutType,
    required this.frameImagePath,
    required this.allPhotos,
  });

  @override
  State<PhotoSelectionScreen> createState() => _PhotoSelectionScreenState();
}

class _PhotoSelectionScreenState extends State<PhotoSelectionScreen> {
  // 3 Slot Foto Frame (Awalnya kosong, user bebas memilih sendiri)
  final List<XFile?> _slots = [null, null, null];

  // Active Timer (60s countdown)
  int _secondsRemaining = 60;
  Timer? _countdownTimer;

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
          _onTimeExpired();
        }
      });
    });
  }

  void _onTimeExpired() {
    // Jika waktu habis dan belum semua slot terisi, otomatis isi dari foto yang belum dipakai
    for (int i = 0; i < 3; i++) {
      if (_slots[i] == null) {
        for (final photo in widget.allPhotos) {
          if (!_slots.contains(photo)) {
            _slots[i] = photo;
            break;
          }
        }
      }
    }

    if (_slots.every((p) => p != null)) {
      _goToReview();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  int get _filledCount => _slots.whereType<XFile>().length;

  int? _getSlotIndexForPhoto(XFile photo) {
    final idx = _slots.indexOf(photo);
    return idx == -1 ? null : idx;
  }

  void _assignPhotoToSlot(int slotIndex, XFile photo) {
    setState(() {
      // Jika foto ini sudah ada di slot lain, kosongkan slot lamanya (swap / move)
      final existingSlot = _slots.indexOf(photo);
      if (existingSlot != -1 && existingSlot != slotIndex) {
        _slots[existingSlot] = _slots[slotIndex];
      }
      _slots[slotIndex] = photo;
    });
  }

  void _clearSlot(int slotIndex) {
    setState(() {
      _slots[slotIndex] = null;
    });
  }

  void _onPhotoTapped(XFile photo) {
    final existingSlot = _getSlotIndexForPhoto(photo);
    if (existingSlot != null) {
      // Jika sudah di slot, tap untuk melepasnya
      _clearSlot(existingSlot);
    } else {
      // Jika belum di slot, masukkan ke slot kosong pertama
      final firstEmpty = _slots.indexOf(null);
      if (firstEmpty != -1) {
        _assignPhotoToSlot(firstEmpty, photo);
      }
    }
  }

  void _goToReview() {
    if (_slots.every((p) => p != null)) {
      _countdownTimer?.cancel();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewScreen(
            sessionId: widget.sessionId,
            layoutType: widget.layoutType,
            frameImagePath: widget.frameImagePath,
            photos: _slots.cast<XFile>(),
            allPhotos: widget.allPhotos,
          ),
        ),
      );
    }
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _getSlotTitle(int index) {
    switch (index) {
      case 0:
        return 'Slot 1 (Atas)';
      case 1:
        return 'Slot 2 (Tengah)';
      case 2:
        return 'Slot 3 (Bawah)';
      default:
        return 'Slot ${index + 1}';
    }
  }

  Widget _buildPhotoThumbnail(XFile photo, {BoxFit fit = BoxFit.cover}) {
    return kIsWeb
        ? Image.network(photo.path, fit: fit)
        : Image.file(File(photo.path), fit: fit);
  }

  // Widget Slot DragTarget di dalam Frame Strip
  Widget _buildFrameSlot(int slotIndex) {
    final photo = _slots[slotIndex];

    return DragTarget<XFile>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => _assignPhotoToSlot(slotIndex, details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        if (photo != null) {
          // Slot sudah terisi foto (juga bisa di-drag untuk swap)
          return Draggable<XFile>(
            data: photo,
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: 140,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildPhotoThumbnail(photo),
                ),
              ),
            ),
            childWhenDragging: Container(
              color: AppTheme.primary.withValues(alpha: 0.15),
              child: const Center(
                child: Icon(Icons.swap_vert_rounded, color: AppTheme.primary, size: 32),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPhotoThumbnail(photo),

                // Tombol Hapus (Silang)
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _clearSlot(slotIndex),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.65),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),

                // Label nomor slot di kiri bawah foto
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${slotIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Slot Masih Kosong: Tampilan Dropzone yang menarik
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHovered
                ? AppTheme.primary.withValues(alpha: 0.22)
                : const Color(0xFFF1F5F9),
            border: Border.all(
              color: isHovered ? AppTheme.primary : const Color(0xFFCBD5E1),
              width: isHovered ? 3 : 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isHovered
                    ? Icons.file_download_rounded
                    : Icons.add_photo_alternate_outlined,
                color: isHovered ? AppTheme.primary : AppTheme.textDark.withValues(alpha: 0.5),
                size: isHovered ? 36 : 28,
              ),
              const SizedBox(height: 4),
              Text(
                _getSlotTitle(slotIndex),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isHovered ? AppTheme.primary : AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isHovered ? 'Lepaskan di sini!' : 'Tarik atau sentuh foto',
                style: TextStyle(
                  fontSize: 11,
                  color: isHovered
                      ? AppTheme.primary
                      : AppTheme.textDark.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Panel Kiri: Frame Strip Lengkap dengan 3 Slot DragTarget
  Widget _buildInteractiveStripFrame() {
    return Container(
      width: 250,
      height: 700,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4C5C).withValues(alpha: 0.15),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Slot 0 (Atas)
            Positioned(
              top: 20,
              left: 15,
              width: 220,
              height: 180,
              child: _buildFrameSlot(0),
            ),

            // Slot 1 (Tengah)
            Positioned(
              top: 220,
              left: 15,
              width: 220,
              height: 180,
              child: _buildFrameSlot(1),
            ),

            // Slot 2 (Bawah)
            Positioned(
              top: 420,
              left: 15,
              width: 220,
              height: 180,
              child: _buildFrameSlot(2),
            ),

            // Frame Image Graphic Overlay (IgnorePointer agar gesture drop tembus ke slot)
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  widget.frameImagePath,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
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
              child: Column(
                children: [
                  // Top Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          _countdownTimer?.cancel();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CountdownScreen(
                                sessionId: widget.sessionId,
                                layoutType: widget.layoutType,
                                frameImagePath: widget.frameImagePath,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text(
                          'FOTO ULANG',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ).animate().fadeIn(),

                      Column(
                        children: [
                          const Text(
                            'Susun Foto ke Frame',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tarik (drag) foto ke slot di kiri, atau ketuk foto untuk memasukkan',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textDark.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ).animate().fadeIn().slideY(begin: -0.15),

                      // Functional Timer Pill
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
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

                  // Main Content Area: Kiri Frame, Kanan Grid Foto
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // KIRI: Frame Interaktif dengan 3 Slot DragTarget
                        Expanded(
                          flex: 4,
                          child: Center(
                            child: SizedBox(
                              height: 590,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: _buildInteractiveStripFrame(),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 32),

                        // KANAN: Koleksi Foto Hasil Sesi yang Bisa di-Drag
                        Expanded(
                          flex: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F4C5C).withValues(alpha: 0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.photo_library_rounded,
                                          color: AppTheme.primary,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Koleksi Foto Sesi Ini (${widget.allPhotos.length} foto)',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _filledCount == 3
                                            ? AppTheme.success.withValues(alpha: 0.15)
                                            : AppTheme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Terisi: $_filledCount / 3 Slot',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _filledCount == 3
                                              ? AppTheme.success
                                              : AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                // Grid Foto
                                Expanded(
                                  child: widget.allPhotos.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'Tidak ada foto terambil.',
                                            style: TextStyle(color: AppTheme.textDark),
                                          ),
                                        )
                                      : GridView.builder(
                                          physics: const BouncingScrollPhysics(),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                            childAspectRatio: 0.85,
                                          ),
                                          itemCount: widget.allPhotos.length,
                                          itemBuilder: (context, index) {
                                            final photo = widget.allPhotos[index];
                                            final slotIndex = _getSlotIndexForPhoto(photo);
                                            final isAssigned = slotIndex != null;

                                            return Draggable<XFile>(
                                              data: photo,
                                              feedback: Material(
                                                color: Colors.transparent,
                                                child: Container(
                                                  width: 150,
                                                  height: 120,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(14),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.4),
                                                        blurRadius: 20,
                                                        offset: const Offset(0, 8),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(14),
                                                    child: _buildPhotoThumbnail(photo),
                                                  ),
                                                ),
                                              ),
                                              childWhenDragging: Opacity(
                                                opacity: 0.35,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                ),
                                              ),
                                              child: GestureDetector(
                                                onTap: () => _onPhotoTapped(photo),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(
                                                      color: isAssigned
                                                          ? AppTheme.primary
                                                          : Colors.transparent,
                                                      width: isAssigned ? 4 : 1,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: isAssigned
                                                            ? AppTheme.primary.withValues(alpha: 0.25)
                                                            : Colors.black.withValues(alpha: 0.08),
                                                        blurRadius: isAssigned ? 12 : 6,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius: BorderRadius.circular(12),
                                                        child: _buildPhotoThumbnail(photo),
                                                      ),

                                                      // Badge jika sudah masuk ke slot tertentu
                                                      if (isAssigned) ...[
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            color: AppTheme.primary.withValues(alpha: 0.25),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          top: 8,
                                                          right: 8,
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: AppTheme.primary,
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            child: Text(
                                                              'Slot #${slotIndex + 1}',
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bottom Action Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _filledCount == 3
                            ? 'Semua 3 slot terisi! Ketuk "LANJUT KE FILTER" untuk melanjutkan'
                            : 'Isi semua 3 slot frame (${3 - _filledCount} slot lagi)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _filledCount == 3
                              ? AppTheme.success
                              : AppTheme.textDark,
                        ),
                      ),

                      ElevatedButton.icon(
                        onPressed: _filledCount == 3 ? _goToReview : null,
                        icon: const Text(
                          'LANJUT KE FILTER',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        label: const Icon(Icons.arrow_forward_rounded),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 18,
                          ),
                          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                          disabledForegroundColor: Colors.grey[600],
                        ),
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
