//
//  YSWhiteBoardManager.h
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/22.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSWhiteBoardManagerDelegate.h"
#import "YSRoomConfiguration.h"


NS_ASSUME_NONNULL_BEGIN

@interface YSWhiteBoardManager : NSObject

@property (nonatomic, weak, readonly) id <YSWhiteBoardManagerDelegate> wbDelegate;
/// 配置项
@property (nonatomic, strong, readonly) NSDictionary *configration;

/// 房间数据
@property (nonatomic, strong, readonly) NSDictionary *roomDic;
/// 房间配置项
@property (nonatomic, strong, readonly) YSRoomConfiguration *roomConfig;

/// 记录UI层是否开始上课
@property (nonatomic, assign, readonly) BOOL isBeginClass;

// 预加载文档标识
@property (nonatomic, assign) BOOL preloadingFished;


+ (instancetype)shareInstance;
+ (NSString *)whiteBoardVersion;

+ (BOOL)supportPreload;

- (void)doMsgCachePool;


@end

NS_ASSUME_NONNULL_END
