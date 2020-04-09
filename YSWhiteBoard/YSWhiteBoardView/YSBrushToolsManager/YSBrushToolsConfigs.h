//
//  YSBrushToolsConfigs.h
//  YSWhiteBoard
//
//  Created by 马迪 on 2020/4/2.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YSBrushToolsConfigs : NSObject

/// 选择类型
@property (nonatomic, assign) YSDrawType drawType;
/// 颜色
@property (nonatomic, strong) NSString *colorHex;
/// 滑动条进度
@property (nonatomic, assign) CGFloat progress;

@end

NS_ASSUME_NONNULL_END
