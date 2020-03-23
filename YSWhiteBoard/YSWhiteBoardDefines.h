//
//  YSWhiteBoardDefines.h
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/22.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#ifndef YSWhiteBoardDefines_h
#define YSWhiteBoardDefines_h


#pragma - mark 用户属性

/// 用户属性
static  NSString *const sYSUserProperties           = @"properties";

/// 发布状态
static  NSString *const sYSUserPublishstate         = @"publishstate";
/// 画笔权限 YES NO
static  NSString *const sYSUserCandraw              = @"candraw";

/// 是否进入后台 YES NO
static  NSString *const sYSUserIsInBackGround       = @"isInBackGround";

/// 用户设备状态
static  NSString *const sYSUserVideoFail            = @"vfail";
static  NSString *const sYSUserAudioFail            = @"afail";

/// 画笔颜色值
static  NSString *const sYSUserPrimaryColor         = @"primaryColor";
/// 奖杯数
static  NSString *const sYSUserGiftNumber           = @"giftnumber";
static  NSString *const sYSUserGiftinfo             = @"giftinfo";



#pragma - mark 信令

/// 发送消息
static  NSString *const sYSSignalPubMsg                 = @"pubMsg";
/// 删除消息
static  NSString *const sYSSignalDelMsg                 = @"delMsg";

/// 白板加载完成回调
static  NSString *const sYSSignalOnPageFinished         = @"onPageFinished";

/// 打印h5日志
static  NSString *const sYSSignalPrintLogMessage        = @"printLogMessage";

/// 发布网络文件流的方法
static  NSString *const sYSSignalPublishNetworkMedia    = @"publishNetworkMedia";
/// 取消发布网络文件流
static  NSString *const sYSSignalUnpublishNetworkMedia  = @"unpublishNetworkMedia";

/// 新添加接口设置属性
static  NSString *const sYSSignalSetProperty            = @"setProperty";

/// 白板放大事件
static  NSString *const sYSSignalChangeWebPageFullScreen = @"changeWebPageFullScreen";
/// 接收动作指令
static  NSString *const sYSSignalReceiveActionCommand   = @"receiveActionCommand";
/// 发送动作指令
static  NSString *const sYSSignalSendActionCommand      = @"sendActionCommand";

/// 本地持久化当前文档服务器的地址信息
static  NSString *const sYSSignalSaveValueByKey         = @"saveValueByKey";
static  NSString *const sYSSignalGetValueByKey          = @"getValueByKey";

/// 播放ppt内部MP3
static  NSString *const sYSSignalOnJsPlay               = @"isPlayAudio";

#endif /* YSWhiteBoardDefines_h */