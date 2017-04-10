//
//  CYDataCollector.h
//  CYAI_SDK
//
//  Created by WWLy on 06/04/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CYSpeechSession;

// 把识别和翻译结果传给后端
@interface CYDataCollector : NSObject

+ (void)postDataToServer:(CYSpeechSession *)session;

@end
