//
//  CYIflyRecognizer.m
//  CYAI_SDK
//
//  Created by WWLy on 28/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import "CYIflyRecognizer.h"
#import "iflyMSC/IFlyMSC.h"
#import "IATConfig.h"
#import "ISRDataHelper.h"
#import "CYSpeechRecognizer.h"

@interface CYIflyRecognizer () <IFlySpeechRecognizerDelegate>

@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;//不带界面的识别对象

@property (nonatomic, copy) NSString *recognizeResult;

@end


static id _instance;

@implementation CYIflyRecognizer

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self initiFlySpeechRecognizer];
    }
    return self;
}

#pragma mark - 启动和取消讯飞语音识别(含讯飞录音)
- (void)initiFlySpeechRecognizer {
    //单例模式，无UI的实例
    if (_iFlySpeechRecognizer == nil) {
        _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
        
        [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
        
        //设置听写模式
        [_iFlySpeechRecognizer setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
    }
    _iFlySpeechRecognizer.delegate = self;
    if (_iFlySpeechRecognizer != nil) {
        IATConfig *instance = [IATConfig sharedInstance];
        //设置最长录音时间
        [_iFlySpeechRecognizer setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
        //设置后端点
        [_iFlySpeechRecognizer setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
        //设置前端点
        [_iFlySpeechRecognizer setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
        //网络等待时间
        [_iFlySpeechRecognizer setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
        //设置采样率，推荐使用16K
        [_iFlySpeechRecognizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
        if ([instance.language isEqualToString:[IATConfig chinese]]) {
            //设置语言
            [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
            //设置方言
            [_iFlySpeechRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
        } else if ([instance.language isEqualToString:[IATConfig english]]) {
            [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
        }
        //设置是否返回标点符号
        [_iFlySpeechRecognizer setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
        [_iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
    }
    
    self.recognizeResult = @"";
}

// 开始语音识别
- (void)startListen {
    //若讯飞语音识别引擎(_iFlySpeechRecognizer)为空,则重新初始化.
    if(_iFlySpeechRecognizer == nil)
    {
        [self initiFlySpeechRecognizer];
    }
    //取消本次听写会话,开始新的会话？？？是吧
    [_iFlySpeechRecognizer cancel];
    
    //设置音频来源为麦克风
    [_iFlySpeechRecognizer setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
    
    //保存录音文件，保存在sdk工作路径中，如未设置工作路径，则默认保存在library/cache下
    [_iFlySpeechRecognizer setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
    
    /******
     开始识别(启动听写):
     同时只能进行一路会话，这次会话没有结束不能进行下一路会话，否则会报错。若有需要多次回话， 请在onError回调返回后请求下一路回话。
     成功返回YES；失败返回NO。
     启动听写后,才会调用onResults回调函数.
     ******/
    NSLog(@"讯飞开始识别");
    BOOL ret = [_iFlySpeechRecognizer startListening];
    if (ret) {
        
    } else {
        
    }
}

// 取消此次回话, 停止录音, 停止识别
- (void)stopListen {
    NSLog(@"讯飞停止识别");
    [_iFlySpeechRecognizer stopListening];
    [_iFlySpeechRecognizer cancel];
    [_iFlySpeechRecognizer setDelegate:nil];
    [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
}

- (void)startListening {
    [_iFlySpeechRecognizer startListening];
}

- (void)stopListening {
    [_iFlySpeechRecognizer stopListening];
}

// 设置中文口音识别
- (void)setiFlyAccent:(ChineseAccent)accentEnum {
    NSString *accentStr = [CYLanguageDefine iFlyAccentStr:accentEnum];
    IATConfig *instance = [IATConfig sharedInstance];
    if ([instance.language isEqualToString:[IATConfig chinese]]) {
        instance.accent = accentStr;
        [_iFlySpeechRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
    } else if ([instance.language isEqualToString:[IATConfig english]]) {
        //[_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
    }
}

#pragma mark - IFlySpeechRecognizerDelegate

/*!
 *  识别结果回调
 *    在识别过程中可能会多次回调此函数，你最好不要在此回调函数中进行界面的更改等操作，只需要将回调的结果保存起来。
 *  使用results的示例如下：
 *  <pre><code>
 *  - (void) onResults:(NSArray *) results{
 *     NSMutableString *result = [[NSMutableString alloc] init];
 *     NSDictionary *dic = [results objectAtIndex:0];
 *     for (NSString *key in dic){
 *        [result appendFormat:@"%@",key];//合并结果
 *     }
 *   }
 *  </code></pre>
 *
 *  @param results  -[out] 识别结果，NSArray的第一个元素为NSDictionary，NSDictionary的key为识别结果，sc为识别结果的置信度。
 *  @param isLast   -[out] 是否最后一个结果
 */
- (void)onResults:(NSArray *)results isLast:(BOOL)isLast {
    
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    NSString * resultFromJson =  [ISRDataHelper stringFromJson:resultString];

    NSLog(@"听写结果：%@", resultFromJson);
    
    if (isLast) {
        // 当前没有语音合成进程
        if (![CYSpeechRecognizer shareInstance].isSpeaking) {
            //最后一次识别结果, 此时会自动停止监听, 需要手动开启
            NSLog(@"最后一次识别结果, 此时会自动停止监听, 手动开启识别");
            [self.iFlySpeechRecognizer startListening];
        }
        return; //do not translate when we hear it.
    }
    
    if (self.finishRecognizeBlock) {
        NSString * inputString = resultFromJson;
        if([inputString hasPrefix:@"，"]) {
            inputString = [inputString substringFromIndex:1];
        }
        if([inputString hasPrefix:@","]) {
            inputString = [inputString substringFromIndex:1];
        }
        if([inputString hasPrefix:@"?"]) {
            inputString = [inputString substringFromIndex:1];
        }
        if([inputString hasPrefix:@"？"]) {
            inputString = [inputString substringFromIndex:1];
        }
        
        NSUInteger length = inputString.length;
        
        unichar buffer[length+1];
        [inputString getCharacters:buffer range:NSMakeRange(0, length)];
        
        NSInteger chinese_count = 0;
        NSString * words = @"";
        for(int i = 0; i < length; i++)
        {
            BOOL isLetter = isalpha(buffer[i]);
            
            if (!isLetter) {
                words = [NSString stringWithFormat:@"%@%C", words, buffer[i]];
                chinese_count ++;
            } else {
                words = [NSString stringWithFormat:@"%@%C", words, buffer[i]];
                if ((i+1 < length) && ( ![[NSCharacterSet letterCharacterSet] characterIsMember: buffer[i+1]]) ) {
                    words = [NSString stringWithFormat:@"%@", words];
                }
            }
        }
        
        float source_confidence;
        source_confidence = (float)chinese_count / length;
        
        if (source_confidence < 0.95) {
            source_confidence = source_confidence * 0.5;
        }
        
        words = [words stringByReplacingOccurrencesOfString: @"了 呢" withString:@"了"];
        words = [words stringByReplacingOccurrencesOfString: @"？" withString:@" "];
        words = [words stringByReplacingOccurrencesOfString: @"?" withString:@" "];
    
        self.recognizeResult = words;
        
        self.finishRecognizeBlock(words, source_confidence);
    }
}

/*!
 *  识别结果回调（注：无论听写是否正确都会回调）
 *    在进行语音识别过程中的任何时刻都有可能回调此函数，你可以根据errorCode进行相应的处理，
 *  当errorCode没有错误时，表示此次会话正常结束；否则，表示此次会话有错误发生。特别的当调用
 *  `cancel`函数时，引擎不会自动结束，需要等到回调此函数，才表示此次会话结束。在没有回调此函数
 *  之前如果重新调用了`startListenging`函数则会报错误。
     error.errorCode =
     0     听写正确
     other 听写出错
 *  @param error 错误描述
 */
- (void)onError:(IFlySpeechError *) error {
    NSString *errText = [NSString stringWithFormat:@"听写结束：%d %@", error.errorCode, error.errorDesc];
    NSLog(@"%@",errText);
    NSString *text = @"";
    if (error.errorCode == 0) {
        if (self.recognizeResult.length == 0) {
            text = @"无识别结果";
        } else {
            text = @"识别成功";
        }
    } else {
        text = [NSString stringWithFormat:@"发生错误：%d %@", error.errorCode,error.errorDesc];
        NSLog(@"%@, 尝试重启讯飞", text);
        if (error.errorCode /100 == 102) {
            
            NSMutableDictionary * errorDict = [[NSMutableDictionary alloc]init];
            
            NSString * zhStr = @"抱歉，刚才网络连接不稳定，识别不流畅。";
            NSString * enStr = @"Sorry, the internet connection was not stable so that our voice recognition was not stable.";
            
            [errorDict setObject:@"xxx" forKey:@"error_code"];
            [errorDict setObject:zhStr forKey:@"zh_string"];
            [errorDict setObject:enStr forKey:@"en_string"];
//            [self.delegate onError:errorDict];
        }
        NSLog(@"发生错误, 讯飞开始重新识别");
        BOOL ret = [_iFlySpeechRecognizer startListening];
        if (ret) {
            if (error.errorCode / 100 == 102) {
                NSMutableDictionary * errorDict = [[NSMutableDictionary alloc]init];
                
                NSString * zhStr = @"连接恢复，可以继续说话了。：）";
                NSString * enStr = @"connection for recognition is restored.";
                
                [errorDict setObject:@"xxx" forKey:@"error_code"];
                [errorDict setObject:zhStr forKey:@"zh_string"];
                [errorDict setObject:enStr forKey:@"en_string"];
//                [self.delegate onError:errorDict];
            }
        }
    }
}

@end
