//
//  CYPolicyMaker.m
//  CYAI_SDK
//
//  Created by WWLy on 06/04/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import "CYPolicyMaker.h"
#import "CYSpeechRecognizer.h"
#import "BNNSLanguageDetection.h"



static id _instance;

@implementation CYPolicyMaker

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

float EMPTY_VALUE_PLACEHOLDER = -100;
// 识别语言的语种
+ (CYLanguageType)detectLanguage:(CYSpeechSession *)session {
    CYDetectLanguage language = [[CYSpeechRecognizer shareInstance] currentDetectLanguage];
    // 如果用户指定了源语言
    if (language != CYDetectLanguageAuto) {
        if (language == CYDetectLanguageEnglish) {
//            session.adoptSessionWords = session.fullSiriSessionWords;
            return CYLanguageTypeEnglish;
        } else if (language == CYDetectLanguageChinese) {
//            session.adoptSessionWords = session.iflySessionWords;
            return CYLanguageTypeChinese;
        }
    }
    
    // 如果用户设置的自动模式就需要利用神经网络去判断语种
    /*****
     根据字典conversation内的相应字段,设置4个confidence的浮点数的值。然后扔给神经网络判断语种。
     *****/
    float en2zh_source_confidence, en2zh_target_confidence, zh2en_source_confidence, zh2en_target_confidence = EMPTY_VALUE_PLACEHOLDER;
    en2zh_source_confidence = session.fullSiriSessionWords.asrConfidence ? session.fullSiriSessionWords.asrConfidence : session.partSiriSessionWords.asrConfidence ? session.partSiriSessionWords.asrConfidence : EMPTY_VALUE_PLACEHOLDER;
    en2zh_target_confidence = session.fullSiriSessionWords.transConfidence ? session.fullSiriSessionWords.transConfidence : session.partSiriSessionWords.transConfidence ? session.partSiriSessionWords.transConfidence : EMPTY_VALUE_PLACEHOLDER;
    zh2en_source_confidence = session.iflySessionWords.asrConfidence ? session.iflySessionWords.asrConfidence : EMPTY_VALUE_PLACEHOLDER;
    zh2en_target_confidence = session.iflySessionWords.transConfidence ? session.iflySessionWords.transConfidence : EMPTY_VALUE_PLACEHOLDER;
    
    float myvariable[4];
    myvariable[0] = en2zh_source_confidence;
    myvariable[1] = en2zh_target_confidence;
    myvariable[2] = zh2en_source_confidence;
    myvariable[3] = zh2en_target_confidence;
    
    // 调用神经网络方法进行识别
    NSLog(@"利用神经网络开始识别");
    float nn_res = bnns_predict(myvariable);
    // 中文
    if (nn_res < 0.4) {
//        session.adoptSessionWords = session.iflySessionWords;
        return CYLanguageTypeChinese;
    }
    // 英文
    else {
//        session.adoptSessionWords = session.fullSiriSessionWords;
        return CYLanguageTypeEnglish;
    }
}


- (float)determineContains:(NSString*)subString fullString:(NSString*)fullString {
    float temp;
    if ([subString rangeOfString:fullString].location == NSNotFound)
        temp = 0.0;
    else
        temp = 1.0;
    return temp;
}

@end


























