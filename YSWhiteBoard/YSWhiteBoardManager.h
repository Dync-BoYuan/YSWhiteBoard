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

#import "YSWhiteBoardView.h"
#import "YSFileModel.h"


NS_ASSUME_NONNULL_BEGIN

@interface YSWhiteBoardManager : NSObject

@property (nonatomic, weak, readonly) id <YSWhiteBoardManagerDelegate> wbDelegate;
/// 配置项
@property (nonatomic, strong, readonly) NSDictionary *configration;

/// 房间数据
@property (nonatomic, strong, readonly) NSDictionary *roomDic;
/// 房间配置项
@property (nonatomic, strong, readonly) YSRoomConfiguration *roomConfig;

// 关于获取白板 服务器地址、备份地址、web地址相关通知
/// 文档服务器地址
@property (nonatomic, strong, readonly) NSString *serverDocAddrKey;


/// 课件列表
@property (nonatomic, strong, readonly) NSMutableArray <YSFileModel *> *docmentList;
/// 课件Dic列表
@property (nonatomic, strong, readonly) NSMutableArray <NSDictionary *> *docmentDicist;

/// 记录UI层是否开始上课
@property (nonatomic, assign, readonly) BOOL isBeginClass;

/// 预加载文档结束
@property (nonatomic, assign) BOOL preloadingFished;


+ (instancetype)shareInstance;
+ (NSString *)whiteBoardVersion;

+ (BOOL)supportPreload;

- (void)doMsgCachePool;

- (YSWhiteBoardView *)createMainWhiteBoardWithFrame:(CGRect)frame
                        loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock;


@end

NS_ASSUME_NONNULL_END
