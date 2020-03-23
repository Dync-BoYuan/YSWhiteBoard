//
//  YSWhiteBoardManager.h
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/22.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSRoomConfiguration.h"


NS_ASSUME_NONNULL_BEGIN

@interface YSWhiteBoardManager : NSObject

/// 房间数据
@property (nonatomic, strong, readonly) NSDictionary *roomDic;
/// 房间配置项
@property (nonatomic, strong, readonly) YSRoomConfiguration *roomConfig;

/// 记录UI层是否开始上课
@property (nonatomic, assign, readonly) BOOL isBeginClass;

+ (instancetype)shareInstance;
+ (NSString *)whiteBoardVersion;

- (void)doMsgCachePool;

@end

NS_ASSUME_NONNULL_END
