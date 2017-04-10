//
//  Config.m
//  caiyunView
//
//  Created by yuanxingyuan on 15-5-29.
//  Copyright (c) 2015年 北京彩彻区明科技有限公司. All rights reserved.
//

#import "Config.h"

#include <stdlib.h>

#define CONF_SET_INT(name,intValue) [self.parmas setObject:[[NSNumber alloc] initWithInt:intValue] forKey:@name];
#define CONF_SET_DOUBLE(name,dValue) [self.parmas setObject:[[NSNumber alloc] initWithDouble:dValue] forKey:@name];

@interface Config ()


@end

@implementation Config

+ (instancetype)initOnce {
    if (!conf) {
        conf = [[Config alloc] init];
        [conf initConfigLocal];
    }
    return conf;
}



//先读取本地设置
- (void)initConfigLocal {
    
    /*云端目前没有的变量*/
    [self.parmas setObject:@"rnnsearch1.interpreter.algo.dev.caiyunai.com" forKey:@"interpreter_hostname"];//彩云翻译的网址
    [self.parmas setObject:@"81" forKey:@"interpreter_port_en2zh"];//彩云翻译的英->中端口
    [self.parmas setObject:@"82" forKey:@"interpreter_port_zh2en"];//彩云翻译的中->英端口
    
    [self.parmas setObject:@"http://receiver.interpreter.algo.dev.caiyunai.com/languageDetectByFeatures/EIUR383YJD736USHF" forKey:@"data_collector_api"];
    
    NSDictionary * app_launch_oneces = [NSDictionary dictionaryWithObjectsAndKeys:@"您想说点什么,我来帮您翻译",@"zh",@"Please talk, I'll help to translate",@"en",nil];
    [self.parmas setObject:app_launch_oneces forKey:@"app_launch_oneces"];
    
    NSDictionary * headset_out_tips = [NSDictionary dictionaryWithObjectsAndKeys:@"已切换至交传模式",@"zh",@"Switch to normal model",@"en",nil];
    [self.parmas setObject:headset_out_tips forKey:@"headset_out"];
    
    NSDictionary * connecting_when_app_launch_tips = [NSDictionary dictionaryWithObjectsAndKeys:@"连接中...",@"zh",@"Connecting...",@"en",nil];
    [self.parmas setObject:connecting_when_app_launch_tips forKey:@"connecting_when_app_launch"];

    NSDictionary * app_launch_successfully_tips = [NSDictionary dictionaryWithObjectsAndKeys:@"连接成功！您想说点什么,我来帮您翻译",@"zh",@"Connection successful! Just say anything and I will translate it!",@"en",nil];
    [self.parmas setObject:app_launch_successfully_tips forKey:@"app_launch_successfully"];
    
    /*云端已有的变量*/
    NSDictionary * app_launch_tips = [NSDictionary dictionaryWithObjectsAndKeys:@"连接成功！您想说点什么,我来帮您翻译",@"zh",@"Please talk, I'll help to translate",@"en",nil];
    [self.parmas setObject:app_launch_tips forKey:@"app_launch"];
    
    NSDictionary * headset_in_tips = [NSDictionary dictionaryWithObjectsAndKeys:@"让我们开始体验同传模式吧",@"zh",@"Let’s try simultaneous translation model",@"en",nil];
    [self.parmas setObject:headset_in_tips forKey:@"headset_in"];

    NSDictionary * change_to_simulatenous_mode_without_headset_tips = [NSDictionary dictionaryWithObjectsAndKeys:@"插上耳机才能体验同传效果哦",@"zh",@"Plug in your headset to try non-stop translation!",@"en",nil];
    [self.parmas setObject:change_to_simulatenous_mode_without_headset_tips forKey:@"change_to_simulatenous_mode_without_headset"];

    NSDictionary * change_to_alernative_mode_tips = [NSDictionary dictionaryWithObjectsAndKeys:@"已切换至交传模式",@"zh",@"Switched to Interactive Mode",@"en",nil];
    [self.parmas setObject:change_to_alernative_mode_tips forKey:@"change_to_alernative_mode"];

    NSDictionary * change_to_simulatenous_mode_tips = [NSDictionary dictionaryWithObjectsAndKeys:@"让我们开始体验同传模式吧",@"zh",@"Switched to Continuous Mode",@"en",nil];
    [self.parmas setObject:change_to_simulatenous_mode_tips forKey:@"change_to_simulatenous_mode"];

    NSDictionary * change_to_auto_language_mode_tips = [NSDictionary dictionaryWithObjectsAndKeys:@"小译将会智能识别您说的语种",@"zh",@"You can speak Chinese or English, both languages are detectable now!",@"en",nil];
    [self.parmas setObject:change_to_auto_language_mode_tips forKey:@"change_to_auto_language_mode"];
    
    [self.parmas setObject:@"https://api.interpreter.caiyunai.com/v1/translator" forKey:@"interpreter_api_url"];//彩云翻译的网址
    [self.parmas setObject:@"token ssdj273ksdiwi923bsd9" forKey:@"ios_token"];//
    NSDictionary * change_to_zh_mode_tips = [NSDictionary dictionaryWithObjectsAndKeys:@"接下来小译会认为您说的是中文哦",@"zh",@"Please speak Chinese",@"en",nil];
    [self.parmas setObject:change_to_zh_mode_tips forKey:@"change_to_zh_mode"];

    NSDictionary * change_to_en_mode_tips = [NSDictionary dictionaryWithObjectsAndKeys:@"接下来小译会认为您说的是英文哦",@"zh",@"Please speak English to receive the Chinese translation.",@"en",nil];
    [self.parmas setObject:change_to_en_mode_tips forKey:@"change_to_en_mode"];

    NSDictionary * audio_permisson_lack_tips = [NSDictionary dictionaryWithObjectsAndKeys:@"目前无法使用麦克风，请在 系统设置-彩云小译 中打开麦克风权限",@"zh",@"Can't use the microphone. Please enable the permission in system Settings-LingoCloud",@"en",nil];
    [self.parmas setObject:audio_permisson_lack_tips forKey:@"audio_permisson_lack"];

    NSDictionary * network_status_bad_tips = [NSDictionary dictionaryWithObjectsAndKeys:@"╮(╯▽╰)╭糟糕，网络不给力",@"zh",@"Network Error. Please check your network and try again.",@"en",nil];
    [self.parmas setObject:network_status_bad_tips forKey:@"network_status_bad"];
}



- (id)getValue:(NSString*)name {
    return [self.parmas objectForKey:name];
}

- (NSMutableDictionary *)parmas {
    if (_parmas == nil) {
        _parmas = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return _parmas;
}

@end
