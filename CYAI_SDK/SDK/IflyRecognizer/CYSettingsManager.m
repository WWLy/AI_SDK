//
//  CYSettingsManager.m
//  caiyunInterpreter
//
//  Created by hyz on 2017/1/17.
//  Copyright © 2017年 北京彩彻区明科技有限公司. All rights reserved.
//

#import "CYSettingsManager.h"
#import "CYLanguageDefine.h"

static CYSettingsManager * _instance;


@implementation CYSettingsManager

//单例模式
+ (instancetype)defaultSettingsManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        
        NSDictionary* defaultPrefs = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @(ChineseAccent_PuTongHua),@"selected_chinese_accent",
                                      @(EnglishAccent_US),@"selected_english_accent",
                                      nil];
        
        [defaults registerDefaults:defaultPrefs];//第一次启动时设置的默认值

        _selectedChineseAccent = [defaults integerForKey:@"selected_chinese_accent"];
        _selectedEnglishAccent = [defaults integerForKey:@"selected_english_accent"];
    }
    return self;
}

- (void)setSelectedChineseAccent:(ChineseAccent)selectedChineseAccent {
    _selectedChineseAccent = selectedChineseAccent;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:_selectedChineseAccent forKey:@"selected_chinese_accent"];
}

- (void)setSelectedEnglishAccent:(EnglishAccent)selectedEnglishAccent {
    _selectedEnglishAccent = selectedEnglishAccent;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:_selectedEnglishAccent forKey:@"selected_english_accent"];
}

@end
