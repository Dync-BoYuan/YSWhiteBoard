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

@interface YSWBDrawViewManager : NSObject

@property (nonatomic, strong) NSMutableDictionary *fileDictionary;

/// 课件使用 webView 加载
@property (nonatomic, assign, readonly) BOOL showOnWeb;

/// 服务器地址
@property (nonatomic, strong) NSString *address;

/// 当前页码
@property (nonatomic, assign) NSInteger currentPage;
/// 总页码
@property (nonatomic, assign, readonly) NSInteger pagecount;

- (instancetype)initWithBackView:(UIView *)view webView:(WKWebView *)webView;

- (void)clearAfterClass;

- (void)updateProperty:(NSDictionary *)dictionary;
- (void)receiveWhiteBoardMessage:(NSDictionary *)dictionary isDelMsg:(BOOL)isDel;
- (void)whiteBoardOnRoomConnectedUserlist:(NSNumber *)code response:(NSDictionary *)response;

@end

NS_ASSUME_NONNULL_END
