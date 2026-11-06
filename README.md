# AgoraBoost.dylib (بدون جلبريك)

دايلب مستقل 100%، مفيش فيه أي اعتماد على MobileSubstrate ولا
CydiaSubstrate ولا أي مكتبة تانية محتاجة جلبريك. الـ Hooking بيتم
بـ Objective-C Runtime العادي (`method_exchangeImplementations`) جوه
`__attribute__((constructor))` بيتنفذ تلقائيًا أول ما الدايلب يتحمّل
جوه البروسيس.

## إيه اللي بيعمله

نفس منطق النسخة اللي فاتت:
1. يرفع دقة/فريم ريت/بيتريت الفيديو في `setVideoEncoderConfiguration:`.
2. يجبر أعلى بروفايل صوت في `setAudioProfile:scenario:`.
3. يفعّل `enableDualStreamMode:` دايمًا.

بيتأكد الأول إن كلاس `AgoraRtcEngineKit` موجود فعليًا جوه البروسيس
قبل ما يعمل أي Hook، فلو حقنته في تطبيق مش فيه Agora مش هيأثر فيه
بحاجة.

## مهم: الفرق عن نسخة Theos

- **مفيش جلبريك مطلوب على جهازك إطلاقًا.**
- الدايلب مش بيتحمّل تلقائيًا في *كل* التطبيقات زي تويك الجلبريك —
  لازم تحقنه بنفسك جوه IPA تطبيق معيّن (مرة واحدة لكل تطبيق)، وبعدين
  تنصّب النسخة المعدَّلة دي بدل النسخة الأصلية من المتجر.
- التطبيق المعدَّل لازم يتوقّع (re-sign) بشهادة/بروفايل عشان iOS
  يقبل يشغّله، وده جزء طبيعي من أي عملية Sideloading.

## خطوة 1: بناء الدايلب

على ماك فيه Xcode Command Line Tools:

```bash
chmod +x build.sh
./build.sh
```

هيطلع عندك `AgoraBoost.dylib` في نفس المجلد.

## خطوة 2: حقنه جوه IPA التطبيق

عندك طريقتين، اختار الأسهل بالنسبالك:

### الطريقة أ) TrollStore + TrollFools (الأسهل، وبدون إعادة توقيع يدوي)

لو جهازك بيدعم [TrollStore](https://github.com/opa334/TrollStore) (تثبيت
بدون جلبريك ومينتهيش صلاحيته):

1. نزّل تطبيق **TrollFools** مفتوح المصدر (أداة شهيرة لحقن الدايلبات
   في أي تطبيق متثبت عن طريق TrollStore، بدون أي إعادة توقيع يدوي).
2. افتح TrollFools → اختار التطبيق المستهدف (اللي بيستخدم Agora).
3. اضغط إضافة (+) واختار ملف `AgoraBoost.dylib`.
4. TrollFools هيحقن الدايلب ويعيد توقيع التطبيق تلقائيًا على الجهاز.
5. افتح التطبيق عادي — الدايلب هيشتغل تلقائيًا.

### الطريقة ب) Sideloadly / AltStore (من غير TrollStore)

1. حمّل IPA الأصلي للتطبيق المستهدف (من نسخة اشتريتها/تملكها).
2. افتح [Sideloadly](https://sideloadly.io/) على ويندوز/ماك.
3. في خانة "Tweaks/Dylibs" ضيف ملف `AgoraBoost.dylib`
   (Sideloadly بيعمل الحقن + إعادة التوقيع تلقائيًا بالـ Apple ID
   بتاعك).
4. وصّل جهازك واضغط Start، هيتثبت التطبيق المعدَّل على جهازك مباشرة.

> ملاحظة: التوقيع بـ Apple ID مجاني بيحتاج إعادة تثبيت/تجديد كل 7
> أيام (قيود أبل العادية)، أما حساب Developer المدفوع فبيدّيك سنة
> كاملة.

### الطريقة ج) يدوي (insert_dylib + codesign)

لو عايز تتحكم بنفسك بدل الأدوات الجاهزة:

```bash
# 1) فك ضغط الـ IPA
unzip App.ipa -d App_extracted
cd App_extracted/Payload/App.app

# 2) انسخ الدايلب جوه مجلد Frameworks
mkdir -p Frameworks
cp /path/to/AgoraBoost.dylib Frameworks/

# 3) احقن مرجع التحميل جوه الـ Mach-O الرئيسي
#    (أداة insert_dylib: https://github.com/Tyilo/insert_dylib)
insert_dylib --inplace --weak \
    "@executable_path/Frameworks/AgoraBoost.dylib" \
    App

# 4) أعد توقيع الدايلب والتطبيق كله بنفس الشهادة/بروفايل
codesign -f -s "اسم الشهادة بتاعتك" Frameworks/AgoraBoost.dylib
codesign -f -s "اسم الشهادة بتاعتك" --entitlements entitlements.plist .

# 5) أعد ضغط الـ IPA ونصّبه (Xcode / Sideloadly / Apple Configurator)
cd ../../
zip -r App_patched.ipa Payload
```

## خطوة 3 (اختياري): التحكم في الإعدادات

حط ملف اسمه `AgoraBoostPrefs.plist` جنب الدايلب نفسه جوه
`App.app/Frameworks/` بنفس شكل الموجود في `AgoraBoostPrefs.plist`
المرفق هنا، وعدّل القيم زي ما يناسبك من غير ما تعيد البناء من
الصفر (بس هتحتاج تعيد التوقيع لو عدّلت أي ملف جوه الـ bundle).

## ملاحظات مهمة

- ده تعديل لنسخة شخصية من تطبيق إنت مالكه، شغال محليًا على جهازك —
  مش بيفك تشفير ولا يتجاوز أي حماية DRM جوه مكتبة Agora نفسها، وبيعمل
  Swizzling بس على ميثودز عامة وموثّقة رسميًا.
- كل التطبيقات اللي بتعدلها كده عادةً بتخالف شروط استخدام المتجر
  (App Store ToS)، فالاستخدام على مسؤوليتك الشخصية.
- رفع البيتريت/الدقة بالقوة يستهلك بيانات وبطارية أكتر، وجودة أسوأ
  لو الشبكة ضعيفة (لأنك بتلغي التكيّف التلقائي) — عدّل القيم في ملف
  التفضيلات حسب احتياجك الفعلي.
