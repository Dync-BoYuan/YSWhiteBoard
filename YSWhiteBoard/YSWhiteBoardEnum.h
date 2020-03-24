//
//  YSWhiteBoardEnum.h
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/24.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#ifndef YSWhiteBoardEnum_h
#define YSWhiteBoardEnum_h

typedef NS_ENUM(NSInteger, YSEvent)
{
    YSEventShowPage        = 0,    //增加文档
    YSEventShapeAdd        = 2,    //增加画笔
    YSEventShapeClean      = 5,    //清屏
    YSEventShapeUndo       = 6,    //撤回
    YSEventShapeRedo       = 7,    //重做
};

typedef NS_ENUM(NSInteger, YSNativeToolType)
{
    YSNativeToolTypeMouse   = 100,
    YSNativeToolTypeLine    = 10,
    YSNativeToolTypeText    = 20,
    YSNativeToolTypeShape   = 30,
    YSNativeToolTypeEraser  = 50,
};

typedef NS_ENUM(NSInteger, YSToolSelectButtonIndex)
{
    Draw_Pen            = 10,       //画笔
    Draw_MarkPen        = 11,       //记号笔
    Draw_Line           = 12,       //直线
    Draw_Arrow          = 13,       //带箭头的直线
    
    Draw_EmptyRect      = 30,       //空心矩形
    Draw_SolidRect      = 31,       //实心矩形
    Draw_EmptyCircle    = 32,       //空心圆
    Draw_SolidCircle    = 33,       //实心圆
    
    Draw_Text_Size      = 20, //文字
    Draw_Text_Color     = 21,
    
    Draw_Edite_Select   = 40,//
    Draw_Edite_Delete   = 41,//
    Draw_Edite_Move     = 42,
    Draw_Edite_Clear    = 43,//
    
    Draw_Eraser         = 50,       //橡皮擦
    
    
    Draw_Undo           = 26,       //撤销
    Draw_Redo           = 27,       //重做
};

typedef NS_ENUM(NSUInteger, YSWorkMode)
{
    YSWorkModeViewer = 0,       //只能观看 不能标记 隐藏工具条
    YSWorkModeControllor = 1,   //操作状态
};

typedef NS_ENUM(NSInteger, YSDrawType)
{
    YSDrawTypePen               = 10,    //钢笔
    YSDrawTypeMarkPen           = 11,    //记号笔
    YSDrawTypeLine              = 12,    //直线
    YSDrawTypeArrowLine         = 13,    //箭头
    
    YSDrawTypeTextMS            = 20,    //微软雅黑字
    YSDrawTypeTextSong          = 21,    //宋体字
    YSDrawTypeTextArial         = 22,    //Arial字
    
    YSDrawTypeEmptyRectangle    = 30,    //空心矩形
    YSDrawTypeFilledRectangle   = 31,    //实心矩形
    YSDrawTypeEmptyEllipse      = 32,    //空心圆
    YSDrawTypeFilledEllipse     = 33,    //实心圆
    
    YSDrawTypeEraser            = 50,    //橡皮擦
    
    YSDrawTypeClear             = 60,    //清除画板内容
};

typedef NS_ENUM(NSInteger, YSBrushToolType)
{
    YSBrushToolTypeMouse   = 100,
    YSBrushToolTypeLine    = 10,
    YSBrushToolTypeText    = 20,
    YSBrushToolTypeShape   = 30,
    YSBrushToolTypeEraser  = 50,
};

typedef NS_ENUM(NSUInteger, YSWhiteBoardErrorCode)
{
    YSError_OK,
    YSError_Bad_Parameters,
};

#endif /* YSWhiteBoardEnum_h */
