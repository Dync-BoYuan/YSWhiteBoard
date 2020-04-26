//
//  YSWhiteBoardManagerDelegate.h
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/23.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#ifndef YSWhiteBoardManagerDelegate_h
#define YSWhiteBoardManagerDelegate_h

#import <Foundation/Foundation.h>

@protocol YSWhiteBoardManagerDelegate <NSObject>

@required

/**
 文件列表回调
 @param fileList 文件NSDictionary列表
 */
- (void)onWhiteBroadFileList:(NSArray *)fileList;

/// H5脚本文件加载初始化完成
- (void)onWhiteBoardPageFinshed:(NSString *)fileId;

/// 切换Web课件加载状态
- (void)onWhiteBoardLoadedState:(NSString *)fileId withState:(NSDictionary *)dic;

/// Web课件翻页结果
- (void)onWhiteBoardStateUpdate:(NSString *)fileId withState:(NSDictionary *)dic;
/// 翻页超时
- (void)onWhiteBoardSlideLoadTimeout:(NSString *)fileId withState:(NSDictionary *)dic;
/// 课件缩放
- (void)onWhiteBoardZoomScaleChanged:(NSString *)fileId zoomScale:(CGFloat)zoomScale;
/// 课件全屏
- (void)onWhiteBoardFullScreen:(BOOL)isAllScreen;



#pragma mark - 课件事件

/// 切剑课件
- (void)onWhiteBoardChangedFileWithFileList:(NSArray *)fileList;




@end

#endif /* YSWhiteBoardManagerDelegate_h */
