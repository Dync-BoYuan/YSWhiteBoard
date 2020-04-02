//
//  YSWhiteBoardMacro.h
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/22.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#ifndef YSWhiteBoardMacro_h
#define YSWhiteBoardMacro_h

#define YSWBBUNDLE_NAME     @"YSWhiteBoardResources.bundle"
#define YSWBBUNDLE          [NSBundle bundleWithPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:YSWBBUNDLE_NAME]]
#define YSWBLocalized(s)    [YSWBBUNDLE localizedStringForKey:s value:@"" table:nil]

#ifndef __OPTIMIZE__
#define NSLog(...) NSLog(__VA_ARGS__)
#else
#define NSLog(...)
#endif

/// 文本框输入工具的text控件tag
#define YSWHITEBOARD_TEXTVIEWTAG    20190109

/// 课件缩放范围
#define YSWHITEBOARD_MAXZOOMSCALE   (3.0f)
#define YSWHITEBOARD_MINZOOMSCALE   (1.0f)

/// 网络协议 http or https
extern NSString *const YSWhiteBoardWebProtocolKey;
/// host
extern NSString *const YSWhiteBoardWebHostKey;
/// port
extern NSString *const YSWhiteBoardWebPortKey;
extern NSString *const YSWhiteBoardPlayBackKey;

#pragma mark - 1.读取本地index  0.读取指定   ssssssssss
#define IS_LOAD_LOCAL_INDEX 1

#if IS_LOAD_LOCAL_INDEX //读取本地时通常为发布版本需要设置成https端口443

    #define YSWBHTTPS       @"https"
    #define YSWBPort        @"443"

#else

    #define YSWBHTTPS       @"http"
    #define YSWBPort        @"80"
    #define PointToHost     @"192.168.1.149:9251"

#endif

#define WBBUNDLE_NAME @"YSWhiteBoardResources.bundle"
#define WBBUNDLE [NSBundle bundleWithPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:WBBUNDLE_NAME]]

#endif /* YSWhiteBoardMacro_h */
