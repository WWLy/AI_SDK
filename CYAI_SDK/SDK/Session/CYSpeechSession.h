//
//  CYSpeechSession.h
//  CYAI_SDK
//
//  Created by WWLy on 29/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYSessionWords.h"


@interface CYSpeechSession : NSObject

// 把当前时间戳作为 id (精确到豪秒)
@property (nonatomic, assign) long long sessionId;

// 当某一方得到结果时的时间点
@property (nonatomic, assign) long long flagTime;

// 讯飞识别及翻译
@property (nonatomic, strong) CYSessionWords *iflySessionWords;

// siri 识别及翻译
@property (nonatomic, strong) CYSessionWords *siriSessionWords;

// 选中的结果(待合成的结果)
@property (nonatomic, strong) CYSessionWords *adoptSessionWords;


@end
