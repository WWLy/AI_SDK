//
//  CYCollectionQueue.m
//  CYAI_SDK
//
//  Created by WWLy on 30/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import "CYCollectionQueue.h"


@interface CYCollectionQueue ()


@end


static id _instance;

@implementation CYCollectionQueue

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.recognizeQueue = [NSMutableArray arrayWithCapacity:5];
        self.speakQueue = [NSMutableArray arrayWithCapacity:5];
    }
    return self;
}

- (CYSpeechSession *)getSpeechSessionWithID:(long long)sessionId {
    NSUInteger sessionCount = self.recognizeQueue.count;
    int i = 0;
    for (; i < sessionCount; ++i) {
        CYSpeechSession *session = self.recognizeQueue[i];
        if (sessionId == session.sessionId) {
            return session;
        }
    }
    // 走到这里说明没有找到, 此时创建一个新的 session 并添加到队列中
    CYSpeechSession *session = [[CYSpeechSession alloc] init];
    session.sessionId = sessionId;
    [self.recognizeQueue addObject:session];
    return session;
}


@end
