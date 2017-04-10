//
//  Config.h
//  caiyunView
//
//  Created by yuanxingyuan on 15-5-29.
//  Copyright (c) 2015年 北京彩彻区明科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Config : NSObject

@property (nonatomic, strong) NSMutableDictionary * parmas;
@property (nonatomic, strong) NSDateFormatter * datetimeFormatter;
@property (nonatomic, strong) NSDateFormatter * dateFormatter;


+ (instancetype)initOnce;

- (id)getValue:(NSString *)name ;


@end

static Config *conf = nil;






