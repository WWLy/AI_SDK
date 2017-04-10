//
//  CYTranslateModel.m
//  CYAI_SDK
//
//  Created by WWLy on 31/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import "CYTranslateModel.h"

@implementation CYTranslateModel

- (instancetype)initWithDict:(NSDictionary *)dict {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSLog(@"UndefinedKey: %@", key);
}

@end
