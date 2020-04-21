//
//  YSWBDrawViewManager.h
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/22.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YSWhiteBoardView;
@interface YSWBDrawViewManager : NSObject

/// 课件使用 webView 加载
@property (nonatomic, assign, readonly) BOOL showOnWeb;

/// 服务器地址
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSMutableDictionary *fileDictionary;

- (instancetype)initWithBackView:(YSWhiteBoardView *)view webView:(WKWebView *)webView;

- (void)clearAfterClass;

- (void)updateProperty:(NSDictionary *)dictionary;
- (void)receiveWhiteBoardMessage:(NSDictionary *)dictionary isDelMsg:(BOOL)isDel;
//- (void)whiteBoardOnRoomConnectedUserlist:(NSNumber *)code response:(NSDictionary *)response;

- (void)updateFrame;

- (void)setTotalPage:(NSInteger)total currentPage:(NSInteger)currentPage;
- (void)updateWBRatio:(CGFloat)ratio;

#pragma mark - 点击画笔工具创建画笔选择器
- (void)brushToolsDidSelect:(YSNativeToolType)type fromRemote:(BOOL)isFromRemote;
- (void)didSelectDrawType:(YSDrawType)type color:(NSString *)hexColor widthProgress:(CGFloat)progress;

@end

NS_ASSUME_NONNULL_END
