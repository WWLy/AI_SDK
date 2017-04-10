//
//  CYIflyRecognizer.h
//  CYAI_SDK
//
//  Created by WWLy on 28/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYLanguageDefine.h"

@interface CYIflyRecognizer : NSObject

// 此处用 block 为了解耦 第一个参数是识别结果, 第二个参数是识别置信度
@property (nonatomic, copy) void(^finishRecognizeBlock)(NSString *, float);


+ (instancetype)shareInstance;

- (void)initiFlySpeechRecognizer;

// 设置中文口音识别
- (void)setiFlyAccent:(ChineseAccent)accentEnum;

// 开始语音识别
- (void)startListen;

// 取消此次回话, 停止识别
- (void)stopListen;

- (void)stopListening;

@end
