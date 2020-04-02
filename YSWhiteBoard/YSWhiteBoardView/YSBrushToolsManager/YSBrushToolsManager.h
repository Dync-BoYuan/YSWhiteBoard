//
//  YSBrushToolsManager.h
//  YSWhiteBoard
//
//  Created by 马迪 on 2020/4/2.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSBrushToolsConfigs.h"

NS_ASSUME_NONNULL_BEGIN

@interface YSBrushToolsManager : NSObject

///当前的配置
@property (nonatomic, strong,readonly) YSBrushToolsConfigs *currentConfig;

///单例
+ (instancetype)shareInstance;

///画笔默认配置
- (void)freshBrushToolConfigs;

///选择画笔工具
- (void)brushToolsDidSelect:(YSBrushToolType)BrushToolType;

///选择画笔工具的：类型 && 颜色  &&大小
- (void)didSelectDrawType:(YSDrawType)type color:(NSString *)hexColor widthProgress:(float)progress;

/// 改变默认画笔颜色
- (void)changeDefaultPrimaryColor:(NSString *)colorHex;

/// 获取当前工具配置设置
//- (YSBrushToolsConfigs *)getWbToolConfigWithToolType:(YSBrushToolType)type;

@end

NS_ASSUME_NONNULL_END
