import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';

class ApiService {
  static const String serverHost = 'https://momentrabooth.com';
  static const String baseUrl = '$serverHost/api/booth';
  static const String paymentUrl = '$serverHost/api/payment';

  /// Cek apakah backend server merespons
  static Future<bool> isServerOnline() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/event/active'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (_) {
      return false;
    }
  }

  /// Mulai sesi baru (online dengan event aktif, atau fallback offline yang aman)
  static Future<String> startSession() async {
    try {
      // 1. Coba dapatkan event aktif terlebih dahulu
      final eventResponse = await http
          .get(
            Uri.parse('$baseUrl/event/active'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 3));

      if (eventResponse.statusCode == 200) {
        final eventData = jsonDecode(eventResponse.body);
        final String eventId = eventData['id'].toString();

        // 2. Mulai sesi dengan event_id yang dinamis
        final response = await http
            .post(
              Uri.parse('$baseUrl/sessions'),
              headers: {'Accept': 'application/json'},
              body: {'event_id': eventId},
            )
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return data['data']['id'].toString();
        }
      }
    } catch (e) {
      debugPrint('API Booth Offline/Fallback: $e');
    }

    // Fallback: Jika server backend belum dinyalakan atau belum ada event,
    // generate session ID lokal yang valid agar operasional photobooth tetap lancar.
    final localSessionId =
        'MMT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    debugPrint('Menggunakan sesi lokal booth: $localSessionId');
    return localSessionId;
  }

  /// Upload Foto ke Laravel (menggunakan JSON Base64 anti-blokir firewall hosting)
  static Future<bool> uploadPhoto(
    String sessionId,
    XFile photo,
    int sequenceNumber,
  ) async {
    try {
      Uint8List bytes = await photo.readAsBytes();
      String base64Photo = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$baseUrl/sessions/$sessionId/photos'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'sequence_number': sequenceNumber,
          'photo_base64': base64Photo,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        debugPrint('Upload foto ke-$sequenceNumber sukses!');
        return true;
      } else {
        debugPrint(
          'Gagal upload foto ke-$sequenceNumber. Status: ${response.statusCode}, Body: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error upload API: $e');
      return false;
    }
  }

  /// Upload Hasil Foto Strip + Frame (Komposit Final) untuk Softfile Download
  static Future<bool> uploadStrip(String sessionId, Uint8List stripBytes) async {
    // 1. Coba upload via Multipart Form-Data (paling cepat & aman dari batas payload server)
    try {
      final uri = Uri.parse('$baseUrl/sessions/$sessionId/strip');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';
      request.fields['sequence_number'] = '0';
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          stripBytes,
          filename: 'strip_$sessionId.jpg',
        ),
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 25));
      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        debugPrint('Upload foto strip + frame via Multipart sukses!');
        return true;
      }
    } catch (e) {
      debugPrint('Multipart upload note: $e, beralih ke Base64 fallback');
    }

    // 2. Fallback: Base64 JSON ke /strip
    try {
      final base64Strip = base64Encode(stripBytes);
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/$sessionId/strip'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'sequence_number': 0,
          'photo_base64': base64Strip,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Upload foto strip via Base64 JSON sukses!');
        return true;
      }

      // 3. Fallback kedua: Base64 JSON ke /photos
      final fallbackResponse = await http.post(
        Uri.parse('$baseUrl/sessions/$sessionId/photos'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'sequence_number': 0,
          'photo_base64': base64Strip,
        }),
      ).timeout(const Duration(seconds: 25));

      return fallbackResponse.statusCode == 200 ||
          fallbackResponse.statusCode == 201;
    } catch (e) {
      debugPrint('Error upload foto strip komposit: $e');
      return false;
    }
  }

  /// Buat transaksi QRIS DOKU melalui backend
  static Future<Map<String, dynamic>?> generateQrisPayment({int amount = 25000}) async {
    try {
      final response = await http.post(
        Uri.parse('$paymentUrl/qris'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'gateway': 'doku',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return {
            'order_id': data['order_id'],
            'token_id': data['token_id'],
            'qr_string': data['qr_string'],
            'qr_url': data['qr_url'],
            'amount': data['amount'] ?? amount,
            'gateway': data['gateway'] ?? 'doku',
          };
        }
      }
    } catch (e) {
      debugPrint('Error request QRIS DOKU: $e');
    }
    return null;
  }

  /// Cek status pembayaran ke backend (Polling)
  static Future<String> checkPaymentStatus(String orderId, {String? tokenId}) async {
    try {
      final uriStr = tokenId != null && tokenId.isNotEmpty
          ? '$paymentUrl/status/$orderId?token_id=$tokenId'
          : '$paymentUrl/status/$orderId';

      final response = await http.get(
        Uri.parse(uriStr),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transaction_status'] ?? 'pending';
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
    }
    return 'pending';
  }
}
