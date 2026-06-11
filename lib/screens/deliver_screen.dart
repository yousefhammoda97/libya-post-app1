import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import '../models/office_data.dart';
import '../utils/api_service.dart';
import '../utils/session_manager.dart';
import 'login_screen.dart';
import 'last_items_screen.dart';

class DeliverScreen extends StatefulWidget {
  const DeliverScreen({super.key});

  @override
  State<DeliverScreen> createState() => _DeliverScreenState();
}

class _DeliverScreenState extends State<DeliverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemIdController = TextEditingController();
  final _signatoryController = TextEditingController();
  final _otherReasonController = TextEditingController();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  String _deliveryStatus = 'delivered';
  String? _selectedOfficeCd;
  String? _selectedReason;
  String? _selectedMeasure;
  File? _signImage;
  File? _failImage;
  bool _loading = false;
  String _username = '';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final u = await SessionManager.getUsername();
    setState(() => _username = u ?? '');
  }

  @override
  void dispose() {
    _itemIdController.dispose();
    _signatoryController.dispose();
    _otherReasonController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isSignature, bool useCamera) async {
    final source = useCamera ? ImageSource.camera : ImageSource.gallery;
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        if (isSignature) {
          _signImage = File(picked.path);
        } else {
          _failImage = File(picked.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOfficeCd == null) {
      _showError('يرجى اختيار مكتب التسليم');
      return;
    }
    if (_deliveryStatus == 'delivered' && _signImage == null) {
      _showError('يرجى إضافة صورة إثبات التسليم');
      return;
    }
    if (_deliveryStatus == 'not_delivered' && _selectedReason == null) {
      _showError('يرجى اختيار سبب عدم التسليم');
      return;
    }

    setState(() => _loading = true);

    // الحصول على بيانات التوقيع
    String? signatureData;
    if (_deliveryStatus == 'delivered' && _signatureController.isNotEmpty) {
      final bytes = await _signatureController.toPngBytes();
      if (bytes != null) {
        final base64Str = base64FromBytes(bytes);
        signatureData = 'data:image/png;base64,$base64Str';
      }
    }

    final result = await ApiService.submitDelivery(
      itemId: _itemIdController.text.trim(),
      deliveryStatus: _deliveryStatus,
      officeCd: _selectedOfficeCd!,
      signatoryName: _deliveryStatus == 'delivered' ? _signatoryController.text.trim() : null,
      nonDeliveryReason: _deliveryStatus == 'not_delivered' ? _selectedReason : null,
      nonDeliveryMeasure: _deliveryStatus == 'not_delivered' ? _selectedMeasure : null,
      otherReason: _selectedReason == '59' ? _otherReasonController.text.trim() : null,
      signImage: _deliveryStatus == 'delivered' ? _signImage : null,
      failImage: _deliveryStatus == 'not_delivered' ? _failImage : null,
      signatureData: signatureData,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      _showSuccess(result['message'] ?? 'تمت العملية بنجاح');
      _resetForm();
    } else {
      _showError(result['message'] ?? 'حدث خطأ');
    }
  }

  String base64FromBytes(List<int> bytes) {
    const base64Chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    var result = '';
    var i = 0;
    while (i < bytes.length) {
      final b0 = bytes[i++];
      final b1 = i < bytes.length ? bytes[i++] : 0;
      final b2 = i < bytes.length ? bytes[i++] : 0;
      result += base64Chars[(b0 >> 2) & 0x3F];
      result += base64Chars[((b0 & 0x3) << 4) | ((b1 >> 4) & 0xF)];
      result += base64Chars[((b1 & 0xF) << 2) | ((b2 >> 6) & 0x3)];
      result += base64Chars[b2 & 0x3F];
    }
    final padding = bytes.length % 3;
    if (padding == 1) {
      result = '${result.substring(0, result.length - 2)}==';
    } else if (padding == 2) {
      result = '${result.substring(0, result.length - 1)}=';
    }
    return result;
  }

  void _resetForm() {
    _itemIdController.clear();
    _signatoryController.clear();
    _otherReasonController.clear();
    _signatureController.clear();
    setState(() {
      _deliveryStatus = 'delivered';
      _selectedReason = null;
      _selectedMeasure = null;
      _signImage = null;
      _failImage = null;
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFe53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1f9d55),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: const Color(0xFFe53935)),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SessionManager.clearSession();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F9),
      appBar: AppBar(
        title: const Text('تسليم البريد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'آخر 10 شحنات',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LastItemsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جارٍ الإرسال...', style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _card(children: [
                      // رقم الشحنة
                      _label('رقم الشحنة (Item ID):'),
                      TextFormField(
                        controller: _itemIdController,
                        textDirection: TextDirection.ltr,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                          LengthLimitingTextInputFormatter(13),
                          _UpperCaseFormatter(),
                        ],
                        decoration: const InputDecoration(
                          hintText: 'مثال: EE123456789LY',
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'أدخل رقم الشحنة';
                          if (v.length != 13) return 'رقم الشحنة يجب أن يكون 13 حرف';
                          return null;
                        },
                      ),

                      // مكتب التسليم
                      _label('مكتب التسليم:'),
                      DropdownButtonFormField<String>(
                        value: _selectedOfficeCd,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        hint: const Text('اختر مكتب التسليم'),
                        items: OfficeData.offices.map((o) {
                          return DropdownMenuItem(
                            value: o['code'],
                            child: Text(
                              '${o['name']} (${o['code']})',
                              style: const TextStyle(fontSize: 15),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _selectedOfficeCd = v),
                        validator: (v) =>
                            v == null ? 'اختر مكتب التسليم' : null,
                      ),

                      // حالة التسليم
                      _label('حالة التسليم:'),
                      Row(
                        children: [
                          Expanded(
                            child: _statusCard(
                              label: 'تم التسليم',
                              icon: Icons.check_circle_outline,
                              color: const Color(0xFF1f9d55),
                              selected: _deliveryStatus == 'delivered',
                              onTap: () =>
                                  setState(() => _deliveryStatus = 'delivered'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statusCard(
                              label: 'لم يتم التسليم',
                              icon: Icons.cancel_outlined,
                              color: const Color(0xFFe53935),
                              selected: _deliveryStatus == 'not_delivered',
                              onTap: () => setState(
                                  () => _deliveryStatus = 'not_delivered'),
                            ),
                          ),
                        ],
                      ),
                    ]),

                    const SizedBox(height: 12),

                    // حقول التسليم الناجح
                    if (_deliveryStatus == 'delivered') ...[
                      _card(children: [
                        _sectionTitle('معلومات التسليم', Icons.person_pin),

                        _label('اسم المستلم الفعلي:'),
                        TextFormField(
                          controller: _signatoryController,
                          decoration: const InputDecoration(
                            hintText: 'الاسم الكامل للمستلم',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'أدخل اسم المستلم' : null,
                        ),

                        _label('صورة إثبات التسليم: *'),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('كاميرا'),
                                onPressed: () => _pickImage(true, true),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  foregroundColor: const Color(0xFF2f6fed),
                                  side: const BorderSide(
                                      color: Color(0xFF2f6fed)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.photo_library),
                                label: const Text('معرض'),
                                onPressed: () => _pickImage(true, false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  foregroundColor: const Color(0xFF6b7785),
                                  side: const BorderSide(
                                      color: Color(0xFF6b7785)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_signImage != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_signImage!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          ),
                        ],

                        _label('توقيع المستلم (اختياري):'),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFd6deea), width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Signature(
                            controller: _signatureController,
                            height: 160,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text('مسح التوقيع'),
                          onPressed: () => _signatureController.clear(),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6b7785),
                          ),
                        ),
                      ]),
                    ],

                    // حقول عدم التسليم
                    if (_deliveryStatus == 'not_delivered') ...[
                      _card(children: [
                        _sectionTitle('سبب عدم التسليم', Icons.info_outline),

                        _label('سبب عدم التسليم:'),
                        DropdownButtonFormField<String>(
                          value: _selectedReason,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.report_problem_outlined),
                          ),
                          hint: const Text('اختر السبب'),
                          items: OfficeData.nonDeliveryReasons.map((r) {
                            return DropdownMenuItem(
                              value: r['code'],
                              child: Text(
                                '${r['code']} - ${r['name']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedReason = v),
                          validator: (v) =>
                              v == null ? 'اختر سبب عدم التسليم' : null,
                        ),

                        if (_selectedReason == '59') ...[
                          _label('اكتب السبب:'),
                          TextFormField(
                            controller: _otherReasonController,
                            decoration: const InputDecoration(
                              hintText: 'اكتب السبب هنا...',
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'أدخل السبب' : null,
                          ),
                        ],

                        _label('الإجراء المتخذ:'),
                        DropdownButtonFormField<String>(
                          value: _selectedMeasure,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.assignment_outlined),
                          ),
                          hint: const Text('اختر الإجراء'),
                          items: OfficeData.nonDeliveryMeasures.map((m) {
                            return DropdownMenuItem(
                              value: m['code'],
                              child: Text(
                                '${m['code']} - ${m['name']}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedMeasure = v),
                        ),

                        _label('صورة إثبات عدم التسليم (اختياري):'),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('كاميرا'),
                                onPressed: () => _pickImage(false, true),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  foregroundColor: const Color(0xFF2f6fed),
                                  side: const BorderSide(color: Color(0xFF2f6fed)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.photo_library),
                                label: const Text('معرض'),
                                onPressed: () => _pickImage(false, false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  foregroundColor: const Color(0xFF6b7785),
                                  side: const BorderSide(color: Color(0xFF6b7785)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_failImage != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_failImage!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          ),
                        ],
                      ]),
                    ],

                    const SizedBox(height: 16),

                    // زر الإرسال
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send, size: 22),
                        label: const Text('تسجيل الحالة',
                            style: TextStyle(fontSize: 18)),
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _deliveryStatus == 'delivered'
                              ? const Color(0xFF1f9d55)
                              : const Color(0xFFe53935),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Color(0xFF1c2733),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2f6fed), size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1c2733),
          ),
        ),
      ],
    );
  }

  Widget _statusCard({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
