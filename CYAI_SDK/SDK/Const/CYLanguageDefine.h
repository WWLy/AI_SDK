//
//  CYLanguageDefine.h
//  caiyunInterpreter
//
//  Created by hyz on 2017/1/17.
//  Copyright © 2017年 北京彩彻区明科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PUTONGHUA   @"mandarin"
#define YUEYU       @"cantonese"
#define HENANHUA    @"henanese"
#define SICHUANHUA  @"lmz"
#define ENGLISH     @"en_us"
#define CHINESE     @"zh_cn";


typedef enum : NSUInteger {
    CYLanguageTypeChinese,
    CYLanguageTypeEnglish
} CYLanguageType;

typedef enum : NSUInteger {
    CYDetectLanguageAuto,    // 自动
    CYDetectLanguageEnglish, // 英->中
    CYDetectLanguageChinese  // 中->英
} CYDetectLanguage; // 语言类型

typedef enum : NSUInteger {
    CYRecognizeTypeIfly,
    CYRecognizeTypeSiriPart,
    CYRecognizeTypeSiriFull,
} CYRecognizeType; // 识别回调类型

typedef enum : NSUInteger {
    ShowLanguageChinese,
    ShowLanguageEnglish
} ShowLanguage; 

typedef enum : NSUInteger {
    ChineseAccent_PuTongHua,
    ChineseAccent_YueYu,
    ChineseAccent_HeNanHua,
    ChineseAccent_SiChuanHua,
    ChineseAccent_Number//中文口音的总数量,总放在枚举值的最后
} ChineseAccent;

typedef enum : NSUInteger {
    EnglishAccent_US,
    EnglishAccent_British,
    EnglishAccent_Australian,
    EnglishAccent_Canadian,
    EnglishAccent_Indian,
    EnglishAccent_Number//英文口音的总数量,总放在枚举值的最后
} EnglishAccent;


@interface CYLanguageDefine : NSObject

+ (NSString*)chineseAccentStr:(ChineseAccent)cnAccentEnum;
+ (NSString*)englishAccentStr:(EnglishAccent)enAccentEnum;
+ (NSString*)iFlyAccentStr:(ChineseAccent)cnAccentEnum;


@end
