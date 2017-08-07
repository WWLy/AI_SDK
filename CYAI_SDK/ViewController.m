//
//  ViewController.m
//  CYAI_SDK
//
//  Created by WWLy on 28/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import "ViewController.h"
#import "CYSpeechRecognizer.h"


@interface ViewController () <CYSpeechRecognizerDelegate>

@property (nonatomic, strong) CYSpeechRecognizer *recognizer;

@property (weak, nonatomic) IBOutlet UILabel *source;

@property (weak, nonatomic) IBOutlet UILabel *result;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.recognizer = [CYSpeechRecognizer shareInstance];
    self.recognizer.delegate = self;
//    [self.recognizer startRecognizers];

}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [[CYSpeechRecognizer shareInstance] transText:@"你好" languageType:CYLanguageTypeChinese complete:^(NSString *result) {
        NSLog(@"--------result: %@", result);
    }];
}

- (IBAction)startXunfei:(id)sender {
    [self.recognizer startXunfei];
}

- (IBAction)startSiri:(id)sender {
    [self.recognizer startSiri];
}

- (IBAction)stopXunfei:(id)sender {
    [self.recognizer stopXunfei];
}

- (IBAction)stopSiri:(id)sender {
    [self.recognizer stopSiri];
}


- (IBAction)btnClick:(UIButton *)sender {
    if ([sender.currentTitle isEqualToString:@"自动"]) {
        [self.recognizer changeDetectLanguage:CYDetectLanguageAuto];
    } else if ([sender.currentTitle isEqualToString:@"中文"]) {
        [self.recognizer changeDetectLanguage:CYDetectLanguageChinese];
    } else if ([sender.currentTitle isEqualToString:@"英文"]) {
        [self.recognizer changeDetectLanguage:CYDetectLanguageEnglish];
    }
}

- (void)beginSayTextWithSource:(NSString *)source target:(NSString *)target {

    self.source.text = source;
    
    self.result.text = target;
}

- (void)speechInterpreterResultAvailable:(NSDictionary *)resultDict {
    // 下一步就是要合成了
    NSLog(@"识别及翻译结束resultDict: %@", resultDict);
}

- (void)onSpeechError:(NSDictionary *)errorDict {
    NSLog(@"errorDict: %@", errorDict);
}

- (void)whenSpeakerOver {
    NSLog(@"合成结束");
}

- (void)HeadsetPluggedIn {
    NSLog(@"插入耳机");
}

- (void)HeadsetUnplugged {
    NSLog(@"拔出耳机");
}

// 这个方法会一直触发
- (void)speechVolumeChanged:(int)volume {
//    NSLog(@"音量变化: %d", volume);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
