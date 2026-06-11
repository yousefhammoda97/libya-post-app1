import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'session_manager.dart';

class ApiService {
  static String? _baseUrl;
  static String? _sessionCookie;

  static Future<void> _init() async {
    _baseUrl = await SessionManager.getBaseUrl();
    _sessionCookie = await SessionManager.getSessionCookie();
  }

  // ======= LOGIN =======
  static Future<Map<String, dynamic>> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    final url = '$baseUrl/login.php';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': username, 'password': password},
      ).timeout(const Duration(seconds: 20));

      // نأخذ الكوكيز من الاستجابة
      final cookies = response.headers['set-cookie'] ?? '';
      final sessionCookie = _extractSessionCookie(cookies);

      if (response.statusCode == 200 || response.statusCode == 302) {
        // نتحقق إذا كانت هناك إعادة توجيه لصفحة deliver.php
        final location = response.headers['location'] ?? '';
        if (location.contains('deliver') ||
            response.body.contains('تسليم البريد') ||
            response.body.contains('item_id')) {
          return {
            'success': true,
            'session_cookie': sessionCookie,
            'message': 'تم تسجيل الدخول بنجاح',
          };
        }
        // نتحقق من خطأ في تسجيل الدخول
        if (response.body.contains('خطأ') ||
            response.body.contains('error') ||
            response.body.contains('invalid')) {
          return {'success': false, 'message': 'اسم المستخدم أو كلمة المرور غير صحيحة'};
        }
        // في حالة كان لدينا كوكي صالح
        if (sessionCookie.isNotEmpty) {
          return {
            'success': true,
            'session_cookie': sessionCookie,
            'message': 'تم تسجيل الدخول',
          };
        }
      }
      return {'success': false, 'message': 'فشل تسجيل الدخول (HTTP ${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  static String _extractSessionCookie(String cookieHeader) {
    if (cookieHeader.isEmpty) return '';
    final parts = cookieHeader.split(';');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.startsWith('PHPSESSID=') || trimmed.startsWith('session=')) {
        return trimmed;
      }
    }
    // نأخذ أول كوكي
    return parts.isNotEmpty ? parts.first.trim() : '';
  }

  // ======= FETCH LAST 10 ITEMS =======
  static Future<List<Map<String, dynamic>>> fetchLastItems() async {
    await _init();
    if (_baseUrl == null || _sessionCookie == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/deliver.php?ajax=last_items'),
        headers: {
          'Cookie': _sessionCookie!,
          'X-Requested-With': 'XMLHttpRequest',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true && data['items'] != null) {
          return List<Map<String, dynamic>>.from(data['items']);
        }
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  // ======= SUBMIT DELIVERY =======
  static Future<Map<String, dynamic>> submitDelivery({
    required String itemId,
    required String deliveryStatus,
    required String officeCd,
    String? signatoryName,
    String? nonDeliveryReason,
    String? nonDeliveryMeasure,
    String? otherReason,
    File? signImage,
    File? failImage,
    String? signatureData, // base64 PNG from signature pad
  }) async {
    await _init();
    if (_baseUrl == null || _sessionCookie == null) {
      return {'success': false, 'message': 'الجلسة منتهية، يرجى تسجيل الدخول مجدداً'};
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/deliver.php'),
      );
      request.headers['Cookie'] = _sessionCookie!;

      // الحقول الأساسية
      request.fields['item_id'] = itemId.toUpperCase();
      request.fields['delivery_status'] = deliveryStatus;
      request.fields['office_cd'] = officeCd;

      if (deliveryStatus == 'delivered') {
        request.fields['signatory_name'] = signatoryName ?? '';
        if (signatureData != null && signatureData.isNotEmpty) {
          request.fields['sign_image_data'] = signatureData;
        }
        if (signImage != null) {
          request.files.add(
            await http.MultipartFile.fromPath('sign_image', signImage.path),
          );
        }
      } else {
        request.fields['non_delivery_reason'] = nonDeliveryReason ?? '';
        request.fields['non_delivery_measure'] = nonDeliveryMeasure ?? '';
        if (nonDeliveryReason == '59' && otherReason != null) {
          request.fields['other_reason'] = otherReason;
        }
        if (failImage != null) {
          request.files.add(
            await http.MultipartFile.fromPath('fail_image', failImage.path),
          );
        }
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 302) {
        // الصفحة تُعيد توجيه بعد POST ناجح
        final body = response.body;
        if (body.contains('ناجحة') || body.contains('تم الحفظ')) {
          return {'success': true, 'message': '✅ تمت العملية بنجاح'};
        }
        if (body.contains('خطأ') || body.contains('❌')) {
          // نستخرج رسالة الخطأ
          final errorMatch =
              RegExp(r'خطأ أثناء المعالجة.*?<br>\s*(.*?)<\/div>', dotAll: true)
                  .firstMatch(body);
          final errMsg = errorMatch?.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '') ??
              'حدث خطأ أثناء المعالجة';
          return {'success': false, 'message': errMsg};
        }
        // إعادة التوجيه تعني نجاح
        if (response.statusCode == 302) {
          return {'success': true, 'message': '✅ تمت العملية بنجاح'};
        }
      }
      return {
        'success': false,
        'message': 'استجابة غير متوقعة من الخادم (${response.statusCode})'
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }
}
