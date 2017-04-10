//
//  CYSiriRecognizer.h
//  CYAI_SDK
//
//  Created by WWLy on 29/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CYSiriRecognizer : NSObject

@property (nonatomic, strong) NSString * sfRecognizePartialResult;
@property (nonatomic, assign) float sfRecognizePartialResultConfidence;

// 此处用 block 为了解耦 第一个参数是识别结果, 第二个参数是识别置信度
@property (nonatomic, copy) void(^finishRecognizeBlock)(NSString *, float);

@property (nonatomic, assign) BOOL sf_do_not_send_user_is_speaking;

@property (nonatomic, assign) BOOL sf_can_handle_audio;


+ (instancetype)shareInstance;

- (void)startRecognizer;

- (void)stopRecognizer;

// 开始录音
- (void)startListen;

// 停止录音
- (void)endListen;


- (void)temp;

@end
