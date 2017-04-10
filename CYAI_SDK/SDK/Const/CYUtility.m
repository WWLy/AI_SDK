//
//  CYUtility.m
//  caiyunInterpreter
//
//  Created by hyz on 16/12/5.
//  Copyright © 2016年 北京彩彻区明科技有限公司. All rights reserved.
//

#import "CYUtility.h"

@implementation CYUtility

+(BOOL)didContainChineseStr:(NSString *)originalStr{

    NSError * error;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\p{Script=Han}" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:originalStr
                                                        options:0
                                                          range:NSMakeRange(0, [originalStr length])];
    
    return numberOfMatches>0 ? YES : NO;
    
    /*
    //originalStr = @"春1mianBU觉晓";
    for (int i = 0; i<[originalStr length]; i++)
    {
        NSString *oneChar = [originalStr substringWithRange:NSMakeRange(i,1)];
        const char *u8Temp = [oneChar UTF8String];
        CYLog(@"%s",u8Temp);
        if (3==strlen(u8Temp)){
            CYLog(@"字符串中含有中文");
            return YES;
        }
    }
    return NO;
     */
}

+(BOOL)aString:(NSString*)aString  containsbString:(NSString*)bString{
    
    //if ([minutyly_description containsString:@"不会"]) {//iOS7中没有的函数
    //CYLog(@"aString:%@,bString:%@",aString,bString);
    
    if (bString == nil || bString.length == 0){
        return NO;
    }
    
    if ([aString rangeOfString:bString].location != NSNotFound) {
        return YES;
    }else{
        return NO;
    }
}

//目前为三种语言:zh_CN,zh_TW,en_US
+(NSString*)systemLanguage{
    NSArray *systemLanguages = [NSLocale preferredLanguages];
    NSString *currentLanguage = [systemLanguages objectAtIndex:0];
    
    //    CYLog(@"systemLanguages are %@",systemLanguages);
    //    CYLog(@"language is %@",currentLanguage);
    
    //if ([currentLanguage containsString:@"en-"]) {//英文:en-CN,en-US等(语言-国家？)
    if ([CYUtility aString:currentLanguage containsbString:@"en-"]||[CYUtility aString:currentLanguage containsbString:@"en"]) {//英文:en-CN,en-US等(语言-国家？)
        NSLog(@"return en_US");
        return @"en_US";
    }else if(  [CYUtility aString:currentLanguage containsbString:@"zh-"]) {//中文
        //zh-Hans-US:简体中文
        //zh-Hant-US:繁体中文
        //zh-HK:繁体中文,香港
        //zh-TW:繁体中文,台湾
        if (  [CYUtility aString:currentLanguage containsbString:@"zh-Hans"]||[CYUtility aString:currentLanguage containsbString:@"zh-CN"]) {
            //简体中文:zh-Hans-CN
            NSLog(@"return zh_CN");
            return @"zh_CN";
        }else{
            NSLog(@"return zh_TW");
            //繁体中文:zh-Hant-CN,zh-HK,zh-TW等
            return @"zh_TW";
        }
    }else{
        NSLog(@"return zh_CN");
        return @"zh_CN";
    }
}



+(void)postNotificationWithName:(NSString*)name object:(id)obj
{
    //信息更新后，创建通知
    NSNotification * aNotification = [NSNotification notificationWithName:name object:obj];
    
    //通过通知中心，发送通知。
    NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotification:aNotification];
}
@end
