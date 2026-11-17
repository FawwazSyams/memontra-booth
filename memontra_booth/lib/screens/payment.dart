import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'countdown_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String sessionId;
  final String layoutType;
  final String frameImagePath;

  const PaymentScreen({
    super.key,
    required this.sessionId,
    required this.layoutType,
    required this.frameImagePath,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // =========================================================================
  // KONFIGURASI PEMBAYARAN MANUAL
  // (Ubah nomor rekening & nama pemilik sesuai rekening resmi Memontra)
  // =========================================================================
  static const String _bankName = 'Seabank';
  static const String _accountNumber = '901305262029';
  static const String _accountHolder = 'Ulfah Nur Fazri';
  static const String _totalPrice = 'Rp 25.000';

  bool _isPaid = false;
  Timer? _sessionTimer;
  int _secondsRemaining = 300; // 5 menit waktu sesi pembayaran stand

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _onPaymentSuccess() {
    if (_isPaid) return;
    setState(() {
      _isPaid = true;
    });

    _sessionTimer?.cancel();

    // Berikan feedback visual sukses sejenak sebelum berpindah ke countdown kamera
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _goToCountdown();
      }
    });
  }

  void _goToCountdown() {
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
  }

  void _copyAccountNumber() {
    Clipboard.setData(const ClipboardData(text: _accountNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Nomor rekening berhasil disalin!'),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 28),
        actionsPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppTheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Konfirmasi Petugas Stand',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pastikan pelanggan telah melakukan transfer atau pembayaran tunai dan menunjukkan bukti yang valid kepada Anda.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgPeach.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.buttonPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Nominal Diterima:',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _totalPrice,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Cek Lagi / Batal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _onPaymentSuccess();
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: const Text(
              'Ya, Sudah Bayar & Lanjutkan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
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
                  // Top Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          _sessionTimer?.cancel();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text(
                          'KEMBALI',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ).animate().fadeIn(),

                      // Timer & Sesi Info pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Waktu: ${_formatTimer(_secondsRemaining)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Center Card
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 620),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 32,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F4C5C).withValues(alpha: 0.08),
                                blurRadius: 28,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _isPaid
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.success,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                    ).animate().scale(
                                          duration: 300.ms,
                                          curve: Curves.easeOutBack,
                                        ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Pembayaran Berhasil!',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Menyiapkan kamera photobooth...',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Header Icon
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_rounded,
                                        color: AppTheme.primary,
                                        size: 36,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Title
                                    const Text(
                                      'Pembayaran di Stand',
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Transfer ke rekening pemilik Memontra atau bayar langsung ke petugas stand',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Price Tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.bgPeach.withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppTheme.buttonPrimary.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.receipt_long_rounded,
                                            color: AppTheme.textDark,
                                            size: 22,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Total Biaya: ',
                                            style: TextStyle(
                                              fontSize: 17,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                          Text(
                                            _totalPrice,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Bank Transfer Card
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F8F8),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.primary.withValues(alpha: 0.22),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.primary,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Text(
                                                      _bankName,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  const Text(
                                                    'Transfer Bank',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.textDark,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              TextButton.icon(
                                                onPressed: _copyAccountNumber,
                                                icon: const Icon(Icons.copy_rounded, size: 16),
                                                label: const Text(
                                                  'Salin No. Rekening',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: AppTheme.primary,
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Text(
                                                'No. Rekening: ',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              SelectableText(
                                                _accountNumber,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1.2,
                                                  color: AppTheme.textDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: const [
                                              Text(
                                                'Atas Nama: ',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              Text(
                                                _accountHolder,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // 3 Petunjuk Singkat
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          _buildStepRow(
                                            stepNumber: '1',
                                            text: 'Transfer ke rekening di atas atau serahkan uang tunai ke penjaga stand.',
                                          ),
                                          const SizedBox(height: 8),
                                          _buildStepRow(
                                            stepNumber: '2',
                                            text: 'Tunjukkan bukti transfer / pembayaran kepada penjaga stand.',
                                          ),
                                          const SizedBox(height: 8),
                                          _buildStepRow(
                                            stepNumber: '3',
                                            text: 'Petugas stand akan menekan tombol "Lanjutkan" untuk memulai foto!',
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 26),

                                    // Tombol LANJUTKAN untuk Petugas Stand
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton.icon(
                                        onPressed: _showConfirmationDialog,
                                        icon: const Icon(
                                          Icons.check_circle_rounded,
                                          size: 24,
                                        ),
                                        label: const Text(
                                          'LANJUTKAN (SUDAH BAYAR)',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.buttonPrimary,
                                          foregroundColor: Colors.white,
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    // Helper Text Petugas
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 15,
                                          color: Colors.black45,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Petugas: Periksa bukti transfer pelanggan sebelum menekan tombol',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      ),
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

  Widget _buildStepRow({required String stepNumber, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            stepNumber,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
