#import "AgoraStubs.h"
#import <objc/runtime.h>

// ===================================================================
// AgoraBoost.dylib
// دايلب مستقل 100% - بدون أي اعتماد على MobileSubstrate / CydiaSubstrate
// / Theos runtime. كل الـ Hooking بيتم بـ Objective-C Runtime العادي
// (method_exchangeImplementations) جوه constructor بيتنفذ تلقائيًا
// أول ما الدايلب يتحمّل جوه البروسيس (عن طريق LC_LOAD_DYLIB محقون
// جوه الـ Mach-O بتاع التطبيق).
// ===================================================================

#pragma mark - إعدادات قابلة للتعديل (ملف تفضيلات اختياري)

// لو عايز تتحكم في القيم من غير ما تعيد بناء الدايلب، ممكن تحط ملف
// Preferences.plist جنب الدايلب نفسه جوه الـ Bundle، وهنقرأ منه هنا.
static NSString *AGBPreferencesPath(void) {
    NSString *dylibDir = [[NSBundle mainBundle] bundlePath];
    return [dylibDir stringByAppendingPathComponent:@"AgoraBoostPrefs.plist"];
}

static BOOL  gEnabled         = YES;
static BOOL  gForceHDVideo    = YES;
static BOOL  gForceHQAudio    = YES;
static BOOL  gForceDualStream = YES;
static NSInteger gMinWidth       = 1280;
static NSInteger gMinHeight      = 720;
static NSInteger gMinFrameRate   = 24;
static NSInteger gMinBitrateKbps = 1500;

static void AGBLoadPreferences(void) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:AGBPreferencesPath()];
    if (!prefs) return;

    if (prefs[@"Enabled"])         gEnabled         = [prefs[@"Enabled"] boolValue];
    if (prefs[@"ForceHDVideo"])    gForceHDVideo    = [prefs[@"ForceHDVideo"] boolValue];
    if (prefs[@"ForceHQAudio"])    gForceHQAudio    = [prefs[@"ForceHQAudio"] boolValue];
    if (prefs[@"ForceDualStream"]) gForceDualStream = [prefs[@"ForceDualStream"] boolValue];
    if (prefs[@"MinWidth"])        gMinWidth        = [prefs[@"MinWidth"] integerValue];
    if (prefs[@"MinHeight"])       gMinHeight       = [prefs[@"MinHeight"] integerValue];
    if (prefs[@"MinFrameRate"])    gMinFrameRate    = [prefs[@"MinFrameRate"] integerValue];
    if (prefs[@"MinBitrateKbps"])  gMinBitrateKbps  = [prefs[@"MinBitrateKbps"] integerValue];
}

#pragma mark - الميثودز البديلة (Swizzled Implementations)

@interface NSObject (AgoraBoostSwizzle)
- (int)agb_setVideoEncoderConfiguration:(AgoraVideoEncoderConfiguration *)config;
- (int)agb_setAudioProfile:(AgoraAudioProfile)profile scenario:(AgoraAudioScenario)scenario;
- (int)agb_enableDualStreamMode:(BOOL)enabled;
@end

@implementation NSObject (AgoraBoostSwizzle)

// بعد عملية الـ Exchange، استدعاء "agb_..." هنا فعليًا بينفّذ
// الـ Implementation الأصلي بتاع الميثود (لأن الاتنين اتبادلوا مكان بعض)
- (int)agb_setVideoEncoderConfiguration:(AgoraVideoEncoderConfiguration *)config {
    if (gEnabled && gForceHDVideo && config) {
        CGSize dim = config.dimensions;
        CGFloat currentArea = dim.width * dim.height;
        CGFloat minArea = (CGFloat)(gMinWidth * gMinHeight);

        if (currentArea < minArea) {
            config.dimensions = CGSizeMake(gMinWidth, gMinHeight);
        }
        if (config.frameRate < gMinFrameRate) {
            config.frameRate = gMinFrameRate;
        }
        if (config.bitrate < gMinBitrateKbps) {
            config.bitrate = gMinBitrateKbps;
        }
        if (config.minBitrate > 0 && config.minBitrate < (gMinBitrateKbps / 2)) {
            config.minBitrate = gMinBitrateKbps / 2;
        }

        NSLog(@"[AgoraBoost] فيديو -> %@x%@ @%@fps bitrate=%@kbps",
              @(config.dimensions.width), @(config.dimensions.height),
              @(config.frameRate), @(config.bitrate));
    }
    // بعد الـ swap، السطر ده بينادي الـ IMP الأصلي الحقيقي
    return [self agb_setVideoEncoderConfiguration:config];
}

- (int)agb_setAudioProfile:(AgoraAudioProfile)profile scenario:(AgoraAudioScenario)scenario {
    AgoraAudioProfile finalProfile = profile;
    if (gEnabled && gForceHQAudio) {
        finalProfile = AgoraAudioProfileMusicHighQualityStereo;
        NSLog(@"[AgoraBoost] صوت -> بروفايل %ld بدل %ld", (long)finalProfile, (long)profile);
    }
    return [self agb_setAudioProfile:finalProfile scenario:scenario];
}

- (int)agb_enableDualStreamMode:(BOOL)enabled {
    BOOL finalValue = enabled;
    if (gEnabled && gForceDualStream) {
        finalValue = YES;
    }
    return [self agb_enableDualStreamMode:finalValue];
}

@end

#pragma mark - آلية الـ Swizzling

static void AGBSwizzle(Class cls, SEL originalSelector, SEL swizzledSelector) {
    if (!cls) return;

    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    if (!originalMethod || !swizzledMethod) {
        NSLog(@"[AgoraBoost] تخطينا %@ - الميثود مش موجود", NSStringFromSelector(originalSelector));
        return;
    }

    // لو الكلاس نفسه معرّفش الميثود الأصلي (ممكن يكون موروث)، نضيفه
    // الأول كميثود جديد يشاور على الـ Implementation البديل، وبعدين
    // نستبدل الـ Implementation بتاع الميثود البديل بالأصلي.
    BOOL didAddMethod = class_addMethod(cls,
                                         originalSelector,
                                         method_getImplementation(swizzledMethod),
                                         method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(cls,
                             swizzledSelector,
                             method_getImplementation(originalMethod),
                             method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }

    NSLog(@"[AgoraBoost] تم عمل Hook بنجاح لـ %@", NSStringFromSelector(originalSelector));
}

#pragma mark - نقطة الدخول (تتنفذ تلقائيًا وقت تحميل الدايلب)

__attribute__((constructor))
static void AGBEntryPoint(void) {
    @autoreleasepool {
        AGBLoadPreferences();
        if (!gEnabled) {
            NSLog(@"[AgoraBoost] التويك متعطّل من ملف الإعدادات");
            return;
        }

        Class agoraClass = NSClassFromString(@"AgoraRtcEngineKit");
        if (!agoraClass) {
            // التطبيق الحالي مش فيه Agora SDK - منعملش أي حاجة
            return;
        }

        NSLog(@"[AgoraBoost] تم العثور على AgoraRtcEngineKit - بدء الـ Hooks في: %@",
              [[NSBundle mainBundle] bundleIdentifier]);

        AGBSwizzle(agoraClass,
                   @selector(setVideoEncoderConfiguration:),
                   @selector(agb_setVideoEncoderConfiguration:));

        AGBSwizzle(agoraClass,
                   @selector(setAudioProfile:scenario:),
                   @selector(agb_setAudioProfile:scenario:));

        AGBSwizzle(agoraClass,
                   @selector(enableDualStreamMode:),
                   @selector(agb_enableDualStreamMode:));
    }
}
