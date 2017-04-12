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

- (void)beginSayTextWithSource:(NSString *)source target:(NSString *)target; // 开始语音合成回调

- (void)whenSpeakerOver; // 语音合成结束回调

- (void)HeadsetUnplugged; // 耳机拔出

- (void)HeadsetPluggedIn; // 耳机插入

- (void)speechVolumeChanged:(int)volume; // 音量变化

@end


@interface CYSpeechRecognizer : NSObject

@property (nonatomic, assign) CYDetectLanguage  detectLanguage;

@property (nonatomic, strong) CYSpeaker         *speaker;

@property (nonatomic, strong) CYThreadRunloop   *threadLoop;

@property (nonatomic, strong) CYCollectionQueue *collectionQueue;

@property (nonatomic, assign) BOOL              isSpeaking;// 语音合成状态

@property (nonatomic, assign) id <CYSpeechRecognizerDelegate> delegate;

@property bool isSimultaneousInterpretation; //同传or交传


#pragma mark - Function

+ (instancetype)shareInstance;

// 开启讯飞和 siri 的语音识别
- (void)startRecognizers;

// 停止讯飞和 siri 的语音识别
- (void)stopRecognizers;

// 自动语音合成
- (void)sayTextAuto;

// 手动语音合成
- (void)sayText:(NSString *)text;

/**
 直接输入一段文字，返回翻译结果

 @param sourceStr 需要翻译的文本
 @param languageType 需要翻译的文本类型
 @param complete 翻译结果回调
 */
- (void)transText:(NSString *)sourceStr languageType:(CYLanguageType) languageType complete:(void(^)(NSString *transWords))complete;


// 设置中文口音识别
- (void)setiFlyAccent:(ChineseAccent)accentEnum;

@end
