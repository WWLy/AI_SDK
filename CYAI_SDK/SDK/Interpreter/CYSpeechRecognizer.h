//
//  SpeechRecognizer.h
//  AI_SDK
//
//  Created by WWLy on 28/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYCollectionQueue.h"
#import "CYLanguageDefine.h"
@class CYSpeaker, CYThreadRunloop;


typedef enum : NSUInteger {
    CYDetectLanguageAuto,    // 自动
    CYDetectLanguageEnglish, // 英->中
    CYDetectLanguageChinese  // 中->英
} CYDetectLanguage; // 语言类型


@protocol CYSpeechRecognizerDelegate <NSObject>



- (void)beginSayTextWithSource:(NSString *)source target:(NSString *)target;

- (void)whenSpeakerOver;

@end


@interface CYSpeechRecognizer : NSObject


@property (nonatomic, assign) CYDetectLanguage detectLanguage;

@property (nonatomic, strong) CYSpeaker *speaker;

@property (nonatomic, strong) CYThreadRunloop *threadLoop;

@property (nonatomic, strong) CYCollectionQueue *collectionQueue;

// 语音合成状态
@property (nonatomic, assign) BOOL isSpeaking;


@property (nonatomic, assign) id <CYSpeechRecognizerDelegate> delegate;

+ (instancetype)shareInstance;

// 开启讯飞和 siri 的语音识别
- (void)startRecognizers;

// 停止讯飞和 siri 的语音识别
- (void)stopRecognizers;

- (void)sayTextAuto;

- (void)sayText:(NSString *)text;


// 直接输入一段文字给，返回翻译结果
- (void)transText:(NSString *)sourceStr languageType:(CYLanguageType) languageType complete:(void(^)(NSString *))complete;


@end
