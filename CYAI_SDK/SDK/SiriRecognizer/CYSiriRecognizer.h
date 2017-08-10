//
//  CYSiriRecognizer.h
//  CYAI_SDK
//
//  Created by WWLy on 29/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYLanguageDefine.h"

@interface CYSiriRecognizer : NSObject

@property (nonatomic, strong) NSString * sfRecognizePartialResult;
@property (nonatomic, assign) float sfRecognizePartialResultConfidence;

/// 此处用 block 为了解耦 第一个参数是识别结果, 第二个参数是识别置信度
@property (nonatomic, copy) void (^finishRecognizeBlock)(NSString *, float, CYRecognizeType);

/// 控制是否记录录音结果, 为 false 时不处理
@property (nonatomic, assign) BOOL sf_do_not_send_user_is_speaking;
/// 控制是否识别录音结果, 为 false 时录音会被保存, 但是不进行识别
@property (nonatomic, assign) BOOL sf_can_handle_audio;

@property (nonatomic, assign) CYDetectLanguage detectLanguage;


+ (instancetype)shareInstance;

/// 开始语音识别
- (void)startRecognizer;
/// 停止语音识别
- (void)stopRecognizer;

/// 开始录音并处理数据
- (void)startListen;
/// 结束录音并停止处理
- (void)stopListen;

/// 开始录音
- (void)startAVCapture;
/// 结束录音
- (void)endAVCapture;

/// 处理录音结束并开始识别 录音状态没有改变
- (void)startHandleRecognitionRequest;

@end
