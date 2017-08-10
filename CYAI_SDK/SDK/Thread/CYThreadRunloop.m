//
//  CYThreadRunloop.m
//  CYAI_SDK
//
//  Created by WWLy on 05/04/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import "CYThreadRunloop.h"
#import "CYSpeechRecognizer.h"
#import "CYPolicyMaker.h"
#import "CYSpeaker.h"
#import "CYDataCollector.h"

@interface CYThreadRunloop ()

@property (nonatomic, strong) NSTimer *timer;

@end

//static NSUInteger const largestWaitTime = 2000;
static float const interval = 100.0 / 1000.0;
//static float const wholeWaitTime = 3000.0;

static id _instance;

@implementation CYThreadRunloop

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (void)startRunLoop {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 开启一条子线程
        NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(newThread) object:nil];
        [thread start];
    });
}

- (void)newThread {
    
    self.timer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(check) userInfo:nil repeats:YES];
    
    // 只要调用currentRunLoop方法, 系统就会自动创建一个RunLoop, 添加到当前线程中
    NSRunLoop *runloop = [NSRunLoop currentRunLoop]; // 这个方法是懒加载
    
    [runloop addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    [runloop run];
}

- (void)check {
    
    [[CYSpeechRecognizer shareInstance] sayTextAuto];
    
    CYCollectionQueue *queue = [CYSpeechRecognizer shareInstance].collectionQueue;
    CYSpeechSession *session = queue.recognizeQueue.firstObject;
    
    long long timeIntevel = [[NSDate date] timeIntervalSince1970] * 1000;
    
    if (session == nil) {
        return;
    }
    // 根据识别模式进行处理
    CYDetectLanguage language = [[CYSpeechRecognizer shareInstance] currentDetectLanguage];
    if (language == CYDetectLanguageAuto) {
        [self detectLanguageAutoCheck:timeIntevel];
    } else if (language == CYDetectLanguageChinese) {
        [self detectLanguageChineseCheck:timeIntevel];
    } else if (language == CYDetectLanguageEnglish) {
        [self detectLanguageEnglishCheck:timeIntevel];
    }
    
    if (session.fullSiriSessionWords.asrWords != nil && session.fullSiriSessionWords.transWords != nil && session.iflySessionWords.asrWords != nil && session.iflySessionWords.transWords != nil) {
//    if (session.adoptSessionWords.asrWords != nil) {
        // 开始上传数据
        NSLog(@"开始上传数据");
        [CYDataCollector postDataToServer:session];
    }
}

- (void)detectLanguageAutoCheck:(long long)timeIntevel {
    CYCollectionQueue *queue = [CYSpeechRecognizer shareInstance].collectionQueue;
    CYSpeechSession *session = queue.recognizeQueue.firstObject;
    // 如果讯飞和 siri 都得到翻译结果了
    if (session.fullSiriSessionWords.transWords != nil && session.iflySessionWords.transWords != nil) {
        NSLog(@"detectLanguageAutoCheck 讯飞和 siri 都得到结果");
        // 判断语种
        if ([CYPolicyMaker detectLanguage:session] == CYLanguageTypeChinese) {
            session.adoptSessionWords = session.iflySessionWords;
        } else {
            session.adoptSessionWords = session.fullSiriSessionWords;
        }
        // 把这个 session 从翻译队列拿到合成队列
        [queue.recognizeQueue removeObject:session];
        [queue.abandonPool addObject:@(session.sessionId)];
        [queue.speakQueue addObject:session];
    }
    // 如果讯飞得到翻译结果但是 siri 没有翻译结果
    else if (session.iflySessionWords.transWords != nil && session.fullSiriSessionWords.transWords == nil) {
        // 判断是否超时, 如果超时则不再等待, 最多等待1.4s
        if (timeIntevel > session.sessionId + 1400) {
            NSLog(@"detectLanguageAutoCheck 讯飞得到结果但是 siri 没有结果 超时");
            if (session.fullSiriSessionWords == nil) {
                session.fullSiriSessionWords = [[CYSessionWords alloc] init];
            }
            session.fullSiriSessionWords.asrWords = @"";
            session.fullSiriSessionWords.asrConfidence = 0;
            session.fullSiriSessionWords.transWords = @"";
            session.fullSiriSessionWords.transConfidence = 0;
            
            // 判断语种
            if ([CYPolicyMaker detectLanguage:session] == CYLanguageTypeChinese) {
                session.adoptSessionWords = session.iflySessionWords;
            } else {
                session.adoptSessionWords = session.fullSiriSessionWords;
            }
            
            [queue.recognizeQueue removeObject:session];
            [queue.abandonPool addObject:@(session.sessionId)];
            [queue.speakQueue addObject:session];
            
        } else {
            NSLog(@"detectLanguageAutoCheck 讯飞得到结果但是 siri 没有结果 直接人为判断");
            // 此时利用神经网络判断语种, 如果为中文且 识别置信度>0.9, 放弃英文会话
            if ([CYPolicyMaker detectLanguage:session] == CYLanguageTypeChinese && session.iflySessionWords.asrConfidence > 0.9) {
                NSLog(@"detectLanguageAutoCheck 讯飞得到结果但是 siri 没有结果 满足人为条件");
                session.adoptSessionWords = session.iflySessionWords;
                [queue.recognizeQueue removeObject:session];
                [queue.abandonPool addObject:@(session.sessionId)];
                [queue.speakQueue addObject:session];
            }
        }
    }
    // 如果讯飞得到翻译结果但是 siri 没有得到完整识别结果
    else if (session.iflySessionWords.transWords != nil && session.fullSiriSessionWords.transWords == nil) {
        // 判断是否超时, 如果超时则不再等待, 最多等待1.4s
        if (timeIntevel > session.sessionId + 1400) {
            NSLog(@"detectLanguageAutoCheck 讯飞得到结果但是 siri 没有结果 超时");
            if (session.fullSiriSessionWords == nil) {
                session.fullSiriSessionWords = [[CYSessionWords alloc] init];
            }
            session.fullSiriSessionWords.asrWords = @"";
            session.fullSiriSessionWords.asrConfidence = 0;
            session.fullSiriSessionWords.transWords = @"";
            session.fullSiriSessionWords.transConfidence = 0;
            
            // 判断语种
            if ([CYPolicyMaker detectLanguage:session] == CYLanguageTypeChinese) {
                session.adoptSessionWords = session.iflySessionWords;
            } else {
                session.adoptSessionWords = session.fullSiriSessionWords;
            }
            
            [queue.recognizeQueue removeObject:session];
            [queue.abandonPool addObject:@(session.sessionId)];
            [queue.speakQueue addObject:session];
        }
        // 如果没有超时
        else {
            NSLog(@"detectLanguageAutoCheck 讯飞得到结果但是 siri 没有结果 直接人为判断");
            // 此时利用神经网络判断语种, 如果为中文且 识别置信度>0.9, 放弃英文会话
            if ([CYPolicyMaker detectLanguage:session] == CYLanguageTypeChinese && session.iflySessionWords.asrConfidence > 0.9) {
                NSLog(@"detectLanguageAutoCheck 讯飞得到结果但是 siri 没有结果 满足条件");
                session.adoptSessionWords = session.iflySessionWords;
                [queue.recognizeQueue removeObject:session];
                [queue.abandonPool addObject:@(session.sessionId)];
                [queue.speakQueue addObject:session];
            }
        }
    }
    // 如果 siri 得到完整翻译结果但是讯飞没得到翻译结果
    else if (session.fullSiriSessionWords.transWords != nil && session.iflySessionWords.transWords == nil) {
        // 判断是否超时, 如果超时则不再等待
        if (timeIntevel > session.sessionId + 1400) {
            NSLog(@"detectLanguageAutoCheck siri 得到结果但是讯飞没得到结果 超时");
            if (session.iflySessionWords == nil) {
                session.iflySessionWords = [[CYSessionWords alloc] init];
            }
            session.iflySessionWords.asrWords = @"";
            session.iflySessionWords.asrConfidence = 0;
            session.iflySessionWords.transWords = @"";
            session.iflySessionWords.transConfidence = 0;
            
            session.adoptSessionWords = session.fullSiriSessionWords;
            
            [queue.recognizeQueue removeObject:session];
            [queue.abandonPool addObject:@(session.sessionId)];
            [queue.speakQueue addObject:session];
        }
    }
    // 如果讯飞和 siri 都识别出来了 但是都没有翻译结果
    else if (session.iflySessionWords.asrWords != nil && session.fullSiriSessionWords.asrWords != nil) {
        // 如果超时, 放弃会话
        if (timeIntevel > session.sessionId + 2000) {
            NSLog(@"detectLanguageAutoCheck 讯飞和 siri 都识别出来了 但是都没有翻译结果 超时 sessionId: %zd   time: %zd", session.sessionId, time);
            session.iflySessionWords.transWords = @"";
            session.iflySessionWords.transConfidence = 0;
            session.fullSiriSessionWords.transWords = @"";
            session.fullSiriSessionWords.transConfidence = 0;
            [queue.recognizeQueue removeObject:session];
            [queue.abandonPool addObject:@(session.sessionId)];
//            [queue.speakQueue addObject:session];
        }
    }
    // 如果讯飞识别出来了 siri 没有
    else if (session.iflySessionWords.asrWords != nil && session.fullSiriSessionWords.asrWords == nil) {
        // 如果超时 放弃会话
        if (timeIntevel > session.sessionId + 2000) {
            NSLog(@"detectLanguageAutoCheck 讯飞识别出来了 siri 没有  超时 sessionId: %zd   time: %zd", session.sessionId, time);
            session.iflySessionWords.transWords = @"";
            session.iflySessionWords.transConfidence = 0;
            session.fullSiriSessionWords = [[CYSessionWords alloc] init];
            session.fullSiriSessionWords.asrWords = @"";
            session.fullSiriSessionWords.asrConfidence = 0;
            session.fullSiriSessionWords.transWords = @"";
            session.fullSiriSessionWords.transConfidence = 0;
            [queue.recognizeQueue removeObject:session];
            [queue.abandonPool addObject:@(session.sessionId)];
//            [queue.speakQueue addObject:session];
        }
    }
    // 如果 siri 识别出来了 讯飞没有
    else if (session.fullSiriSessionWords.asrWords != nil && session.iflySessionWords.asrWords == nil) {
        // 如果超时
        if (timeIntevel > session.sessionId + 2000) {
            NSLog(@"detectLanguageAutoCheck siri 识别出来了 讯飞没有  超时 sessionId: %zd   time: %zd", session.sessionId, time);
            session.iflySessionWords = [[CYSessionWords alloc] init];
            session.iflySessionWords.asrWords = @"";
            session.iflySessionWords.asrConfidence = 0;
            session.iflySessionWords.transWords = @"";
            session.iflySessionWords.transConfidence = 0;
            session.fullSiriSessionWords.transWords = @"";
            session.fullSiriSessionWords.transConfidence = 0;
            [queue.recognizeQueue removeObject:session];
            [queue.abandonPool addObject:@(session.sessionId)];
//            [queue.speakQueue addObject:session];
        }
    }
    // 其他
    else {
        // 如果超时
        if (timeIntevel > session.sessionId + 2000) {
            NSLog(@"detectLanguageAutoCheck 默认处理");
            session.iflySessionWords = [[CYSessionWords alloc] init];
            session.iflySessionWords.asrWords = @"";
            session.iflySessionWords.asrConfidence = 0;
            session.iflySessionWords.transWords = @"";
            session.iflySessionWords.transConfidence = 0;
            session.fullSiriSessionWords.transWords = @"";
            session.fullSiriSessionWords.transConfidence = 0;
            [queue.recognizeQueue removeObject:session];
            [queue.abandonPool addObject:@(session.sessionId)];
//            [queue.speakQueue addObject:session];
        }
    }
//    // 如果该 session 处理结束
//    if (session.fullSiriSessionWords.asrWords != nil && session.fullSiriSessionWords.transWords != nil && session.iflySessionWords.asrWords != nil && session.iflySessionWords.transWords != nil) {
//        // 判断语种
////        [CYPolicyMaker detectLanguage:session];
//    }
}

// 中文 -> 英文
- (void)detectLanguageChineseCheck:(long long)timeIntevel {
    CYCollectionQueue *queue = [CYSpeechRecognizer shareInstance].collectionQueue;
    CYSpeechSession *session = queue.recognizeQueue.firstObject;
    // 此时只使用讯飞的结果, 不用等待 siri
    // 如果讯飞得到翻译结果
    if (session.iflySessionWords.transWords != nil) {
        session.adoptSessionWords = session.iflySessionWords;
        [queue.recognizeQueue removeObject:session];
        [queue.abandonPool addObject:@(session.sessionId)];
        [queue.speakQueue addObject:session];
    }
    // 如果只得到识别结果
    else if (session.iflySessionWords.asrWords != nil) {
        // 判断是否超时 2000ms
        if (session.sessionId > timeIntevel + 2000) {
            session.iflySessionWords.transWords = @"";
            session.iflySessionWords.transConfidence = 0;
            session.adoptSessionWords = session.iflySessionWords;
            [queue.recognizeQueue removeObject:session];
            [queue.abandonPool addObject:@(session.sessionId)];
            [queue.speakQueue addObject:session];
        }
    }
    // TODO:测试用
    else if (session.iflySessionWords == nil) {
        [queue.recognizeQueue removeObject:session];
    }
    
}

// 英文 -> 中文
- (void)detectLanguageEnglishCheck:(long long)timeIntevel  {
    CYCollectionQueue *queue = [CYSpeechRecognizer shareInstance].collectionQueue;
    CYSpeechSession *session = queue.recognizeQueue.firstObject;
    
    if (session.fullSiriSessionWords.transWords != nil) {
        session.adoptSessionWords = session.fullSiriSessionWords;
        [queue.recognizeQueue removeObject:session];
        [queue.abandonPool addObject:@(session.sessionId)];
        [queue.speakQueue addObject:session];
    }
    // 如果没有翻译结果
    else if (session.fullSiriSessionWords.asrWords != nil) {
        // 判断是否超时 2000ms
        if (session.sessionId > timeIntevel + 2000) {
            session.fullSiriSessionWords.transWords = @"";
            session.fullSiriSessionWords.transConfidence = 0;
            session.adoptSessionWords = session.fullSiriSessionWords;
            [queue.recognizeQueue removeObject:session];
            [queue.abandonPool addObject:@(session.sessionId)];
            [queue.speakQueue addObject:session];
        }
    } else {
        if (session.sessionId > timeIntevel + 2000) {
            [queue.recognizeQueue removeObject:session];
            [queue.abandonPool addObject:@(session.sessionId)];
        }
    }
}



@end
















