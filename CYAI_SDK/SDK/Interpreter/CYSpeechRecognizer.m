//
//  CYSpeechRecognizer.m
//  AI_SDK
//
//  Created by WWLy on 28/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//


#import "CYSpeechRecognizer.h"
#import "CYIflyRecognizer.h"
#import "CYSiriRecognizer.h"
#import "CYSpeechSession.h"
#import "CYTranslator.h"
#import "CYTranslateModel.h"
#import "CYSpeaker.h"
#import "CYThreadRunloop.h"
#import "BNNSLanguageDetection.h"
#import <AVFoundation/AVFoundation.h>


/**
 SpeechRecognizer 包括讯飞和 Siri 两个语音识别 SDK
 */
@interface CYSpeechRecognizer () <CYIflyRecognizerDelegate>


@property (nonatomic, strong) CYIflyRecognizer *iflyRecognizer;
@property (nonatomic, strong) CYSiriRecognizer *siriRecognizer;

// 识别结果
@property (nonatomic, strong) CYSpeechSession *session;

@property (nonatomic, assign) long long timeIntervel;

@property (nonatomic, assign) CYDetectLanguage  detectLanguage;

@end


static id _instance;

@implementation CYSpeechRecognizer

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}


- (instancetype)init {
    if (self = [super init]) {
        
        [self initIflyRecognizer];
        [self initSisiRecognizer];
        [self initSpeaker];
        
        [self initHeadset];
        
        [self.threadLoop startRunLoop];
        
        create_network_with_data();
    }
    return self;
}

#pragma mark - 语音识别
// 初始化讯飞识别器
- (void)initIflyRecognizer {
    __weak typeof(self) weakSelf = self;
    // 讯飞识别得到结果
    self.iflyRecognizer.finishRecognizeBlock = ^(NSString *resultStr, float asrConfidence) {
        /**
         这次讯飞识别结束了, 所以英文不需要继续识别了, 但是英文需要返回 Final Result 结果
         调用此方法会触发 siri 的识别结束回调方法
         */
        [weakSelf handleSessionWithType:CYRecognizeTypeIfly asrWords:resultStr asrConfidence:asrConfidence];
        [weakSelf.siriRecognizer temp];
        
    };
}

// 初始化 siri 识别器
- (void)initSisiRecognizer {
    __weak typeof(self) weakSelf = self;
    self.siriRecognizer.finishRecognizeBlock = ^(NSString *resultStr, float asrConfidence, CYRecognizeType type) {
        [weakSelf handleSessionWithType:type asrWords:resultStr asrConfidence:asrConfidence];
    };
}

- (void)handleSessionWithType:(CYRecognizeType)type asrWords:(NSString *)asrWords asrConfidence:(float)asrConfidence {
    /**
     把识别结果转换成 sessionWords 模型
     */
    CYSessionWords *sessionWords = [[CYSessionWords alloc] init];
    sessionWords.asrWords = asrWords;
    sessionWords.asrConfidence = asrConfidence;
    // 以讯飞为主导, 把讯飞识别结果时间作为 session 时间
    if (type == CYRecognizeTypeIfly) {
        self.timeIntervel = [[NSDate date] timeIntervalSince1970] * 1000;
    }
    CYSpeechSession *speechSession = [[CYCollectionQueue shareInstance] getSpeechSessionWithID:self.timeIntervel];
    if (speechSession == nil) {
        return;
    }
    // 从讯飞识别过来的
    if (type == CYRecognizeTypeIfly) {
        speechSession.iflySessionWords = sessionWords;
        // 如果用户设置了讲英文, 就不执行翻译  否则就进行 中->英
        if (self.detectLanguage != CYDetectLanguageEnglish) {
            NSLog(@"讯飞识别sessionWords: %@ - %f - %@", sessionWords.asrWords, sessionWords.asrConfidence, [NSThread currentThread]);
            [[CYTranslator shareInstance] translateWithSourceType:CYLanguageTypeChinese sourceString:asrWords complete:^(CYTranslateModel *transModel) {
                // 当翻译完毕之后判断会话是否结束, 如果已经结束就不再处理
                if (speechSession.adoptSessionWords) {
                    return;
                }
                speechSession.flagTime = [[NSDate date] timeIntervalSince1970] * 1000;
                sessionWords.transWords = transModel.target;
                sessionWords.transConfidence = transModel.confidence;
                NSLog(@"讯飞翻译sessionWords: %@ - %f - %@", sessionWords.transWords, sessionWords.transConfidence, [NSThread currentThread]);
            }];
        }
    }
    // siri 得到部分识别结果
    else if (type == CYRecognizeTypeSiriPart) {
        speechSession.partSiriSessionWords = sessionWords;
        // 如果用户设置了讲中文, 就不执行翻译  否则就进行 英->中
        if (self.detectLanguage == CYDetectLanguageChinese) {
            return;
        }
        NSLog(@"Siri部分识别sessionWords: %@ - %f - %@", sessionWords.asrWords, sessionWords.asrConfidence, [NSThread currentThread]);
        [[CYTranslator shareInstance] translateWithSourceType:CYLanguageTypeEnglish sourceString:asrWords complete:^(CYTranslateModel *transModel) {
            
            // 当翻译完毕之后判断会话是否结束, 如果已经结束就不再处理
            if (speechSession.adoptSessionWords) {
                return;
            }
            
            speechSession.flagTime = [[NSDate date] timeIntervalSince1970] * 1000;
            sessionWords.transWords = transModel.target;
            sessionWords.transConfidence = transModel.confidence;
            NSLog(@"Siri部分翻译sessionWords: %@ - %f - %@", sessionWords.transWords, sessionWords.transConfidence, [NSThread currentThread]);
            
        }];
    }
    // siri 得到完整识别结果
    else if (type == CYRecognizeTypeSiriFull) {

        self.timeIntervel = 0;
        
        if (self.detectLanguage == CYDetectLanguageChinese) {
            return;
        }
        
        // 如果完整识别结果和部分识别结果相同, 就不需要再进行翻译
        if ([asrWords isEqualToString:speechSession.partSiriSessionWords.asrWords]) {
            speechSession.fullSiriSessionWords = speechSession.partSiriSessionWords;
            // 由于部分识别结果的置信度不准, 所以需要替换成完整识别结果的置信度
            speechSession.fullSiriSessionWords.asrConfidence = asrConfidence;
            NSLog(@"Siri部分识别结果和完整识别结果相同sessionWords: %@ - %f - %@", sessionWords.asrWords, sessionWords.asrConfidence, [NSThread currentThread]);
            return;
        }
        
        speechSession.fullSiriSessionWords = sessionWords;
        // 如果用户设置了讲中文, 就不执行翻译  否则就进行 英->中
        
        NSLog(@"Siri识别sessionWords: %@ - %f - %@", sessionWords.asrWords, sessionWords.asrConfidence, [NSThread currentThread]);
        [[CYTranslator shareInstance] translateWithSourceType:CYLanguageTypeEnglish sourceString:asrWords complete:^(CYTranslateModel *transModel) {
            
            // 当翻译完毕之后判断会话是否结束, 如果已经结束就不再处理
            if (speechSession.adoptSessionWords) {
                return;
            }
            
            speechSession.flagTime = [[NSDate date] timeIntervalSince1970] * 1000;
            sessionWords.transWords = transModel.target;
            sessionWords.transConfidence = transModel.confidence;
            NSLog(@"Siri翻译sessionWords: %@ - %f - %@", sessionWords.transWords, sessionWords.transConfidence, [NSThread currentThread]);
        }];
    }
}


// 开启讯飞和 siri 的语音识别
- (void)startRecognizers {
    // 讯飞开始监听
    [self.iflyRecognizer startRecognizer];
    [self.iflyRecognizer startListen];
    // siri 开始监听
    [self.siriRecognizer startRecognizer];
    [self.siriRecognizer startListen];
}

- (void)startXunfei {
    // 讯飞开始监听
    [self.iflyRecognizer startRecognizer];
    [self.iflyRecognizer startListen];
}

- (void)startSiri {
    // siri 开始监听
    [self.siriRecognizer startRecognizer];
    [self.siriRecognizer startListen];
}

// 停止讯飞和 siri 的语音识别
- (void)stopRecognizers {
    // 讯飞停止监听
    [self.iflyRecognizer stopRecognizer];
    [self.iflyRecognizer stopListen];
    // siri 停止监听
    [self.siriRecognizer stopRecognizer];
    [self.siriRecognizer stopListen];
}

- (void)stopXunfei {
    // 讯飞停止监听
    [self.iflyRecognizer stopRecognizer];
    [self.iflyRecognizer stopListen];
}

- (void)stopSiri {
    // siri 停止监听
    [self.siriRecognizer stopRecognizer];
    [self.siriRecognizer stopListen];
}


#pragma mark - 语音合成
// 初始化语音合成
- (void)initSpeaker {
    __weak typeof(self) weakSelf = self;
    // 合成完毕
    self.speaker.speakOver = ^{
        NSLog(@"speakOver");
        // 当语音合成完毕后开始识别
        if (weakSelf.isSpeaking) {
            [weakSelf.iflyRecognizer startListen];
            weakSelf.siriRecognizer.sf_do_not_send_user_is_speaking = false;
            weakSelf.isSpeaking = false;
        }
        
        if ([weakSelf.delegate respondsToSelector:@selector(whenSpeakerOver)]) {
            [weakSelf.delegate whenSpeakerOver];
        }
    };
}

// 自动从合成队列中取出并进行合成
- (void)sayTextAuto {
    if (self.isSpeaking) {
        return;
    }
    CYCollectionQueue *queue = [CYCollectionQueue shareInstance];
    CYSpeechSession *session = queue.speakQueue.firstObject;
    if (session == nil) {
        return;
    }
    [queue.speakQueue removeObject:session];
    // 主线程回调
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(beginSayTextWithSource:target:)]) {
            [self.delegate beginSayTextWithSource:session.adoptSessionWords.asrWords target:session.adoptSessionWords.transWords];
        }
    }];

    NSString *speakString = session.adoptSessionWords.transWords;
    [self sayText:speakString];
}

- (void)sayText:(NSString *)text {
    // 如果没有插入耳机，或者虽然插入耳机但是为交传状态:不要一边识别一边说话 即交传模式
    if (![self isHeadsetPluggedIn] || self.isSimultaneousInterpretation == NO) {
        NSLog(@"交传模式: 开始合成,停止识别");
        NSLog(@"isSpeaking? : %zd", self.isSpeaking);
        self.isSpeaking = true;
        // 停止Siri的识别, 即不把Siri录音回调的结果传递给Siri识别
        self.siriRecognizer.sf_do_not_send_user_is_speaking = true;
        
        [self.iflyRecognizer stopListen];
    }
    [self.speaker sayText:text];
}


#pragma mark - SDK接口

- (void)transText:(NSString *)sourceStr languageType:(CYLanguageType) languageType complete:(void(^)(NSString *transWords))complete {
    [[CYTranslator shareInstance] translateWithSourceType:languageType sourceString:sourceStr complete:^(CYTranslateModel *transModel) {
        if (complete) {
            complete(transModel.target);
        }
    }];
}

- (void)changeDetectLanguage:(CYDetectLanguage)detectLanguage {
    self.detectLanguage = detectLanguage;
    // 如果是中文就停止 siri 录音
    if (detectLanguage == CYDetectLanguageChinese) {
//        [self.siriRecognizer endAVCapture];
        [self.siriRecognizer stopListen];
    } else {
        [self.siriRecognizer startListen];
    }
}

- (CYDetectLanguage)currentDetectLanguage {
    return self.detectLanguage;
}

// 设置讯飞中文口音识别
- (void)setiFlyAccent:(ChineseAccent)accentEnum {
    [self.iflyRecognizer setiFlyAccent:accentEnum];
}


#pragma mark - 耳机拔插事件检测

- (void)initSimultaneousInterpretation {
    if ([self isHeadsetPluggedIn]) {
        self.isSimultaneousInterpretation = YES;
    } else {
        self.isSimultaneousInterpretation = NO;
    }
}

- (BOOL)isHeadsetPluggedIn {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        //CYLog(@"input mic :  %@", [desc portType]);
        if (([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            || ([[desc portType] isEqualToString:AVAudioSessionPortBluetoothHFP])
            || ([[desc portType] isEqualToString:AVAudioSessionPortBluetoothA2DP])
            ) {
            return YES;
        }
    }
    return NO;
}

- (void)initHeadset {
    //监听耳机事件
    [[AVAudioSession sharedInstance] setActive:YES error:nil];//创建单例对象并且使其设置为活跃状态.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];//设置通知
}

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    //更新UI要放在主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (routeChangeReason) {
            case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
                self.isSimultaneousInterpretation = YES; // 同传
                [self.delegate HeadsetPluggedIn];
                break;
            case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
                self.isSimultaneousInterpretation = NO; // 交传
                [self.delegate HeadsetUnplugged];
                break;
            case AVAudioSessionRouteChangeReasonCategoryChange:
                break;
        }
    });
}


#pragma mark - CYIflyRecognizerDelegate

- (void)iflySpeechVolumeChanged:(int)volume {
    if ([self.delegate respondsToSelector:@selector(speechVolumeChanged:)]) {
        [self.delegate speechVolumeChanged:volume];
    }
}

- (void)iflyOnError:(NSDictionary *)errorDict {
    if ([self.delegate respondsToSelector:@selector(onSpeechError:)]) {
        [self.delegate onSpeechError:errorDict];
    }
}


#pragma mark - lazy load

- (CYIflyRecognizer *)iflyRecognizer {
    if (_iflyRecognizer == nil) {
        _iflyRecognizer = [CYIflyRecognizer shareInstance];
        _iflyRecognizer.delegate = self;
    }
    return _iflyRecognizer;
}

- (CYSiriRecognizer *)siriRecognizer {
    if (_siriRecognizer == nil) {
        _siriRecognizer = [CYSiriRecognizer shareInstance];
    }
    return _siriRecognizer;
}

- (CYSpeaker *)speaker {
    if (_speaker == nil) {
        _speaker = [CYSpeaker shareInstance];
    }
    return _speaker;
}

- (CYThreadRunloop *)threadLoop {
    if (_threadLoop == nil) {
        _threadLoop = [CYThreadRunloop shareInstance];
    }
    return _threadLoop;
}

- (CYCollectionQueue *)collectionQueue {
    if (_collectionQueue == nil) {
        _collectionQueue = [CYCollectionQueue shareInstance];
    }
    return _collectionQueue;
}

@end







