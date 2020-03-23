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
 @param fileList 文件列表 是一个NSArray类型的数据
 */
- (void)onWhiteBroadFileList:(NSArray *)fileList;

/**
PubMsg消息
 */
- (void)onWhiteBroadPubMsgWithMsgID:(NSString *)msgID
                            msgName:(NSString *)msgName
                               data:(NSObject *)data
                             fromID:(NSString *)fromID
                             inList:(BOOL)inlist
                                 ts:(long)ts;

/**
 msglist消息

 @param msgList 消息
 */
- (void)onWhiteBoardOnRoomConnectedMsglist:(NSDictionary *)msgList;

/**
 界面更新
 */
- (void)onWhiteBoardViewStateUpdate:(NSDictionary *)message;

/**
 教室加载状态
 
 */
- (void)onWhiteBoardLoadedState:(NSDictionary *)message;


/**
 本地操作，缩放课件比例变化

*/
- (void)onWhiteBoardFileViewZoomScaleChanged:(CGFloat)zoomScale;


@end

#endif /* YSWhiteBoardManagerDelegate_h */
