//
//  CYDataCollector.m
//  CYAI_SDK
//
//  Created by WWLy on 06/04/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import "CYDataCollector.h"
#import "CYSpeechRecognizer.h"
#import "CYSpeechSession.h"
#import "Config.h"


@implementation CYDataCollector

+ (void)postDataToServer:(CYSpeechSession *)session {
    
    CYSpeechRecognizer *recognizer = [CYSpeechRecognizer shareInstance];
    NSString *target = @"auto";
    if ([recognizer currentDetectLanguage] == CYDetectLanguageChinese) {
        target = @"zh";
    } else if ([recognizer currentDetectLanguage] == CYDetectLanguageEnglish) {
        target = @"en";
    }
    
    NSString * postdata = [NSString stringWithFormat:@"{\"target\": \"%@\", \"zh2en\": \"%@\", \"zh_source\": \"%@\", \"en_source\": \"%@\", \"en2zh\": \"%@\", \"features\": [%f, %f, %f, %f], \"client_type\":\"ios\"}", target, session.iflySessionWords.transWords, session.iflySessionWords.asrWords, session.fullSiriSessionWords.asrWords, session.fullSiriSessionWords.transWords, session.fullSiriSessionWords.asrConfidence, session.fullSiriSessionWords.transConfidence, session.iflySessionWords.asrConfidence, session.iflySessionWords.transConfidence];
    
    
    NSString *urlStr = [[Config initOnce] getValue:@"data_collector_api"];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[postdata dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                      if (error != nil) {
                                          NSLog(@"数据上传失败");
                                      } else {
                                          NSLog(@"数据上传成功");
                                      }
                                  }];
    
    [task resume];
}

@end
