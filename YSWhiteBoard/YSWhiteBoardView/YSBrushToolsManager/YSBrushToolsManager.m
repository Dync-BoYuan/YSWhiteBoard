//
//  YSBrushToolsManager.m
//  YSWhiteBoard
//
//  Created by 马迪 on 2020/4/2.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSBrushToolsManager.h"


@interface YSBrushToolsManager ()

///默认颜色
@property (nonatomic, copy) NSString *defaultPrimaryColor;

///当前的配置
@property (nonatomic, strong) YSBrushToolsConfigs *currentConfig;

@property (nonatomic, strong) YSBrushToolsConfigs *lineConfig;
@property (nonatomic, strong) YSBrushToolsConfigs *textConfig;
@property (nonatomic, strong) YSBrushToolsConfigs *sharpConfig;
@property (nonatomic, strong) YSBrushToolsConfigs *eraserConfig;

@end

@implementation YSBrushToolsManager


static YSBrushToolsManager *brushTools = nil;
+(instancetype )shareInstance
{
    @synchronized(self)
    {
        if (!brushTools)
        {
            brushTools = [[YSBrushToolsManager alloc] init];
        }
        [brushTools makeDefaultToolConfigs];
    }
    return brushTools;
}

///原始配置
- (void)makeDefaultToolConfigs
{
    // 默认颜色 红
    self.defaultPrimaryColor = @"#FF0000";
    [self freshBrushToolConfigs];
}

///画笔默认配置
- (void)freshBrushToolConfigs
{
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

///选择画笔工具
- (void)brushToolsDidSelect:(YSBrushToolType)BrushToolType
{
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
- (void)didSelectDrawType:(YSDrawType)type color:(NSString *)hexColor widthProgress:(float)progress
{
    NSUInteger toolType = 0;

    if (type >= YSDrawTypeClear)
    {
        toolType = YSBrushToolTypeClear;
    }
    else if (type >= YSDrawTypeEraser)
    {
        toolType = YSBrushToolTypeEraser;
    }
    else if (type >= YSDrawTypeEmptyRectangle)
    {
        toolType = YSBrushToolTypeShape;
    }
    else if (type >= YSDrawTypeTextMS)
    {
        toolType = YSBrushToolTypeText;
    }
    else if (type >= YSDrawTypePen)
    {
        toolType = YSBrushToolTypeLine;
    }
    
    if (toolType)
    {
        [self changeToolConfigWithToolType:toolType drawType:type color:hexColor progress:progress];
    }
}

///画笔属性变化时修改配置
- (void)changeToolConfigWithToolType:(YSBrushToolType)type drawType:(YSDrawType)drawType color:(NSString *)hexColor progress:(float)progress
{
    if (![hexColor bm_isNotEmpty])
    {
        hexColor = self.defaultPrimaryColor;
    }
    YSBrushToolsConfigs * configs = nil;
    switch (type)
    {
        case YSBrushToolTypeLine:
        {
            configs = self.lineConfig;
            break;
        }
        case YSBrushToolTypeText:
        {
            configs = self.textConfig;
        }
            break;
        case YSBrushToolTypeShape:
        {
            configs = self.sharpConfig;
        }
            break;
        case YSBrushToolTypeEraser:
        {
            configs = self.eraserConfig;
        }
            break;
        default:
            break;
    }
    
    if ([configs bm_isNotEmpty])
    {
        configs.drawType = drawType;
        configs.colorHex = hexColor;
        configs.progress = progress;
        
        self.currentConfig = configs;
    }
}

/// 改变默认画笔颜色
- (void)changeDefaultPrimaryColor:(NSString *)colorHex
{
    if (!colorHex)
       {
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
        self.defaultPrimaryColor = colorHex;
    }
}

/// 获取当前工具配置设置
//- (YSBrushToolsConfigs *)getWbToolConfigWithToolType:(YSBrushToolType)type
//{
//    switch (type)
//    {
//        case YSBrushToolTypeLine:
//        {
//            return self.lineConfig;
//            break;
//        }
//        case YSBrushToolTypeText:
//        {
//            return self.textConfig;
//        }
//            break;
//        case YSBrushToolTypeShape:
//        {
//            return self.sharpConfig;
//        }
//            break;
//        case YSBrushToolTypeEraser:
//        {
//            return self.eraserConfig;
//        }
//            break;
//        default:
//            return nil;
//            break;
//    }
//}

@end
