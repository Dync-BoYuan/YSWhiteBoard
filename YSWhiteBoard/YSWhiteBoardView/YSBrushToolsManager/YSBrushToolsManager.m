//
//  YSBrushToolsManager.m
//  YSWhiteBoard
//
//  Created by 马迪 on 2020/4/2.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSBrushToolsManager.h"


@interface YSBrushToolsManager ()

/// 当前画笔工具
@property (nonatomic, assign) YSBrushToolType currentBrushToolType;
/// 当前工具的DrawType
@property (nonatomic, assign) YSDrawType currentBrushDrawType;
/// 画笔颜色
@property (nonatomic, strong) NSString *primaryColorHex;

///默认颜色
@property (nonatomic, strong) NSString *defaultPrimaryColor;

///当前的配置
@property (nonatomic, strong) YSBrushToolsConfigs *currentConfig;

@property (nonatomic, strong) YSBrushToolsConfigs *lineConfig;
@property (nonatomic, strong) YSBrushToolsConfigs *textConfig;
@property (nonatomic, strong) YSBrushToolsConfigs *sharpConfig;
@property (nonatomic, strong) YSBrushToolsConfigs *eraserConfig;

@end


@implementation YSBrushToolsManager

static YSBrushToolsManager *brushTools = nil;
+ (instancetype )shareInstance
{
    if (!brushTools)
    {
        brushTools = [[YSBrushToolsManager alloc] init];
        //[brushTools makeDefaultToolConfigs];
        [brushTools freshDefaultBrushToolConfigs];
    }
    
    return brushTools;
}

///// 原始配置
//- (void)makeDefaultToolConfigs
//{
//    self.currentBrushToolType = YSBrushToolTypeMouse;
//
//    // 默认颜色 红
//    self.defaultPrimaryColor = @"#FF0000";
//    [self freshBrushToolConfigs];
//}

/// 画笔默认配置
- (void)freshDefaultBrushToolConfigs
{
    self.currentBrushToolType = YSBrushToolTypeMouse;
    
    // 默认颜色 红
    self.defaultPrimaryColor = @"#FF0000";

    // 画笔
    self.lineConfig = [[YSBrushToolsConfigs alloc]init];
    self.lineConfig.drawType = YSDrawTypePen;
    self.lineConfig.colorHex = @"";
    self.lineConfig.progress = 0.03f;
    
    // 文本
    self.textConfig = [[YSBrushToolsConfigs alloc]init];
    self.textConfig.drawType = YSDrawTypeTextMS;
    self.textConfig.colorHex = @"";
    self.textConfig.progress = 0.3f;
    
    // 形状
    self.sharpConfig = [[YSBrushToolsConfigs alloc]init];
    self.sharpConfig.drawType = YSDrawTypeEmptyRectangle;
    self.sharpConfig.colorHex = @"";
    self.sharpConfig.progress = 0.03f;
    
    // 橡皮
    self.eraserConfig = [[YSBrushToolsConfigs alloc]init];
    self.eraserConfig.drawType = YSDrawTypeEraser;
    self.eraserConfig.colorHex = @"";
    self.eraserConfig.progress = 0.03f;
    
    self.currentConfig = self.lineConfig;
}

- (YSBrushToolsConfigs *)getSBrushToolsConfigsWithBrushToolType:(YSBrushToolType)brushToolType;
{
    switch (brushToolType)
    {
        case YSBrushToolTypeLine:
        {
            return self.lineConfig;
        }
        case YSBrushToolTypeText:
        {
            return self.textConfig;
        }
        case YSBrushToolTypeShape:
        {
            return self.sharpConfig;
        }
        case YSBrushToolTypeEraser:
        {
            return self.eraserConfig;
        }
        default:
            break;
    }

    return self.currentConfig;
}

///选择画笔工具
- (void)brushToolsDidSelect:(YSBrushToolType)BrushToolType
{
    if (BrushToolType == YSBrushToolTypeClear)
    {
        return;
    }
    
    self.currentBrushToolType = BrushToolType;
    
    switch (BrushToolType)
    {
        case YSBrushToolTypeLine:
        {
            self.currentConfig = self.lineConfig;
            break;
        }
        case YSBrushToolTypeText:
        {
            self.currentConfig = self.textConfig;
        }
            break;
        case YSBrushToolTypeShape:
        {
            self.currentConfig = self.sharpConfig;
        }
            break;
        case YSBrushToolTypeEraser:
        {
            self.currentConfig = self.eraserConfig;
        }
            break;
        default:
            break;
    }
}

#pragma mark - 选择画笔工具：类型 && 颜色  &&大小
- (void)didSelectDrawType:(YSDrawType)type color:(NSString *)hexColor widthProgress:(CGFloat)progress
{
    if (self.currentBrushToolType != YSBrushToolTypeMouse && type != YSDrawTypeClear)
    {
        [self changeToolConfigWithToolType:self.currentBrushToolType drawType:type color:hexColor progress:progress];
    }
}

///画笔属性变化时修改配置
- (void)changeToolConfigWithToolType:(YSBrushToolType)type drawType:(YSDrawType)drawType color:(NSString *)hexColor progress:(CGFloat)progress
{
    if (![hexColor bm_isNotEmpty])
    {
        hexColor = self.defaultPrimaryColor;
    }
        
    if ([self.currentConfig bm_isNotEmpty])
    {
        [self changePrimaryColor:hexColor];

        self.currentConfig.drawType = drawType;
        self.currentConfig.colorHex = self.primaryColorHex;
        self.currentConfig.progress = progress;
    }
}

/// 改变默认画笔颜色
- (void)changePrimaryColor:(NSString *)colorHex
{
    if (!colorHex)
    {
        self.primaryColorHex = self.defaultPrimaryColor;
        return;
    }
    
    NSMutableArray *colorMuArr = [NSMutableArray arrayWithObjects:
                                  @"#000000", @"#9B9B9B", @"#FFFFFF", @"#FF87A3", @"#FF515F", @"#FF0000",
                                  @"#E18838", @"#AC6B00", @"#864706", @"#FF7E0B", @"#FFD33B", @"#FFF52B",
                                  @"#B3D330", @"#88BA44", @"#56A648", @"#53B1A4", @"#68C1FF", @"#058CE5",
                                  @"#0B48FF", @"#C1C7FF", @"#D25FFA", @"#6E3087", @"#3D2484", @"#142473", nil];
    
    NSUInteger index = [colorMuArr indexOfObject:colorHex];
    if (index != NSNotFound)
    {
        self.primaryColorHex = colorHex;
    }
}

@end
