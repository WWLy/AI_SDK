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

@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *sfSpeechRecognitionRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask * sfSpeechRecogTask;

// 录音
@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) AVCaptureSession * avCapture;
@property (nonatomic, strong) NSMutableArray * audio_pieces; // siri 录音


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
//        [self initAudioEngine];
        self.sf_do_not_send_user_is_speaking = false;
        [self initSiriRecorderAndRecognizer]; // 识别
    }
    return self;
}

- (void)initAudioEngine {
    self.audioEngine = [[AVAudioEngine alloc] init];
    // 初始化语音处理器的输入模式
    [self.audioEngine.inputNode installTapOnBus:0 bufferSize:16000 format:[self.audioEngine.inputNode outputFormatForBus: 0] block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        
        // 此时不再对 siri 录音结果识别
        if (self.sf_do_not_send_user_is_speaking) {
            return;
        }
        [self.audio_pieces addObject:buffer];
        if (self.sf_can_handle_audio) {
            for (id buf in self.audio_pieces) {
                // 为语音识别请求对象添加一个AudioPCMBuffer，来获取声音数据
                [self.sfSpeechRecognitionRequest appendAudioPCMBuffer:buf];
            }
            [self.audio_pieces removeAllObjects];
        }
    }];
    
    // 语音处理器准备就绪（会为一些audioEngine启动时所必须的资源开辟内存）
    [self.audioEngine prepare];
}


#pragma mark - 启动和停止Siri录音(而讯飞是自己录音)

- (void)initAVCapture
{
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

/**
 开始录音
 */
- (void)startAVCapture {
//    if (self.avCapture != nil && ![self.avCapture isRunning]){
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSLog(@"Siri 开始录音");
//            [self.avCapture startRunning];
//        });
//    }
    
    if (self.audioEngine != nil && ![self.audioEngine isRunning]) {
        NSError *error;
        // 启动声音处理器
        [self.audioEngine startAndReturnError: &error];
    }
}

- (void)endAVCapture {
//    if (self.avCapture != nil && [self.avCapture isRunning]){
//        NSLog(@"Siri 结束录音");
//        [self.avCapture stopRunning];
//    }
    
    if (self.audioEngine != nil && [self.audioEngine isRunning]) {
        [self.audioEngine stop];
    }
}

// 开始录音
- (void)startListen {
    self.sf_can_handle_audio = true;
    [self startAVCapture];
}

// 停止录音
- (void)endListen {
    self.sf_can_handle_audio = false;
    [self endAVCapture]; // 停止录音
}



#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    [self.audio_pieces addObject:(__bridge id _Nonnull)(sampleBuffer)];
    
    for (id buf in self.audio_pieces) {
        //把录音回调时所填充的buffer内容,扔给语音识别的buffer.
        [self.sfSpeechRecognitionRequest appendAudioSampleBuffer:(__bridge CMSampleBufferRef _Nonnull)(buf)];
    }
    [self.audio_pieces removeAllObjects];
}


#pragma mark - 启动和结束Siri语音识别

- (void)initSiriRecorderAndRecognizer {
    
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
                NSLog(@"Siri 开始录音初始化");
                [self initRecognizer];
                [self startRecognizer];
//                [self startAVCapture];
                break;
            default:
                break;
        }
    }];
}

- (void)initRecognizer {
    self.sfSpeechRecogTask = nil;
    self.sfRecognizePartialResult = @"";
    self.sfRecognizePartialResultConfidence = 0;
    
    NSLocale *local = [[NSLocale alloc] initWithLocaleIdentifier:@"en-us"];
    self.sfSpeechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:local];
}

- (void)getAllSupportedLocales {
    NSSet<NSLocale *> * locales = [SFSpeechRecognizer supportedLocales];
    for (int i = 0; i < locales.count; i++) {
        NSLocale * locale = [locales allObjects][i];
        NSString * localeID = locale.localeIdentifier;
        if ([localeID containsString:@"en"]) {
            NSLog(@"所支持的locale currencySymbol:%@, Identifier:%@", locale.currencySymbol, locale.localeIdentifier);
        }
    }
}

/**
 开始语音识别
 */
- (void)startRecognizer {
    NSLog(@"Siri 开始语音识别");
    
    self.sf_can_handle_audio = true;
    
    self.sfSpeechRecognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    [self.sfSpeechRecognizer setDelegate:nil];
     self.sfSpeechRecogTask = [self.sfSpeechRecognizer recognitionTaskWithRequest:self.sfSpeechRecognitionRequest delegate:self];
    
//    __weak typeof(self) weakSelf = self;
//    self.sfSpeechRecogTask = [self.sfSpeechRecognizer recognitionTaskWithRequest:self.sfSpeechRecognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
//        if (result == nil) {
//            NSLog(@"siri result nil!");
//            return;
//        }
//        float avg_confidence = 0;
//        for (SFTranscriptionSegment *seg in result.bestTranscription.segments) {
//            avg_confidence += seg.confidence;
//        }
//        avg_confidence = avg_confidence / [result.bestTranscription.segments count];
//     
//        weakSelf.sfRecognizePartialResult = result.bestTranscription.formattedString;
//        weakSelf.sfRecognizePartialResultConfidence = avg_confidence;
//        
//        if (result.isFinal && error != nil) {
//            NSLog(@"get Final:%@ 置信度 %f", result.bestTranscription.formattedString, avg_confidence);
//            if (self.finishRecognizeBlock != nil) {
//                self.finishRecognizeBlock(weakSelf.sfRecognizePartialResult, weakSelf.sfRecognizePartialResultConfidence);
//            }
//        }
//    }];
    
}

- (void)stopRecognizer {
    // END capture and END voice Reco
    // or Apple will terminate this task after 30000ms.
    NSLog(@"Siri 停止语音识别");
    [self endAVCapture]; // 先停止录音
    [self.sfSpeechRecognitionRequest endAudio];
//    [self.sfSpeechRecogTask cancel];

}




#pragma mark - SFSpeechRecognitionTaskDelegate

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
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        float avg_confidence = 0;
        for (SFTranscriptionSegment *seg in recognitionResult.bestTranscription.segments) {
            avg_confidence += seg.confidence;
        }
        avg_confidence = avg_confidence / [recognitionResult.bestTranscription.segments count];
        NSLog(@"get Final:%@ 置信度 %f", recognitionResult.bestTranscription.formattedString, avg_confidence);
        if (self.finishRecognizeBlock) {
            self.finishRecognizeBlock(recognitionResult.bestTranscription.formattedString, avg_confidence);
        }
//    });
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
        [self stopRecognizer];
        [self initSiriRecorderAndRecognizer];
        [self startAVCapture];
    }
}


#pragma mark - lazy load

- (NSMutableArray *)audio_pieces {
    if (_audio_pieces == nil) {
        _audio_pieces = [NSMutableArray arrayWithCapacity:10];
    }
    return _audio_pieces;
}



@end












