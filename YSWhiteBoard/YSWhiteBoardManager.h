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
/// 当前激活文档id
@property (nonatomic, strong, readonly) NSString *currentFileId;

/// 记录UI层是否开始上课
@property (nonatomic, assign, readonly) BOOL isBeginClass;

/// 预加载文档结束
@property (nonatomic, assign) BOOL preloadingFished;
/// 信令缓存数据 预加载完成前
@property (nonatomic, strong, readonly) NSMutableArray *preLoadingFileCacheMsgPool;


+ (instancetype)shareInstance;
+ (NSString *)whiteBoardVersion;

+ (BOOL)supportPreload;

- (void)doMsgCachePool;

- (void)registerDelegate:(id <YSWhiteBoardManagerDelegate>)delegate configration:(NSDictionary *)config;

- (YSWhiteBoardView *)createMainWhiteBoardWithFrame:(CGRect)frame
                        loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock;


- (BOOL)isPredownloadError;


#pragma -
#pragma mark 课件操作
/// 变更白板画板背景色
- (void)changeFileViewBackgroudColor:(UIColor *)color;


/// 刷新白板
- (void)refreshWhiteBoard;

/// 刷新当前白板课件数据
- (void)freshCurrentCourse;

/// 添加文档
- (void)addDocumentWithFileDic:(NSDictionary *)file;
/// 删除文档
- (void)delDocumentFile:(NSDictionary *)file;

- (void)setTheCurrentDocumentFileID:(NSString *)fileId;

- (YSFileModel *)currentFile;
- (YSFileModel *)getDocumentWithFileID:(NSString *)fileId;

/// 刷新白板课件
- (void)freshCurrentCourseWithFileId:(NSString *)fileId;

/// 课件 上一页
- (void)whiteBoardPrePage;
- (void)whiteBoardPrePageWithFileId:(NSString *)fileId;
/// 课件 下一页
- (void)whiteBoardNextPage;
- (void)whiteBoardNextPageWithFileId:(NSString *)fileId;
/// 课件 跳转页
- (void)whiteBoardTurnToPage:(NSUInteger)pageNum;
- (void)whiteBoardTurnToPage:(NSUInteger)pageNum withFileId:(NSString *)fileId;

/// 白板 放大
- (void)whiteBoardEnlarge;
- (void)whiteBoardEnlargeWithFileId:(NSString *)fileId;
/// 白板 缩小
- (void)whiteBoardNarrow;
- (void)whiteBoardNarrowWithFileId:(NSString *)fileId;
/// 白板 放大重置
- (void)whiteBoardResetEnlarge;
- (void)whiteBoardResetEnlargeWithFileId:(NSString *)fileId;

- (YSWhiteBoardErrorCode)showDocumentWithFileID:(NSString *)fileId isBeginClass:(BOOL)isBeginClass isPubMsg:(BOOL)isPubMsg;

#pragma -
#pragma mark 画笔控制

- (void)brushToolsDidSelect:(YSBrushToolType)BrushToolType;
- (void)didSelectDrawType:(YSDrawType)type color:(NSString *)hexColor widthProgress:(float)progress;
// 恢复默认工具配置设置
- (void)freshBrushToolConfig;
// 获取当前工具配置设置 drawType: YSBrushToolType类型  colorHex: RGB颜色  progress: 值
- (NSDictionary *)getBrushToolConfigWithToolType:(YSBrushToolType)BrushToolType;
// 改变默认画笔颜色
- (void)changeDefaultPrimaryColor:(NSString *)colorHex;

@end

NS_ASSUME_NONNULL_END
