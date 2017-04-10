//
//  CYSpeaker.m
//  CYAI_SDK
//
//  Created by WWLy on 05/04/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import "CYSpeaker.h"
#import <AVFoundation/AVFoundation.h>//SIRI录音和发音SDK
#import <Speech/Speech.h>//SIRI语音识别SDK
#import "CYUtility.h"
#import "CYCollectionQueue.h"
#import "CYSpeechRecognizer.h"

@interface CYSpeaker () <AVSpeechSynthesizerDelegate>

/*
 AVFoundation框架
 AVCapture:语音捕获(录音)
 AVSpeech:语音合成(发音)
 */

// 合成器 控制播放，暂停
@property AVSpeechSynthesizer * avSpeechSynthesizer;
// 实例化说话的语言，说中文、英文
@property AVSpeechSynthesisVoice *_voice_en;
@property AVSpeechSynthesisVoice *_voice_zh;


@end

static id _instance;

@implementation CYSpeaker

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self initSiriSpeechSynthesis];
    }
    return self;
}

// 初始化语音合成相关
- (void)initSiriSpeechSynthesis {
    //实例化说话的语言，说英文
    //口音选择(identifier):@"com.apple.ttsbundle.siri_female_en-US_compact",@"identifier:com.apple.ttsbundle.Daniel-compact"
    self._voice_en = [AVSpeechSynthesisVoice voiceWithIdentifier:@"com.apple.ttsbundle.siri_female_en-US_compact"];
    self._voice_zh = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    
    // 要朗诵，需要一个语音合成器
    self.avSpeechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    self.avSpeechSynthesizer.delegate = self;//AVSpeechSynthesizer语音合成的代理
    
    //遍历可用的语音种类
    for (AVSpeechSynthesisVoice *voice in [AVSpeechSynthesisVoice speechVoices]) {
        if ([voice.language containsString:@"en-"]) {
//            NSLog(@"Siri语音合成器的语言:%@, 名字:%@, identifier:%@", voice.language, voice.name, voice.identifier);
        }
    }
}



// 读出一段文字
- (void)sayText:(NSString *)aString {

    NSLog(@"开始合成,停止识别");
    
    AVSpeechUtterance *avSpeechUtterance = [AVSpeechUtterance speechUtteranceWithString:aString];
    
    NSString * language = @"en";
    if ([CYUtility didContainChineseStr:aString]) {
        language = @"zh";
    }
    
    //指定语音，和朗诵速度
    //中文朗诵速度：0.1还能够接受
    //英文朗诵速度：0.3还可以
    if ([language isEqual: @"en"]) {//根据所朗读的语言是中文还是英文,选择不同的合成器.
        avSpeechUtterance.voice = self._voice_en;
        avSpeechUtterance.rate = 0.501;
    } else {
        avSpeechUtterance.voice = self._voice_zh;
        avSpeechUtterance.rate = 0.5201;
    }
    
    NSLog(@"speaking(%@, %f):%@", avSpeechUtterance.voice, avSpeechUtterance.rate, aString);
    
    [self.avSpeechSynthesizer speakUtterance:avSpeechUtterance];
}

//Siri语音合成完成(念完了)的回调函数
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    
    // 告诉控制中心读完了
    if (self.speakOver != nil) {
        self.speakOver();
    }
}




@end
