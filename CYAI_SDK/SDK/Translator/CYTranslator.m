//
//  CYTranslator.m
//  CYAI_SDK
//
//  Created by WWLy on 29/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import "CYTranslator.h"
#import "CYUtility.h"
#import "CYTranslateModel.h"


@interface CYTranslator ()

@property (nonatomic, strong) CYSpeechSession *session;
@property (nonatomic, strong) CYSessionWords *sessionWords;

@end



static id _instance;

@implementation CYTranslator

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}


- (void)translateWithSourceType:(CYLanguageType)type sourceString:(NSString *)sourceString complete:(void(^)(CYTranslateModel *))complete {
    if (type == CYLanguageTypeChinese) {
        [self Zh2EnTranslateWithSourceString:sourceString complete:complete];
    } else if (type == CYLanguageTypeEnglish) {
        [self En2ZhTranslateWithSourceString:sourceString complete:complete];
    }
}


// 中->英
- (void)Zh2EnTranslateWithSourceString:(NSString *)zh_sourceString complete:(void(^)(CYTranslateModel *))complete {
    [self requestWithSouceString:zh_sourceString transType:@"zh2en" complete:complete];
}

// 英->中
- (void)En2ZhTranslateWithSourceString:(NSString *)en_sourceString complete:(void(^)(CYTranslateModel *))complete {
    [self requestWithSouceString:en_sourceString transType:@"en2zh" complete:complete];
}


- (void)requestWithSouceString:(NSString *)sourceString transType:(NSString *)transType complete:(void(^)(CYTranslateModel *))complete {
    // transType:  en2zh / zh2en
    NSDictionary *param = @{@"source": sourceString,
                            @"trans_type": transType,
                            @"request_id": [[NSNumber alloc] initWithLong:random()]};
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:param options:0 error:&err];
    NSString *data_for_trans = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSString *urlString = CONF_STRING("interpreter_api_url");
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [request addValue:CONF_STRING("ios_token") forHTTPHeaderField:@"X-Authorization"];
    [request setHTTPBody:[data_for_trans dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSession *urlSession = [NSURLSession sharedSession];
    // 原 SDK 这里发送的是同步请求
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"翻译出错: %@", error);
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if ((httpResponse.statusCode == 200 || httpResponse.statusCode == 304) && data != nil) {
            NSLog(@"翻译结束");
            
            NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            CYTranslateModel *model = [[CYTranslateModel alloc] initWithDict:resultDict];
            
            NSString *transResStr = @"";
            /**
             这里翻译结束, 需要对结果进行一些处理, 去掉多余的字符
             */
            if ([transType isEqualToString:@"zh2en"]) {
                model.target = [self processEnglishTranslation:resultDict];
                self.sessionWords.transWords = transResStr;
            } else if ([transType isEqualToString:@"en2zh"]) {
                model.target = [self processChineseTranslation:resultDict];
            }
            // 把翻译结果回调出去
            if (complete != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    complete(model);
                });
            }
        }
    }];
    [dataTask resume];
}


/**
 处理中->英的结果

 @param transDict 翻译得到的英文结果
 */
- (NSString *)processEnglishTranslation:(NSDictionary *)transDict {
    NSString *trans_string = @"";
    if ([transDict objectForKey:@"target"] != nil) {
        trans_string = transDict[@"target"];
    }
    
    trans_string = [trans_string stringByReplacingOccurrencesOfString:@"<unk>"   withString:@"something"];
    trans_string = [trans_string stringByReplacingOccurrencesOfString:@" '"      withString:@"'"];
    trans_string = [trans_string stringByReplacingOccurrencesOfString:@"can n't" withString:@"can not"];
    trans_string = [trans_string stringByReplacingOccurrencesOfString:@" n't"    withString:@"n't"];
    trans_string = [trans_string stringByReplacingOccurrencesOfString:@"\")"     withString:@""];
    trans_string = [trans_string stringByReplacingOccurrencesOfString:@"？"      withString:@" "];
    trans_string = [trans_string stringByReplacingOccurrencesOfString:@"?"       withString:@" "];
    trans_string = [trans_string stringByReplacingOccurrencesOfString:@"。"      withString:@"."];
    trans_string = [trans_string stringByReplacingOccurrencesOfString:@"，"      withString:@","];
    
    if ([trans_string isEqualToString:@"something ."] || [trans_string isEqualToString:@"something."]) {
        trans_string = @"";
    }
    
    return trans_string;
}


/**
 处理英->中的结果
 
 @param transDict 翻译得到的中文结果
 */
- (NSString *)processChineseTranslation:(NSDictionary *)transDict {
    NSString *trans_string = @"";
    if ([transDict objectForKey:@"target"] != nil) {
        trans_string = transDict[@"target"];
    }

    trans_string = [trans_string stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    return trans_string;
}


@end



















