//
//  CYTranslator.h
//  CYAI_SDK
//
//  Created by WWLy on 29/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYSpeechSession.h"
#import "CYLanguageDefine.h"
@class CYTranslateModel;

@interface CYTranslator : NSObject

+ (instancetype)shareInstance;

- (void)translateWithSourceType:(CYLanguageType)type sourceString:(NSString *)sourceString complete:(void(^)(CYTranslateModel *))complete;

@end
