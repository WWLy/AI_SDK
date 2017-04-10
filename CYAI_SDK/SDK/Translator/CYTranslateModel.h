//
//  CYTranslateModel.h
//  CYAI_SDK
//
//  Created by WWLy on 31/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CYTranslateModel : NSObject

// 翻译结果
@property (nonatomic, copy) NSString *target;

// 翻译置信度
@property (nonatomic, assign) double confidence;

@property (nonatomic, assign) float rc;


- (instancetype)initWithDict:(NSDictionary *)dict;

@end
