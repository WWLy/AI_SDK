//
//  CYUtility.h
//  caiyunInterpreter
//
//  Created by hyz on 16/12/5.
//  Copyright © 2016年 北京彩彻区明科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Config.h"

#define CONF_STRING(str) [[Config initOnce] getValue:@str]
#define CONF_DOUBLE(str) [[[Config initOnce] getValue:@str] doubleValue]
#define CONF_INT(str) [[[Config initOnce] getValue:@str] integerValue]

#define CONF_SET_STR(name,str) [[Config initOnce].parmas setObject:str forKey:@name];
#define CONF_SET(key,value) [[Config initOnce]setConfig:key withValue:value];
#define CONF_SYSTEM_TIP(name,language) [[Config initOnce]getSystemTip:name byLanguage:language];

#define color_5ebb8d [UIColor colorWithRed:94/255.0 green:187/255.0 blue:141/255.0 alpha:1.0]//绿色文字

@interface CYUtility : NSObject

+(BOOL)didContainChineseStr:(NSString *)originalStr;
+(void)postNotificationWithName:(NSString*)name object:(id)obj;

+(BOOL)aString:(NSString*)aString  containsbString:(NSString*)bString;
+(NSString*)systemLanguage;

@end
