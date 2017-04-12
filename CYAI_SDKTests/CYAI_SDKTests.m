//
//  CYAI_SDKTests.m
//  CYAI_SDKTests
//
//  Created by 阿拉斯加的狗 on 2017/4/11.
//  Copyright © 2017年 WWLy. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CYSpeechRecognizer.h"
@interface CYAI_SDKTests : XCTestCase

@property (nonatomic,strong)CYSpeechRecognizer *recognizer;

@end

@implementation CYAI_SDKTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.recognizer = [CYSpeechRecognizer shareInstance];
    
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    
    self.recognizer = nil;
    
    [super tearDown];
}


//测试翻译内容结果
- (void)testTranslatorIsCheckZH {

       __block NSString *resultStr = nil;
    
    [self.recognizer transText:@"你好" languageType:CYLanguageTypeChinese complete:^(NSString *result) {
        
        
        resultStr = result;
        XCTAssert( [resultStr isEqualToString:@"Hello"],@"翻译不正确");
    }];
}

//测试翻译内容结果
- (void)testTranslatorIsCheckEN {
    
   __block NSString *resultStr = nil;
    
    [self.recognizer transText:@"Hello" languageType:CYLanguageTypeEnglish complete:^(NSString *result) {
//        XCTAssert( [result isEqualToString:@"的撒娇父控件的索拉卡"],@"翻译正确");
        
        resultStr = result;
        XCTAssert( [resultStr isEqualToString:@"你好"],@"翻译不正确");
    }];
    
    
}


- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
