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

static NSUInteger const largestWaitTime = 2000;
static float const interval = 100.0 / 1000.0;
static float const wholeWaitTime = 3000.0;

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
    
    long long time = [[NSDate date] timeIntervalSince1970] * 1000;
    
    if (session == nil) {
        return;
    }
    
    // 如果讯飞和 siri 都得到翻译结果了
    if (session.siriSessionWords.transWords != nil && session.iflySessionWords.transWords != nil) {
        // 把这个 session 从翻译队列拿到合成队列
        [queue.recognizeQueue removeObject:session];
        [queue.speakQueue addObject:session];
    }
    // 如果 siri 得到结果但是讯飞没得到结果
    else if (session.siriSessionWords.transWords != nil && session.iflySessionWords.transWords == nil) {
        // 判断是否超时, 如果超时则不再等待
        if (time > session.flagTime + largestWaitTime) {
            NSLog(@"siri 得到结果但是讯飞没得到结果 超时");
            if (session.iflySessionWords == nil) {
                session.iflySessionWords = [[CYSessionWords alloc] init];
            }
            session.iflySessionWords.asrWords = @"";
            session.iflySessionWords.asrConfidence = 0;
            session.iflySessionWords.transWords = @"";
            session.iflySessionWords.transConfidence = 0;
            [queue.recognizeQueue removeObject:session];
            [queue.speakQueue addObject:session];
        }
    }
    // 如果讯飞得到结果但是 siri 没有结果
    else if (session.iflySessionWords.transWords != nil && session.siriSessionWords.transWords == nil) {
        // 判断是否超时, 如果超时则不再等待
        if (time > session.flagTime + largestWaitTime) {
            NSLog(@"讯飞得到结果但是 siri 没有结果 超时");
            if (session.siriSessionWords == nil) {
                session.siriSessionWords = [[CYSessionWords alloc] init];
            }
            session.siriSessionWords.asrWords = @"";
            session.siriSessionWords.asrConfidence = 0;
            session.siriSessionWords.transWords = @"";
            session.siriSessionWords.transConfidence = 0;
            [queue.recognizeQueue removeObject:session];
            [queue.speakQueue addObject:session];
        }
    }
    // 如果讯飞和 siri 都识别出来了 但是都没有翻译结果
    else if (session.iflySessionWords.asrWords != nil && session.siriSessionWords.asrWords != nil) {
        // 如果超时
        if (time > session.sessionId + wholeWaitTime) {
            NSLog(@"讯飞和 siri 都识别出来了 但是都没有翻译结果 超时 sessionId: %zd   time: %zd", session.sessionId, time);
            session.iflySessionWords.transWords = @"";
            session.iflySessionWords.transConfidence = 0;
            session.siriSessionWords.transWords = @"";
            session.siriSessionWords.transConfidence = 0;
            [queue.recognizeQueue removeObject:session];
            [queue.speakQueue addObject:session];
        }
    }
    // 如果讯飞识别出来了 siri 没有
    else if (session.iflySessionWords.asrWords != nil && session.siriSessionWords.asrWords == nil) {
        // 如果超时
        if (time > session.sessionId + wholeWaitTime) {
            NSLog(@"讯飞识别出来了 siri 没有  超时 sessionId: %zd   time: %zd", session.sessionId, time);
            session.iflySessionWords.transWords = @"";
            session.iflySessionWords.transConfidence = 0;
            session.siriSessionWords = [[CYSessionWords alloc] init];
            session.siriSessionWords.asrWords = @"";
            session.siriSessionWords.asrConfidence = 0;
            session.siriSessionWords.transWords = @"";
            session.siriSessionWords.transConfidence = 0;
            [queue.recognizeQueue removeObject:session];
            [queue.speakQueue addObject:session];
        }
    }
    // 如果 siri 识别出来了 讯飞没有
    else if (session.siriSessionWords.asrWords != nil && session.iflySessionWords.asrWords == nil) {
        // 如果超时
        if (time > session.sessionId + wholeWaitTime) {
            NSLog(@"siri 识别出来了 讯飞没有  超时 sessionId: %zd   time: %zd", session.sessionId, time);
            session.iflySessionWords = [[CYSessionWords alloc] init];
            session.iflySessionWords.asrWords = @"";
            session.iflySessionWords.asrConfidence = 0;
            session.iflySessionWords.transWords = @"";
            session.iflySessionWords.transConfidence = 0;
            session.siriSessionWords.transWords = @"";
            session.siriSessionWords.transConfidence = 0;
            [queue.recognizeQueue removeObject:session];
            [queue.speakQueue addObject:session];
        }
    }
    // 其他
    else {
        
    }
    if (session.siriSessionWords.asrWords != nil && session.siriSessionWords.transWords != nil && session.iflySessionWords.asrWords != nil && session.iflySessionWords.transWords != nil) {
        // 开始上传数据
        NSLog(@"开始上传数据");
        [CYDataCollector postDataToServer:session];
        // 判断语种
        [CYPolicyMaker detectLanguage:session];
    }
}






@end
















