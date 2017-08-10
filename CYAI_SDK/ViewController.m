//
//  ViewController.m
//  CYAI_SDK
//
//  Created by WWLy on 28/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import "ViewController.h"
#import "CYSpeechRecognizer.h"
#import "CYUtility.h"


@interface ViewController () <CYSpeechRecognizerDelegate>

@property (nonatomic, strong) CYSpeechRecognizer *recognizer;

@property (weak, nonatomic) IBOutlet UILabel *source;

@property (weak, nonatomic) IBOutlet UILabel *result;

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *translateBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.recognizer = [CYSpeechRecognizer shareInstance];
    self.recognizer.delegate = self;
//    [self.recognizer startRecognizers];
    
    self.textView.layer.borderWidth = 1;
    self.textView.layer.cornerRadius = 5;
    self.textView.layer.borderColor = [UIColor lightGrayColor].CGColor;
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.textView resignFirstResponder];
}
- (IBAction)startAll:(id)sender {
    [self startXunfei:nil];
    [self startSiri:nil];
}

- (IBAction)stopAll:(id)sender {
    [self stopXunfei:nil];
    [self stopSiri:nil];
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

- (IBAction)changeModel:(UISegmentedControl *)sender {
    // 语音
    if (sender.selectedSegmentIndex == 0) {
        self.textView.hidden = YES;
        self.translateBtn.hidden = YES;
    } else if (sender.selectedSegmentIndex == 1) { // 文本
        self.textView.hidden = NO;
        self.translateBtn.hidden = NO;
    }
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

- (IBAction)translateClick:(id)sender {
    
    __weak typeof(self) weakSelf = self;
    
    NSString *sourceStr = self.textView.text;
    
    CYLanguageType targetLanguage = CYLanguageTypeEnglish;
    if (![CYUtility didContainChineseStr:sourceStr]) {
        targetLanguage = CYLanguageTypeChinese;
    }
    
    [weakSelf.recognizer transText:sourceStr languageType:CYLanguageTypeChinese complete:^(NSString *transWords) {
        weakSelf.source.text = sourceStr;
        weakSelf.result.text = transWords;
        weakSelf.textView.text = @"";
    }];
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
