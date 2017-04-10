//
//  CYSettingsManager.h
//  caiyunInterpreter
//
//  Created by hyz on 2017/1/17.
//  Copyright © 2017年 北京彩彻区明科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYLanguageDefine.h"

@interface CYSettingsManager : NSObject

@property (nonatomic) ChineseAccent selectedChineseAccent;
@property (nonatomic) EnglishAccent selectedEnglishAccent;

+ (instancetype)defaultSettingsManager;

@end
