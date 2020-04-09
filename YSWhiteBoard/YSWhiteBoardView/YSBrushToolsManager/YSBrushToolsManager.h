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

/// 当前画笔工具
@property (nonatomic, assign, readonly) YSBrushToolType currentBrushToolType;
/// 当前工具的DrawType
@property (nonatomic, assign, readonly) YSDrawType currentBrushDrawType;
/// 画笔颜色
@property (nonatomic, strong, readonly) NSString *primaryColorHex;

/// 当前的配置
@property (nonatomic, strong, readonly) YSBrushToolsConfigs *currentConfig;


/// 单例
+ (instancetype)shareInstance;

/// 画笔默认配置
- (void)freshBrushToolConfigs;

/// 选择画笔工具
- (void)brushToolsDidSelect:(YSBrushToolType)BrushToolType;

/// 选择画笔工具的：类型 && 颜色  &&大小
- (void)didSelectDrawType:(YSDrawType)type color:(nullable NSString *)hexColor widthProgress:(float)progress;

/// 改变默认画笔颜色
- (void)changePrimaryColor:(nullable NSString *)colorHex;

@end

NS_ASSUME_NONNULL_END
