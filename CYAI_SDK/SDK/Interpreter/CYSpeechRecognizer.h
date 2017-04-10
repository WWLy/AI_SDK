//
//  SpeechRecognizer.h
//  AI_SDK
//
//  Created by WWLy on 28/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYCollectionQueue.h"
@class CYSpeaker, CYThreadRunloop;


typedef enum : NSUInteger {
    CYDetectLanguageAuto,    // 自动
    CYDetectLanguageEnglish, // 英->中
    CYDetectLanguageChinese  // 中->英
} CYDetectLanguage; // 语言类型


@protocol CYSpeechRecognizerDelegate <NSObject>

- (void)beginSayTextWithSource:(NSString *)source target:(NSString *)target;
                                
@end


@interface CYSpeechRecognizer : NSObject


@property (nonatomic, assign) CYDetectLanguage detectLanguage;

@property (nonatomic, strong) CYSpeaker *speaker;

@property (nonatomic, strong) CYThreadRunloop *threadLoop;

@property (nonatomic, strong) CYCollectionQueue *collectionQueue;


@property (nonatomic, assign) id <CYSpeechRecognizerDelegate> delegate;

+ (instancetype)shareInstance;

// 开启讯飞和 siri 的语音识别
- (void)startRecognizers;

// 停止讯飞和 siri 的语音识别
- (void)stopRecognizers;

- (void)sayTextAuto;

- (void)sayText:(NSString *)text;

@end
