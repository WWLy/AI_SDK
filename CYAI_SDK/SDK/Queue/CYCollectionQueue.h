//
//  CYCollectionQueue.h
//  CYAI_SDK
//
//  Created by WWLy on 30/03/2017.
//  Copyright © 2017 WWLy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYSpeechSession.h"

/**
 这里分别用两个数组存放语音识别及翻译的结果和语音合成的数据
 */
@interface CYCollectionQueue : NSObject

// 识别及翻译结果队列
@property (atomic, strong) NSMutableArray<CYSpeechSession *> *recognizeQueue;

// 语音合成队列
@property (atomic, strong) NSMutableArray *speakQueue;

// 这个是当讯飞识别出结果且超时后把该 sessionId 记录下来
@property (nonatomic, strong) NSMutableArray *abandonPool;



+ (instancetype)shareInstance;

/**
 根据传入的 id(时间戳)从队列中找对应的 session, 如果找不到则创建一个新的

 @param sessionId id(时间戳)
 @return session
 */
- (CYSpeechSession *)getSpeechSessionWithID:(long long)sessionId;

@end
