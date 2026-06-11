import 'package:flutter/material.dart';
import '../utils/api_service.dart';
import '../utils/session_manager.dart';
import 'deliver_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController(
    text: 'https://tracking.libyapost.ly:7040/api/govems',
  );
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String _errorMsg = '';

  @override
  void dispose() {
    _urlController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = '';
    });

    final result = await ApiService.login(
      baseUrl: _urlController.text.trim().replaceAll(RegExp(r'/$'), ''),
      username: _userController.text.trim(),
      password: _passController.text,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      await SessionManager.saveSession(
        userId: '1',
        username: _userController.text.trim(),
        role: 'delivery',
        sessionCookie: result['session_cookie'] ?? '',
        baseUrl: _urlController.text.trim().replaceAll(RegExp(r'/$'), ''),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DeliverScreen()),
      );
    } else {
      setState(() {
        _errorMsg = result['message'] ?? 'فشل تسجيل الدخول';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // شعار
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF2f6fed),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2f6fed).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.local_post_office_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'بريد ليبيا',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1c2733),
                ),
              ),
              const Text(
                'نظام تسليم الشحنات',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6b7785),
                ),
              ),
              const SizedBox(height: 36),
              // بطاقة تسجيل الدخول
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1c2733),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // رابط الخادم
                      const Text(
                        'رابط الخادم:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _urlController,
                        keyboardType: TextInputType.url,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.link),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'أدخل رابط الخادم' : null,
                      ),
                      const SizedBox(height: 16),

                      // اسم المستخدم
                      const Text(
                        'اسم المستخدم:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _userController,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          hintText: 'username',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'أدخل اسم المستخدم' : null,
                      ),
                      const SizedBox(height: 16),

                      // كلمة المرور
                      const Text(
                        'كلمة المرور:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passController,
                        obscureText: _obscurePassword,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'أدخل كلمة المرور' : null,
                      ),

                      // رسالة الخطأ
                      if (_errorMsg.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMsg,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('دخول'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'بريد ليبيا © ${DateTime.now().year}',
                style: const TextStyle(color: Color(0xFF6b7785), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
