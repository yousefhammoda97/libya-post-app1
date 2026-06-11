# تطبيق بريد ليبيا - نظام التسليم
## Libya Post Delivery App (Flutter)

تطبيق أندرويد لتسجيل حالات تسليم الشحنات البريدية.

---

## متطلبات التشغيل

- Flutter SDK 3.10+
- Dart SDK 3.0+
- Android SDK (minSdk: 21 = Android 5.0+)
- أندرويد 5.0 أو أحدث

---

## خطوات التثبيت والبناء

### 1. تثبيت المتطلبات
```bash
flutter pub get
```

### 2. بناء APK للتثبيت المباشر
```bash
flutter build apk --release
```
الملف الناتج: `build/app/outputs/flutter-apk/app-release.apk`

### 3. بناء App Bundle لـ Google Play
```bash
flutter build appbundle --release
```

### 4. تشغيل على جهاز متصل
```bash
flutter run
```

---

## مميزات التطبيق

✅ تسجيل الدخول بحساب النظام
✅ إدخال رقم الشحنة (13 حرف)
✅ اختيار مكتب التسليم من قائمة كاملة (65+ مكتب)
✅ تسجيل حالة التسليم (ناجح / غير ناجح)
✅ رفع صورة إثبات التسليم (كاميرا أو معرض)
✅ لوحة توقيع رقمي للمستلم
✅ أسباب عدم التسليم مع الإجراءات
✅ صورة إثبات عدم التسليم (اختياري)
✅ عرض آخر 10 شحنات معالجة
✅ واجهة عربية كاملة RTL
✅ يعمل على أندرويد 5.0+

---

## هيكل المشروع

```
lib/
├── main.dart              # نقطة البداية والتوجيه
├── screens/
│   ├── login_screen.dart  # شاشة تسجيل الدخول
│   ├── deliver_screen.dart # شاشة التسليم الرئيسية
│   └── last_items_screen.dart # آخر 10 شحنات
├── models/
│   └── office_data.dart   # قائمة المكاتب والأسباب
└── utils/
    ├── api_service.dart    # التواصل مع الخادم
    └── session_manager.dart # إدارة الجلسة
```

---

## إعدادات الخادم

في شاشة تسجيل الدخول، أدخل رابط الخادم:
```
https://tracking.libyapost.ly:7040/api/govems
```

---

## API Endpoints المستخدمة

| Endpoint | الوظيفة |
|----------|---------|
| `POST /login.php` | تسجيل الدخول |
| `POST /deliver.php` | تسجيل حالة التسليم |
| `GET /deliver.php?ajax=last_items` | آخر 10 شحنات |
