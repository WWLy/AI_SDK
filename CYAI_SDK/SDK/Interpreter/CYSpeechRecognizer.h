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


@protocol CYSpeechRecognizerDelegate <NSObject>

/**
 语音识别翻译结果回调

 @param resultDict 语音识别翻译结果
 */
- (void)speechInterpreterResultAvailable:(NSDictionary *)resultDict;

/**
 开始语音合成回调

 @param source 语音识别结果
 @param target 翻译结果
 */
- (void)beginSayTextWithSource:(NSString *)source target:(NSString *)target;

/**
 语音合成结束回调
 */
- (void)whenSpeakerOver;

/**
 错误回调
 
 @param errorDict 错误信息
 */
- (void)onSpeechError:(NSDictionary *)errorDict;

/**
 耳机拔出
 */
- (void)HeadsetUnplugged;

/**
 耳机插入
 */
- (void)HeadsetPluggedIn;

/**
 讯飞语音识别过程中音量变化回调

 @param volume 变化的音量
 */
- (void)speechVolumeChanged:(int)volume;

@end


@interface CYSpeechRecognizer : NSObject

@property (nonatomic, strong) CYSpeaker         *speaker;

@property (nonatomic, strong) CYThreadRunloop   *threadLoop;

@property (nonatomic, strong) CYCollectionQueue *collectionQueue;

@property (nonatomic, assign) BOOL              isSpeaking; // 是否正在语音合成

@property (nonatomic, assign) id <CYSpeechRecognizerDelegate> delegate;

@property bool isSimultaneousInterpretation; // 同传or交传


#pragma mark - Function

+ (instancetype)shareInstance;

// 开启讯飞和 siri 的语音识别
- (void)startRecognizers;

// 停止讯飞和 siri 的语音识别
- (void)stopRecognizers;

- (void)startXunfei;

- (void)startSiri;

- (void)stopXunfei;

- (void)stopSiri;


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

/**
 切换语种(识别模式:自动/中文/英文)

 @param detectLanguage 语种
 */
- (void)changeDetectLanguage:(CYDetectLanguage)detectLanguage;

/**
 获取当前的语种

 @return 当前语种(自动/中文/英文)
 */
- (CYDetectLanguage)currentDetectLanguage;

// 设置中文口音识别
- (void)setiFlyAccent:(ChineseAccent)accentEnum;

@end
