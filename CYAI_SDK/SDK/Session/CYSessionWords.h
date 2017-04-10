//
//  CYSessionWords.h
//  CYAI_SDK
//
//  Created by WWLy on 29/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum : NSUInteger {
    CYRecognizeTypeIfly,
    CYRecognizeTypeSiri
} CYRecognizeType;


@interface CYSessionWords : NSObject

// 识别器类型
@property (nonatomic, assign) CYRecognizeType recognizeType;

// 语音识别后的文字(ASR words)
@property (nonatomic, copy) NSString *asrWords;

// 翻译后的文字
@property (nonatomic, copy) NSString *transWords;

// 识别置信度
@property (nonatomic, assign) double asrConfidence;

// 翻译置信度
@property (nonatomic, assign) double transConfidence;



@end
