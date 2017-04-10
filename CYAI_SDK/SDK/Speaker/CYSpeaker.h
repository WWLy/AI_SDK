//
//  CYSpeaker.h
//  CYAI_SDK
//
//  Created by WWLy on 05/04/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CYSpeaker : NSObject

@property (nonatomic, copy) void(^speakOver)();


+ (instancetype)shareInstance;

// 读出一段文字
- (void)sayText:(NSString *)aString;


@end
