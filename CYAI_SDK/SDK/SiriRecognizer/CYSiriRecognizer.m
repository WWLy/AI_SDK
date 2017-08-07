//
//  CYSiriRecognizer.m
//  CYAI_SDK
//
//  Created by WWLy on 29/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import "CYSiriRecognizer.h"
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>

@interface CYSiriRecognizer () <SFSpeechRecognitionTaskDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) SFSpeechRecognizer * sfSpeechRecognizer;
@property (nonatomic, strong) SFSpeechRecognitionTask * sfSpeechRecogTask;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest * sfSpeechRecognitionRequest;

// 录音
@property (nonatomic, strong) AVAudioEngine * audioEngine;
@property (nonatomic, strong) AVCaptureSession * avCapture;
@property (nonatomic, strong) NSMutableArray * audio_pieces; // siri 录音

@property (nonatomic, strong) NSString *tempResult;
@property (nonatomic, assign) CGFloat tempConf;

@end

static CYSiriRecognizer *_instance;

@implementation CYSiriRecognizer

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self initAVCapture]; // 初始化录音
        [self initSiriRecognizer]; // 初始化识别
    }
    return self;
}


#pragma mark - 启动和停止Siri录音

- (void)initAVCapture {
    
    NSLog(@"Siri初始化录音");
    NSError *error;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:nil];
    
    AVAudioSession * session = [AVAudioSession sharedInstance];
    [session setPreferredSampleRate:(double)16000 error:&error];
    
    self.avCapture = [[AVCaptureSession alloc] init];
    
    //this is so important!!
    self.avCapture.usesApplicationAudioSession = true;
    self.avCapture.automaticallyConfiguresApplicationAudioSession = false;
    
    AVCaptureDevice *audioDev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    if (audioDev == nil){
        NSLog(@"Couldn't create audio capture device");
        return ;
    }
    
    // create mic device
    AVCaptureDeviceInput *audioIn = [AVCaptureDeviceInput deviceInputWithDevice:audioDev error:&error];
    if (error != nil){
        NSLog(@"Couldn't create audio input");
        return ;
    }
    
    // add mic device in capture object
    if ([self.avCapture canAddInput:audioIn] == NO){
        NSLog(@"Couldn't add audio input");
        return ;
    }
    [self.avCapture addInput:audioIn];
    // export audio data
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [audioOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    if ([self.avCapture canAddOutput:audioOutput] == NO){
        NSLog(@"Couldn't add audio output");
        return ;
    }
    [self.avCapture addOutput:audioOutput];
    [audioOutput connectionWithMediaType:AVMediaTypeAudio];
}

// 开始录音
- (void)startAVCapture {
    // 中文模式下不启动 siri 录音
    if (self.detectLanguage == CYDetectLanguageChinese) {
        return;
    }
    if (self.avCapture != nil && ![self.avCapture isRunning]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Siri 开始录音");
            [self.avCapture startRunning];
        });
    }
}
// 停止录音
- (void)endAVCapture {
    if (self.avCapture != nil && [self.avCapture isRunning]){
        NSLog(@"Siri 结束录音");
        [self.avCapture stopRunning];
    }
}

#pragma mark - 录音回调AVCaptureAudioDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (self.sf_do_not_send_user_is_speaking) {
        // 不把Siri录音回调的结果传递给Siri识别
        return;
    }
    
    [self.audio_pieces addObject:(__bridge id _Nonnull)(sampleBuffer)];
    
    if (self.sf_can_handle_audio) {
        for (id buf in self.audio_pieces) {
            //把录音回调时所填充的buffer内容,扔给语音识别的buffer.
            [self.sfSpeechRecognitionRequest appendAudioSampleBuffer:(__bridge CMSampleBufferRef _Nonnull)(buf)];
        }
        // 把之前录音数据清空
        [self.audio_pieces removeAllObjects];
    }
}


// 开始录音并处理录音数据
- (void)startListen {
    self.sf_can_handle_audio = true; // SpeechRecognitionRequest开始处理
    [self startAVCapture]; // 开始录音
}

// 结束录音停止处理
- (void)stopListen {
    NSLog(@"siri结束录音并停止处理");
    self.sf_can_handle_audio = false; // SpeechRecognitionRequest不再处理
    [self endAVCapture]; // 停止录音
}

// 处理录音结束并开始识别 录音状态没有改变
- (void)temp {
    NSLog(@"讯飞告诉 siri 你可以停止了");
    self.sf_can_handle_audio = false; // SpeechRecognitionRequest不再处理
    [self.sfSpeechRecognitionRequest endAudio]; // 这个方法 0.5-1s 后会触发 siri 识别结束的回调
    
    // 当讯飞结束后立即把 siri 的部分识别结果拿去翻译
    if (self.finishRecognizeBlock) {
        NSLog(@"siri 识别部分结果: %@ - %f - %@", self.sfRecognizePartialResult, self.sfRecognizePartialResultConfidence, [NSThread currentThread]);
        self.tempResult = self.sfRecognizePartialResult;
        self.tempConf = self.sfRecognizePartialResultConfidence;
        self.finishRecognizeBlock(self.sfRecognizePartialResult, self.sfRecognizePartialResultConfidence, CYRecognizeTypeSiriPart);
    }
}

#pragma mark - 启动和结束Siri语音识别

- (void)initSiriRecognizer {
    // 申请权限
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                NSLog(@"语音识别未授权");
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                NSLog(@"用户未授权使用语音识别");
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                NSLog(@"语音识别在这台设备上受到限制");
                break;
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                // 初始化识别
                [self initRecognizer];
                break;
            default:
                break;
        }
    }];
}

- (void)initRecognizer {
    NSLog(@"Siri初始化语音识别");
    self.sfSpeechRecogTask = nil;
    self.sfRecognizePartialResult = @"";
    self.sfRecognizePartialResultConfidence = 0;
    self.sf_do_not_send_user_is_speaking = false;
    
    NSLocale *local = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    self.sfSpeechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:local];
}


// 开始语音识别
- (void)startRecognizer {
    NSLog(@"Siri开始语音识别");
    
    self.sf_can_handle_audio = true;
    self.sfSpeechRecognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    [self.sfSpeechRecognizer setDelegate:nil];
    self.sfSpeechRecogTask = [self.sfSpeechRecognizer recognitionTaskWithRequest:self.sfSpeechRecognitionRequest delegate:self];
}

// 停止语音识别
- (void)stopRecognizer {
    // END capture and END voice Reco
    // or Apple will terminate this task after 30000ms.
    NSLog(@"Siri 停止语音识别");
    self.sf_can_handle_audio = false;
    [self.sfSpeechRecognitionRequest endAudio]; // 停止识别
}


#pragma mark - 识别结果回调SFSpeechRecognitionTaskDelegate

//当开始检测音频源中的语音时首先调用此方法
- (void)speechRecognitionDidDetectSpeech:(SFSpeechRecognitionTask *)task {
    
}

//apple的语音识别服务会根据提供的音频源识别出多个可能的结果 每有一条结果可用 都会调用此方法 返回部分识别结果
- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didHypothesizeTranscription:(SFTranscription *)transcription {
    // 置信度
    float avg_confidence = 0;
    for (SFTranscriptionSegment *seg in transcription.segments) {
        avg_confidence += seg.confidence;
    }
    avg_confidence = avg_confidence / [transcription.segments count];
    self.sfRecognizePartialResult = transcription.formattedString;
    self.sfRecognizePartialResultConfidence = avg_confidence;
}

//Siri返回完整的(整句)识别结果,会修正部分识别结果.  这个方法调用非常慢
- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishRecognition:(SFSpeechRecognitionResult *)recognitionResult {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        float avg_confidence = 0;
        for (SFTranscriptionSegment *seg in recognitionResult.bestTranscription.segments) {
            avg_confidence += seg.confidence;
        }
        avg_confidence = avg_confidence / [recognitionResult.bestTranscription.segments count];
        NSLog(@"get Final:%@ 置信度 %f", recognitionResult.bestTranscription.formattedString, avg_confidence);
        
//        if ([recognitionResult.bestTranscription.formattedString isEqualToString:self.tempResult]) {
//            NSLog(@"sfLog: 部分结果和完整结果相同, 置信度: %f - %f", self.tempConf, avg_confidence);
//            return;
//        }
        
        
        if (self.finishRecognizeBlock) {
            self.finishRecognizeBlock(recognitionResult.bestTranscription.formattedString, avg_confidence, CYRecognizeTypeSiriFull);
        }
    });
}

//当不再接受音频输入时调用 即开始处理语音识别任务时调用
- (void)speechRecognitionTaskFinishedReadingAudio:(SFSpeechRecognitionTask *)task {
    
}

//当语音识别任务被取消时调用
- (void)speechRecognitionTaskWasCancelled:(SFSpeechRecognitionTask *)task {
    NSLog(@"SFLOG:voice recognition canceled, try to start.");
    [self startRecognizer];
}

//语音识别任务完成时被调用
- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishSuccessfully:(BOOL)successfully {
    NSLog(@"SFLOG:voice recognition is over with %@, try to restart.", successfully ? @"TRUE" : task.error);
    if (successfully) {
        [self startRecognizer];
    } else {
        NSLog(@"SFLOG: sth is wrong, endRecognizer and stop capture");
//        [self stopRecognizer];
//        [self endAVCapture];
        [self endAVCapture];
        [self.sfSpeechRecognitionRequest endAudio];

        [self initSiriRecognizer];
        [self startAVCapture];
        [self startRecognizer];
    }
}



#pragma mark - lazy load
// 存放录音数据
- (NSMutableArray *)audio_pieces {
    if (_audio_pieces == nil) {
        _audio_pieces = [NSMutableArray arrayWithCapacity:10];
    }
    return _audio_pieces;
}


@end












