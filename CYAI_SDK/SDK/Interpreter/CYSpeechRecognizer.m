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
        [weakSelf.siriRecognizer temp];
        
        [weakSelf handleSessionWithType:CYRecognizeTypeIfly asrWords:resultStr asrConfidence:asrConfidence];
    };
}

// 初始化 siri 识别器
- (void)initSisiRecognizer {
    __weak typeof(self) weakSelf = self;
    self.siriRecognizer.finishRecognizeBlock = ^(NSString *resultStr, float asrConfidence) {
        [weakSelf handleSessionWithType:CYRecognizeTypeSiri asrWords:resultStr asrConfidence:asrConfidence];
    };
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

// 停止讯飞和 siri 的语音识别
- (void)stopRecognizers {
    // 讯飞停止监听
    [self.iflyRecognizer stopRecognizer];
    [self.iflyRecognizer stopListen];
    // siri 停止监听
    [self.siriRecognizer stopRecognizer];
    [self.siriRecognizer stopListen];
}

- (void)handleSessionWithType:(CYRecognizeType)type asrWords:(NSString *)asrWords asrConfidence:(float)asrConfidence {
    /**
     把识别结果转换成 sessionWords 模型
     */
    CYSessionWords *sessionWords = [[CYSessionWords alloc] init];
    sessionWords.asrWords = asrWords;
    sessionWords.asrConfidence = asrConfidence;
    sessionWords.recognizeType = type;
    
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
            NSLog(@"讯飞识别sessionWords: %@ - %f", sessionWords.asrWords, sessionWords.asrConfidence);
            [[CYTranslator shareInstance] translateWithSourceType:CYLanguageTypeChinese sourceString:asrWords complete:^(CYTranslateModel *transModel) {
                speechSession.flagTime = [[NSDate date] timeIntervalSince1970] * 1000;
                sessionWords.transWords = transModel.target;
                sessionWords.transConfidence = transModel.confidence;
                NSLog(@"讯飞翻译sessionWords: %@ - %f", sessionWords.transWords, sessionWords.transConfidence);
            }];
        }
    }
    // 从 siri 识别过来的
    else if (type == CYRecognizeTypeSiri) {
        self.timeIntervel = 0;
        speechSession.siriSessionWords = sessionWords;
        // 如果用户设置了讲中文, 就不执行翻译  否则就进行 英->中
        if (self.detectLanguage != CYDetectLanguageChinese) {
            NSLog(@"Siri识别sessionWords: %@ - %f", sessionWords.asrWords, sessionWords.asrConfidence);
            [[CYTranslator shareInstance] translateWithSourceType:CYLanguageTypeEnglish sourceString:asrWords complete:^(CYTranslateModel *transModel) {
                speechSession.flagTime = [[NSDate date] timeIntervalSince1970] * 1000;
                sessionWords.transWords = transModel.target;
                sessionWords.transConfidence = transModel.confidence;
                NSLog(@"Siri翻译sessionWords: %@ - %f", sessionWords.transWords, sessionWords.transConfidence);
            }];
        }
    }
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
    CYCollectionQueue *queue = [CYCollectionQueue shareInstance];
    CYSpeechSession *session = queue.speakQueue.firstObject;
    if (session == nil) {
        return;
    }
    [queue.speakQueue removeObject:session];
    if ([self.delegate respondsToSelector:@selector(beginSayTextWithSource:target:)]) {
        [self.delegate beginSayTextWithSource:session.adoptSessionWords.asrWords target:session.adoptSessionWords.transWords];
    }
    
    NSString *speakString = session.adoptSessionWords.transWords;
    [self sayText:speakString];
}

- (void)sayText:(NSString *)text {
    
    NSLog(@"开始合成,停止识别");
    self.isSpeaking = true;
    
    // 此时不再识别 siri 录音回调结果
    self.siriRecognizer.sf_do_not_send_user_is_speaking = true;
    
    [self.iflyRecognizer stopListen];
    
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

// 设置讯飞中文口音识别
- (void)setiFlyAccent:(ChineseAccent)accentEnum {
    [self.iflyRecognizer setiFlyAccent:accentEnum];
}


#pragma mark - 耳机拔插事件检测

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







