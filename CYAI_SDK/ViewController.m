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



@property (weak, nonatomic) IBOutlet UILabel *source;

@property (weak, nonatomic) IBOutlet UILabel *result;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CYSpeechRecognizer *recognizer = [CYSpeechRecognizer shareInstance];
    recognizer.delegate = self;
    [recognizer startRecognizers];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[CYSpeechRecognizer shareInstance] transText:@"你好" languageType:CYLanguageTypeChinese complete:^(NSString *result) {
        NSLog(@"--------result: %@", result);
    }];
}

- (void)beginSayTextWithSource:(NSString *)source target:(NSString *)target {

    self.source.text = source;
    
    self.result.text = target;
}

- (void)whenSpeakerOver {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
