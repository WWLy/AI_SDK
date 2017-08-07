//
//  CYPolicyMaker.h
//  CYAI_SDK
//
//  Created by WWLy on 06/04/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYLanguageDefine.h"
@class CYSpeechSession;

@interface CYPolicyMaker : NSObject

+ (instancetype)shareInstance;

// 识别语言的语种
+ (CYLanguageType)detectLanguage:(CYSpeechSession *)session;

@end
