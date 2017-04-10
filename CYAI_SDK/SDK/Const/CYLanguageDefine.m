//
//  CYLanguageDefine.m
//  caiyunInterpreter
//
//  Created by hyz on 2017/1/17.
//  Copyright © 2017年 北京彩彻区明科技有限公司. All rights reserved.
//

#import "CYLanguageDefine.h"

@implementation CYLanguageDefine

+ (NSString*)chineseAccentStr:(ChineseAccent)cnAccentEnum {
    switch (cnAccentEnum) {
        case ChineseAccent_PuTongHua:
            return  NSLocalizedString(@"mandarin_accent", nil);
            break;
        case ChineseAccent_YueYu:
            return  NSLocalizedString(@"cantonese_accent", nil);
            break;
        case ChineseAccent_HeNanHua:
            return  NSLocalizedString(@"henan_dialect_accent", nil);
            break;
        case ChineseAccent_SiChuanHua:
            return  NSLocalizedString(@"sichuan_dialect_accent", nil);
            break;
        default:
            return  NSLocalizedString(@"mandarin_accent", nil);
            break;
    }
}

+ (NSString*)englishAccentStr:(EnglishAccent)enAccentEnum {
    switch (enAccentEnum) {
        case EnglishAccent_US:
            return NSLocalizedString(@"american_english_accent", nil);
            break;
        case EnglishAccent_British:
            return NSLocalizedString(@"british_english_accent", nil);
            break;
        case EnglishAccent_Australian:
            return NSLocalizedString(@"australian_english_accent", nil);
            break;
        case EnglishAccent_Canadian:
            return NSLocalizedString(@"canadian_english_accent", nil);
            break;
        case EnglishAccent_Indian:
            return NSLocalizedString(@"indian_english_accent", nil);
            break;
        default:
            return NSLocalizedString(@"american_english_accent", nil);
            break;
    }
}

+ (NSString*)iFlyAccentStr:(ChineseAccent)cnAccentEnum {
    switch (cnAccentEnum) {
        case ChineseAccent_PuTongHua:
            return  PUTONGHUA;
            break;
        case ChineseAccent_YueYu:
            return  YUEYU;
            break;
        case ChineseAccent_HeNanHua:
            return  HENANHUA;
            break;
        case ChineseAccent_SiChuanHua:
            return  SICHUANHUA;
            break;
        default:
            return  PUTONGHUA;
            break;
    }
}

@end
