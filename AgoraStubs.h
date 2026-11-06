#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

// ===================================================================
// تعريفات بديلة (stub) لواجهات Agora RTC SDK العامة فقط.
// الأسماء والقيم دي موثّقة علنًا في Agora API Reference، احنا هنا
// مجرد بنعرّفها تاني محليًا عشان الكومبايلر يعرف شكل الكلاس من غير
// ما نحتاج نلزق هيدرز SDK الأصلية جوه مشروع الدايلب.
// ===================================================================

typedef NS_ENUM(NSInteger, AgoraAudioProfile) {
    AgoraAudioProfileDefault                = 0,
    AgoraAudioProfileSpeechStandard         = 1,
    AgoraAudioProfileMusicStandard          = 2,
    AgoraAudioProfileMusicStandardStereo    = 3,
    AgoraAudioProfileMusicHighQuality       = 4,
    AgoraAudioProfileMusicHighQualityStereo = 5,
    AgoraAudioProfileIOT                    = 6,
};

typedef NS_ENUM(NSInteger, AgoraAudioScenario) {
    AgoraAudioScenarioDefault               = 0,
    AgoraAudioScenarioChatRoomEntertainment = 1,
    AgoraAudioScenarioEducation             = 2,
    AgoraAudioScenarioGameStreaming         = 3,
    AgoraAudioScenarioShowRoom              = 4,
    AgoraAudioScenarioChatRoomGaming        = 5,
    AgoraAudioScenarioIOT                   = 6,
    AgoraAudioScenarioMeeting               = 8,
};

@interface AgoraVideoEncoderConfiguration : NSObject
@property (assign, nonatomic) CGSize dimensions;
@property (assign, nonatomic) NSInteger frameRate;
@property (assign, nonatomic) NSInteger bitrate;
@property (assign, nonatomic) NSInteger minBitrate;
@end

@interface AgoraRtcEngineKit : NSObject
- (int)setVideoEncoderConfiguration:(AgoraVideoEncoderConfiguration *)config;
- (int)setAudioProfile:(AgoraAudioProfile)profile scenario:(AgoraAudioScenario)scenario;
- (int)enableDualStreamMode:(BOOL)enabled;
@end
