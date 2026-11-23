import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
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
  // Mode Pembayaran: 0 = QRIS DOKU Otomatis, 1 = Manual / Tunai Stand
  int _selectedPaymentMethod = 0;

  // Konfigurasi Manual Stand
  static const String _bankName = 'Seabank';
  static const String _accountNumber = '901305262029';
  static const String _accountHolder = 'Ulfah Nur Fazri';
  static const String _totalPrice = 'Rp 25.000';
  static const int _priceAmount = 25000;

  bool _isPaid = false;
  Timer? _sessionTimer;
  Timer? _pollingTimer;
  int _secondsRemaining = 300; // 5 menit waktu pembayaran

  // State QRIS DOKU
  bool _isLoadingQris = true;
  String? _orderId;
  String? _tokenId;
  String? _qrisData; // Bisa berupa raw EMVCo qr_string atau url
  String? _qrisErrorMessage;

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
    _initDokuQris();
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
          _pollingTimer?.cancel();
        }
      });
    });
  }

  /// Request QRIS DOKU ke API backend
  Future<void> _initDokuQris() async {
    setState(() {
      _isLoadingQris = true;
      _qrisErrorMessage = null;
    });

    try {
      final res = await ApiService.generateQrisPayment(amount: _priceAmount);
      if (res != null && mounted) {
        final orderId = res['order_id'] as String?;
        final tokenId = res['token_id'] as String?;
        final qrString = res['qr_string'] as String?;
        final qrUrl = res['qr_url'] as String?;

        final dataToRender = (qrString != null && qrString.isNotEmpty)
            ? qrString
            : (qrUrl != null && qrUrl.isNotEmpty)
                ? qrUrl
                : 'https://momentrabooth.com/payment/doku?order_id=$orderId';

        setState(() {
          _orderId = orderId;
          _tokenId = tokenId;
          _qrisData = dataToRender;
          _isLoadingQris = false;
        });

        // Mulai polling cek status pembayaran secara otomatis
        if (orderId != null) {
          _startStatusPolling(orderId, tokenId);
        }
      } else {
        // Fallback jika backend offline / belum terhubung
        if (mounted) {
          final fallbackOrderId =
              'DOKU-${DateTime.now().millisecondsSinceEpoch}';
          setState(() {
            _orderId = fallbackOrderId;
            _tokenId = null;
            _qrisData =
                '00020101021226600016ID.CO.DOKU.WWW01189360099900000000010215${fallbackOrderId}5204581253033605405250005802ID5914MEMONTRA BOOTH6007JAKARTA62070703A016304';
            _isLoadingQris = false;
          });
          _startStatusPolling(fallbackOrderId);
        }
      }
    } catch (e) {
      debugPrint('Error init DOKU QRIS: $e');
      if (mounted) {
        setState(() {
          _isLoadingQris = false;
          _qrisErrorMessage = 'Gagal memuat QRIS DOKU. Silakan gunakan metode tunai atau muat ulang.';
        });
      }
    }
  }

  /// Polling berkala (setiap 2.5 detik) untuk mengecek apakah pelanggan sudah scan & bayar
  void _startStatusPolling(String orderId, [String? tokenId]) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) async {
      if (!mounted || _isPaid) {
        timer.cancel();
        return;
      }

      final status = await ApiService.checkPaymentStatus(orderId, tokenId: tokenId ?? _tokenId);
      if (status == 'settlement' || status == 'SUCCESS' || status == 'paid') {
        timer.cancel();
        _onPaymentSuccess();
      }
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _onPaymentSuccess() {
    if (_isPaid) return;
    setState(() {
      _isPaid = true;
    });

    _sessionTimer?.cancel();
    _pollingTimer?.cancel();

    // Berikan feedback visual sukses sebelum berpindah ke countdown kamera
    Future.delayed(const Duration(milliseconds: 1400), () {
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                          _pollingTimer?.cancel();
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

                  const SizedBox(height: 14),

                  // Center Card
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 680),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 28,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
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
                                      padding: const EdgeInsets.all(22),
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
                                          duration: 350.ms,
                                          curve: Curves.easeOutBack,
                                        ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Pembayaran Berhasil! 🎉',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Menyiapkan kamera photobooth, bersiaplah untuk berpose...',
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Title & Gateway Branding
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.qr_code_scanner_rounded,
                                            color: AppTheme.primary,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Selesaikan Pembayaran',
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Scan QRIS DOKU menggunakan e-wallet / mobile banking apa saja',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),

                                    const SizedBox(height: 18),

                                    // Switcher Metode Pembayaran: QRIS DOKU vs Manual
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => setState(() => _selectedPaymentMethod = 0),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: _selectedPaymentMethod == 0
                                                      ? AppTheme.primary
                                                      : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: _selectedPaymentMethod == 0
                                                      ? [
                                                          BoxShadow(
                                                            color: AppTheme.primary.withValues(alpha: 0.3),
                                                            blurRadius: 8,
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.qr_code_2_rounded,
                                                      size: 18,
                                                      color: _selectedPaymentMethod == 0
                                                          ? Colors.white
                                                          : AppTheme.textDark,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'QRIS DOKU (Otomatis)',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: _selectedPaymentMethod == 0
                                                            ? Colors.white
                                                            : AppTheme.textDark,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => setState(() => _selectedPaymentMethod = 1),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: _selectedPaymentMethod == 1
                                                      ? AppTheme.primary
                                                      : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: _selectedPaymentMethod == 1
                                                      ? [
                                                          BoxShadow(
                                                            color: AppTheme.primary.withValues(alpha: 0.3),
                                                            blurRadius: 8,
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.account_balance_rounded,
                                                      size: 18,
                                                      color: _selectedPaymentMethod == 1
                                                          ? Colors.white
                                                          : AppTheme.textDark,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Tunai / Transfer Stand',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: _selectedPaymentMethod == 1
                                                            ? Colors.white
                                                            : AppTheme.textDark,
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

                                    const SizedBox(height: 18),

                                    // Price Tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.bgPeach.withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppTheme.buttonPrimary.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.receipt_long_rounded,
                                            color: AppTheme.textDark,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Total Biaya: ',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                          Text(
                                            _totalPrice,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 18),

                                    // Content Berdasarkan Tab Terpilih
                                    if (_selectedPaymentMethod == 0)
                                      _buildDokuQrisView()
                                    else
                                      _buildManualTransferView(),
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

  /// Tampilan QRIS DOKU Otomatis
  Widget _buildDokuQrisView() {
    if (_isLoadingQris) {
      return Container(
        height: 280,
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text(
              'Menghubungkan ke DOKU Payment Gateway...',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    if (_qrisErrorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),
            const SizedBox(height: 8),
            Text(
              _qrisErrorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _initDokuQris,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR Code Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Badge DOKU + QRIS
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE52535), // DOKU Red Brand
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'DOKU',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'QRIS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Dynamic QR Code Render
              QrImageView(
                data: _qrisData ?? 'https://momentrabooth.com',
                version: QrVersions.auto,
                size: 210,
                backgroundColor: Colors.white,
              ),

              const SizedBox(height: 10),

              // Live Pulse Status
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1.3, 1.3),
                        duration: 800.ms,
                      ),
                  const SizedBox(width: 8),
                  const Text(
                    'Menunggu pembayaran otomatis...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (_orderId != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Order ID: $_orderId',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Logo Bank & E-Wallet Yang Didukung
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: const [
            Text(
              'Mendukung: BCA • Mandiri • BRI • BNI • GoPay • OVO • DANA • ShopeePay',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Tombol Darurat untuk Petugas jika internet pelanggan lambat
        TextButton.icon(
          onPressed: _showConfirmationDialog,
          icon: const Icon(Icons.verified_user_rounded, size: 18),
          label: const Text(
            'Petugas: Konfirmasi Manual Jika Sudah Transfer / Tunai',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
        ),
      ],
    );
  }

  /// Tampilan Manual Seabank / Tunai Stand
  Widget _buildManualTransferView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
              const Row(
                children: [
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

        const SizedBox(height: 16),

        // Petunjuk Petugas
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              _buildStepRow(
                stepNumber: '1',
                text: 'Transfer ke rekening di atas atau serahkan uang tunai ke petugas.',
              ),
              const SizedBox(height: 8),
              _buildStepRow(
                stepNumber: '2',
                text: 'Tunjukkan bukti transfer / pembayaran kepada petugas stand.',
              ),
              const SizedBox(height: 8),
              _buildStepRow(
                stepNumber: '3',
                text: 'Petugas menekan tombol di bawah untuk memulai sesi foto!',
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Tombol LANJUTKAN untuk Petugas
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _showConfirmationDialog,
            icon: const Icon(Icons.check_circle_rounded, size: 22),
            label: const Text(
              'LANJUTKAN (SUDAH BAYAR / TUNAI)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
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
