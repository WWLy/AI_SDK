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

// 当 siri 和讯飞都得到结果后进行置信度的判断
+ (void)makeDecisionOnTransAllReady {
    CYCollectionQueue *queue = [CYSpeechRecognizer shareInstance].collectionQueue;
    CYSpeechSession *session = queue.recognizeQueue.firstObject;
    if (session == nil) {
        return;
    }
    
}

// 识别语言的语种
+ (void)detectLanguage:(CYSpeechSession *)session {
    CYDetectLanguage language = [CYSpeechRecognizer shareInstance].detectLanguage;
    // 如果用户指定了源语言
    if (language != CYDetectLanguageAuto) {
        if (language == CYDetectLanguageEnglish) {
            session.adoptSessionWords = session.siriSessionWords;
        } else if (language == CYDetectLanguageChinese) {
            session.adoptSessionWords = session.iflySessionWords;
        }
        return;
    }
    // 如果用户设置的自动模式就需要利用神经网络去判断语种
    float myvariable[4];
    myvariable[0] = session.siriSessionWords.asrConfidence;
    myvariable[1] = session.siriSessionWords.transConfidence;
    myvariable[2] = session.iflySessionWords.asrConfidence;
    myvariable[3] = session.iflySessionWords.transConfidence;
    
    // 调用神经网络方法进行识别
    NSLog(@"利用神经网络开始识别");
    float nn_res = bnns_predict(myvariable);
    // 中文
    if (nn_res < 0.4) {
        session.adoptSessionWords = session.iflySessionWords;
    }
    // 英文
    else {
        session.adoptSessionWords = session.siriSessionWords;
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


























