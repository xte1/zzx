# SongWave — iOS Music App

مشروع SwiftUI عربي للبحث عن الأغاني والفيديوهات الموسيقية عبر YouTube Data API v3، وعرض الرائج، وتشغيل ملفات الصوت التي يستوردها المستخدم محلياً مع دعم Background Audio وLock Screen controls.

## ما الذي يتضمنه؟
- بحث YouTube عن فيديوهات الموسيقى والفنانين.
- قائمة الأكثر رواجاً (Music category / IQ region).
- تشغيل الفيديو داخل مشغل YouTube الرسمي المضمّن.
- استيراد ملفات صوتية من تطبيق Files، ومكتبة محلية ومفضلة.
- تشغيل الملفات المحلية بالخلفية وعند قفل الشاشة، مع أوامر شاشة القفل.
- صفحة معلومات المطور قابلة للتعديل.
- Xcode project وGitHub Actions workflow لإنتاج IPA موقّع.

## قيود YouTube
لا يستخرج التطبيق صوت YouTube ولا يحوّله إلى MP3 ولا يشغله في مشغل مخفي. البحث والرائج يستخدمان YouTube Data API، والتشغيل يتم بواسطة مشغل YouTube الرسمي. التشغيل بالخلفية والتنزيل المحلي مخصصان للملفات الصوتية التي يملكها المستخدم أو لديه إذن بتنزيلها.

## إعداد YouTube API
1. افتح Google Cloud Console وأنشئ مشروعاً.
2. فعّل **YouTube Data API v3**.
3. أنشئ API key، ويفضل تقييده على YouTube Data API v3.
4. في GitHub repository: Settings → Secrets and variables → Actions → New repository secret.
5. أضف `YOUTUBE_API_KEY` وضع مفتاحك كقيمة.

للتشغيل محلياً افتح `SongWave/AppConfig.swift` وضع المفتاح في `youtubeAPIKey`.

## تعديل معلومات المطور
عدّل القيم التالية في `SongWave/AppConfig.swift`:
- `developerName`
- `developerEmail`
- `appVersion`

## تجهيز توقيع IPA عبر GitHub Actions
تحتاج حساب Apple Developer صالحاً، شهادة Apple Distribution بصيغة `.p12`، وملف Ad Hoc provisioning profile مطابقاً لـ Bundle ID.

أنشئ الأسرار التالية في GitHub Actions:

| Secret | القيمة |
|---|---|
| `APPLE_CERTIFICATE_P12_BASE64` | محتوى شهادة `.p12` بعد تحويلها إلى Base64 |
| `APPLE_CERTIFICATE_PASSWORD` | كلمة مرور ملف `.p12` |
| `APPLE_PROVISIONING_PROFILE_BASE64` | ملف `.mobileprovision` بعد تحويله إلى Base64 |
| `APPLE_TEAM_ID` | Team ID من حساب Apple Developer |
| `IOS_BUNDLE_ID` | Bundle ID المسجل والموجود في ملف provisioning profile |
| `YOUTUBE_API_KEY` | مفتاح YouTube Data API v3 |

تحويل الملفات إلى Base64 (على macOS/Linux):

```bash
base64 -i AppleDistribution.p12 | tr -d '\n'
base64 -i SongWave.mobileprovision | tr -d '\n'
```

على GitHub افتح Actions ثم **Build SongWave IPA** واضغط Run workflow. عند نجاح البناء ستجد artifact باسم `SongWave-IPA` يحتوي `SongWave.ipa`.

### ملاحظات التوقيع
- غيّر Bundle ID في Xcode project إلى معرفك المسجل إذا أردت، ثم ضع القيمة نفسها في `IOS_BUNDLE_ID`.
- يجب أن يتطابق ملف provisioning profile مع Bundle ID والشهادة وTeam ID.
- هذا workflow ينتج Ad Hoc IPA؛ تثبيته يتطلب أن يكون جهازك مسجلاً ضمن أجهزة ملف Ad Hoc. للتوزيع عبر TestFlight تحتاج إعداد App Store provisioning/export بدلاً من Ad Hoc.

## فتح المشروع
افتح `SongWave.xcodeproj` في Xcode على macOS. الحد الأدنى المستهدف iOS 16.
