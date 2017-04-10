//
//  IATConfig.m
//  MSCDemo_UI
//
//  Created by wangdan on 15-4-25.
//  Copyright (c) 2015年 iflytek. All rights reserved.
//

#import "CYLanguageDefine.h"
#import "CYSettingsManager.h"
#import "IATConfig.h"

@implementation IATConfig


+ (IATConfig *)sharedInstance {
    static IATConfig * instance = nil;
    static dispatch_once_t predict;
    dispatch_once(&predict, ^{
        instance = [[IATConfig alloc] init];
    });
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        [self defaultSetting];
        return self;
    }
    return nil;
}

- (void)defaultSetting {
    self.speechTimeout = @"6000000";
    self.vadEos = @"60000";
    self.vadBos = @"60000";
    self.dot = @"1";
    self.sampleRate = @"16000";
    self.language = CHINESE;
    //根据配置文件中保存的值,初始化所识别的中文口音.
    self.accent = [CYLanguageDefine iFlyAccentStr: [CYSettingsManager defaultSettingsManager].selectedChineseAccent];//默认为PUTONGHUA;
    self.haveView = NO;//默认是不带界面的
    self.accentNickName = [[NSArray alloc] initWithObjects:@"粤语",@"普通话",@"河南话",@"英文", @"四川话", nil];
}

+ (NSString *)mandarin {
    return PUTONGHUA;
}
+ (NSString *)cantonese {
    return YUEYU;
}
+ (NSString *)henanese {
    return HENANHUA;
}
+ (NSString *)chinese {
    return CHINESE;
}
+ (NSString *)english {
    return ENGLISH;
}

+ (NSString *)lowSampleRate {
    return @"8000";
}

+ (NSString *)highSampleRate {
    return @"16000";
}

+ (NSString *)isDot {
    return @"1";
}

+ (NSString *)noDot {
    return @"0";
}

@end
