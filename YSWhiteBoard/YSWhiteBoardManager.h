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
#import "YSMediaFileModel.h"

#import "YSBrushToolsManager.h"

#import "YSWBMediaControlviewDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface YSWhiteBoardManager : NSObject
<
    YSWBMediaControlviewDelegate
>

@property (nonatomic, weak, readonly) id <YSWhiteBoardManagerDelegate> wbDelegate;
/// 配置项
@property (nonatomic, strong, readonly) NSDictionary *configration;

/// 房间数据
@property (nonatomic, strong, readonly) NSDictionary *roomDic;
/// 房间配置项
@property (nonatomic, strong, readonly) YSRoomConfiguration *roomConfig;
/// 房间类型
@property (nonatomic, assign, readonly) YSRoomUseType roomUseType;

// 关于获取白板 服务器地址、备份地址、web地址相关通知
/// 文档服务器地址
@property (nonatomic, strong, readonly) NSString *serverDocAddrKey;
@property (nonatomic, strong, readonly) NSDictionary *serverAddressInfoDic;

/// 课件列表
@property (nonatomic, strong, readonly) NSMutableArray <YSFileModel *> *docmentList;
/// 课件Dic列表
@property (nonatomic, strong, readonly) NSMutableArray <NSDictionary *> *docmentDicList;
/// 当前激活文档id
@property (nonatomic, strong, readonly) NSString *currentFileId;
/// 当前播放的媒体课件
@property (nonatomic, strong, readonly) YSMediaFileModel *mediaFileModel;
/// 当前播放的媒体课件发送者peerId
@property (nonatomic, strong, readonly) NSString *mediaFileSenderPeerId;

/// 主白板
@property (nonatomic, strong, readonly) YSWhiteBoardView *mainWhiteBoardView;

/// 记录UI层是否开始上课
@property (nonatomic, assign, readonly) BOOL isBeginClass;

/// 更新服务器地址
@property (nonatomic, assign, readonly) BOOL isUpdateWebAddressInfo;

/// 课件窗口列表
@property (nullable, nonatomic, strong) NSMutableArray <YSWhiteBoardView *> *coursewareViewList;


+ (void)destroy;

+ (instancetype)shareInstance;
+ (NSString *)whiteBoardVersion;

- (void)registerDelegate:(id <YSWhiteBoardManagerDelegate>)delegate configration:(NSDictionary *)config;

- (YSWhiteBoardView *)createMainWhiteBoardWithFrame:(CGRect)frame
                        loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock;

- (void)updateWebAddressInfo;


#pragma -
#pragma mark 课件操作

/// 变更白板窗口背景色
- (void)changeMainWhiteBoardBackgroudColor:(UIColor *)color;
/// 变更白板画板背景色
- (void)changeMainCourseViewBackgroudColor:(UIColor *)color;
/// 变更白板背景图
- (void)changeMainWhiteBoardBackImage:(nullable UIImage *)image;

/// 变更白板窗口背景色
- (void)changeAllWhiteBoardBackgroudColor:(UIColor *)color;
/// 变更白板画板背景色
- (void)changeAllCourseViewBackgroudColor:(UIColor *)color;
/// 变更白板背景图
- (void)changeAllWhiteBoardBackImage:(nullable UIImage *)image;


/// 刷新白板
- (void)refreshWhiteBoard;

/// 刷新当前白板课件数据
- (void)freshCurrentCourse;

/// 添加文档
- (void)addDocumentWithFileDic:(NSDictionary *)file;
/// 删除文档
- (void)deleteDocumentWithFileID:(NSString *)fileId;

- (void)setTheCurrentDocumentFileID:(NSString *)fileId;

- (YSFileModel *)currentFile;
- (YSFileModel *)getDocumentWithFileID:(NSString *)fileId;

/// 刷新白板课件
- (void)freshCurrentCourseWithFileId:(NSString *)fileId;

/// 切换课件
- (void)changeCourseWithFileId:(NSString *)fileId;

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

///删除课件窗口
- (void)removeWhiteBoardViewWithFileId:(NSString *)fileId;

- (CGFloat)currentDocumentZoomScale;
- (CGFloat)documentZoomScaleWithFileId:(NSString *)fileId;

#pragma -
#pragma mark 画笔权限

- (BOOL)isUserCanDraw;

#pragma -
#pragma mark 画笔控制

/// 更换画笔工具
- (void)brushToolsDidSelect:(YSBrushToolType)BrushToolType;
- (void)didSelectDrawType:(YSDrawType)type color:(NSString *)hexColor widthProgress:(CGFloat)progress;
// 恢复默认工具配置设置
- (void)freshBrushToolConfig;
// 获取当前工具配置设置 drawType: YSBrushToolType类型  colorHex: RGB颜色  progress: 值
- (YSBrushToolsConfigs *)getCurrentBrushToolConfig;
// 改变默认画笔颜色
- (void)changePrimaryColor:(NSString *)colorHex;

@end

NS_ASSUME_NONNULL_END
