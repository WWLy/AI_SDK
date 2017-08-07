//
//  CYSpeechSession.m
//  CYAI_SDK
//
//  Created by WWLy on 29/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import "CYSpeechSession.h"

@interface CYSpeechSession ()


@end


@implementation CYSpeechSession

- (instancetype)init {
    if (self = [super init]) {
        NSLog(@"Session被创建了");
    }
    return self;
}

- (void)setSessionId:(long long)sessionId {
    _sessionId = sessionId;
    NSLog(@"sessionId 被赋值: %zd", sessionId);
}

- (void)setFlagTime:(long long)flagTime {
    _flagTime = flagTime;
    NSLog(@"flagTime 被赋值: %zd", flagTime);
}


@end


