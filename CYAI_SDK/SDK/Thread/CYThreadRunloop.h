//
//  CYThreadRunloop.h
//  CYAI_SDK
//
//  Created by WWLy on 05/04/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CYThreadRunloop : NSObject

+ (instancetype)shareInstance;

- (void)startRunLoop;

@end
