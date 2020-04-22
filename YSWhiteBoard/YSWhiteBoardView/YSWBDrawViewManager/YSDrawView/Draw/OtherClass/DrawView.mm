//
//  DrawView.m
//  WhiteBoard
//
//  Created by macmini on 14/11/6.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "DrawView.h"
#include <functional>
#include <map>
#import "DrawLine.h"
#import "DrawPen.h"
#import "DrawCircle.h"
#import "DrawRectangle.h"
#import "DrawText.h"
//#import "YSWBMacro.h"
#import "YSWhiteBoardDefines.h"
#import <YSRoomSDK/YSRoomSDK.h>

struct CompareNSString: public std::binary_function<NSString*, NSString*, bool> {
    bool operator()(NSString* lhs, NSString* rhs) const {
        if (rhs != nil)
            return (lhs == nil) || ([lhs compare: rhs] == NSOrderedAscending);
        else
            return false;
    }
};


@interface DrawView ()<UITextViewDelegate>
{
    //当前绘制数组
    NSMutableArray <NSDictionary *>*_drawArray;
    ScreenScale _screenScale;
    //所有绘制数组
    NSMutableArray <NSDictionary *>*_drawBackArray;
    
    YSToolSelectButtonIndex _currentType;
    
    //当前绘制在所有绘制数组的指针
    NSInteger _operationPointer;
    
    NSMutableDictionary *_drawDictionary;
    
    DrawBase *_realTimeDraw;
    
    UITouch *_lastBeginTouch;
    
    BOOL _updateImmediately;
    
    NSMutableArray <UILabel *> *_drawersNames;
}

@end
@implementation DrawView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self!=nil)
    {
        _drawersNames = [NSMutableArray array];
        _shouldShowdraweraName = NO;
        _updateImmediately = YES;
        _mode = YSWorkModeViewer;
        _fileid = @"0";
        _pageId = 1;
        //        _drawDelegate = delegate;
        _screenScale.x = 1700 / self.frame.size.width;
        _screenScale.y = 960 / self.frame.size.height;
        //设置默认配置
        RGBAType rgb;
        rgb.r = 0.0f;
        rgb.g = 0.0f;
        rgb.b = 0.0f;
        rgb.a = 1.0f;
        _initializeRgb = rgb;
        self.backgroundColor = [UIColor clearColor];
        //[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        _drawArray = [@[] mutableCopy];
        _drawBackArray = [@[] mutableCopy];
        [_drawBackArray addObject:@{@"clear_" : [DrawBase new]}];
        _operationPointer = 0;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendTextDrawDirectly) name:YSWhiteSendTextDrawIfChooseMouseNotification object:nil];
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _drawersNames = [NSMutableArray array];
        _shouldShowdraweraName = NO;
        _updateImmediately = YES;
        _mode = YSWorkModeViewer;
        _fileid = @"0";
        _pageId = 1;
        _screenScale.x = 1700 / self.frame.size.width;
        _screenScale.y = 960 / self.frame.size.height;
        //设置默认配置
        RGBAType rgb;
        rgb.r = 0.0f;
        rgb.g = 0.0f;
        rgb.b = 0.0f;
        rgb.a = 1.0f;
        _initializeRgb = rgb;
        self.backgroundColor = [UIColor clearColor];
        //[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        _drawArray = [@[] mutableCopy];
        _drawBackArray = [@[] mutableCopy];
        [_drawBackArray addObject:@{@"clear_" : [DrawBase new]}];
        _operationPointer = 0;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendTextDrawDirectly) name:YSWhiteSendTextDrawIfChooseMouseNotification object:nil];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self refreshcreenScale];
}

-(void)refreshcreenScale
{
    //      NSLog(@"%@",NSStringFromCGRect(self.frame));
    //      web分辨率1700 * 960对应原生大小 440 * 247
    //      float newWebWidth = self.frame.size.width / 440 * webWidth;//683
    
    float webHeight = 960;
    float currentRatio = self.frame.size.width / self.frame.size.height;
    float webWidth = currentRatio * webHeight;
    
    _screenScale.x = webWidth / self.frame.size.width;
    _screenScale.y = webHeight / self.frame.size.height;
    
    if (isnan(_screenScale.x)) {
        _screenScale.x = _screenScale.y;
    }
    
    self.iFontScale = self.frame.size.width / webWidth;
    
    _draw.sacle = _screenScale;
    
    if (_updateImmediately) {
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    for (NSDictionary *dic in _drawArray) {
        DrawBase *data = dic[dic.allKeys.firstObject];
        data.sacle = _screenScale;
        data.iFontScale = self.iFontScale;
        [data onDraw:context];
    }
}

- (void)clearDraw
{
    NSString *whiteboardID = [YSRoomUtil getwhiteboardIDFromFileId:self.fileid];

    NSString *key = [NSString stringWithFormat:@"clear_%f", [NSDate date].timeIntervalSince1970];
    NSDictionary *dic = @{@"eventType" : @"clearEvent", @"actionName" : @"ClearAction", @"clearActionId" : key, @"whiteboardID" : whiteboardID, @"nickname" : @"tmp"};
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    if (error)
    {
        NSLog(@"error:%@",error);
        return;
    }
    NSString *shapeID = [NSString stringWithFormat:@"%@###_SharpsChange_%@_%d", key, self.fileid, self.pageId];
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [[YSRoomInterface instance] pubMsg:sYSSignalSharpsChange msgID:shapeID toID:YSRoomPubMsgTellAll data:dataString save:YES extensionData:@{} associatedMsgID:nil associatedUserID:nil expires:0 completion:^(NSError *error) {
        NSLog(@"%@",error);
    }];
    [self setNeedsDisplay];
}

-(void)selectDraw:(int)type
{
//    if (type != Draw_Pen) {
//        _mode = YSWorkModeControllor;
//    }
    
    _currentType = YSToolSelectButtonIndex(type);
    switch( type )
    {
        case Draw_Pen         : [self createDrawWithClass: [DrawPen class] Empty        :false]; break;
            
        case Draw_MarkPen     : [self createDrawWithClass: [DrawPen class] Empty        :true]; break;
            
        case Draw_Line        : [self createDrawWithClass: [DrawLine class] Empty      :true]; break;
            
        case Draw_Arrow       : [self createDrawWithClass: [DrawLine class] Empty      :false]; break;
            
        case Draw_EmptyRect   : [self createDrawWithClass: [DrawRectangle class] Empty  :true]; break;
            
        case Draw_SolidRect   : [self createDrawWithClass: [DrawRectangle class] Empty  :false];break;
            
        case Draw_EmptyCircle : [self createDrawWithClass: [DrawCircle class] Empty:true]; break;
            
        case Draw_SolidCircle : [self createDrawWithClass: [DrawCircle class] Empty:false]; break;
            
        case Draw_Text_Size   : [self createDrawWithClass: [DrawText class] Empty  :false]; break;
            
        case Draw_Text_Color  : [self createDrawWithClass: [DrawText class] Empty :false]; break;
            
        case Draw_Eraser      : [self createDrawWithClass: [DrawPen class] Empty     :false]; break;
            
        case Draw_Edite_Delete:
        {
            //            NSMutableArray *selectArray = [@[] mutableCopy];
            //            for (NSDictionary *dic in _drawArray) {
            //                DrawBase *data = dic[dic.allKeys.firstObject];
            //                if (data.draw_select) {
            //                    [selectArray addObject:data];
            //                }
            //            }
            //
            //            for (NSDictionary *dic in selectArray) {
            //                DrawBase *data = dic[dic.allKeys.firstObject];
            //                [self callShapedelDelegateWithFileID:_fileid shapeID:[data getDrawID]];
            //                [_drawArray removeObject:dic];
            //                break;
            //            }
            //
            //            [self setNeedsDisplay];
            break;
        }
        case Draw_Edite_Clear:
        {
            NSString *whiteboardID = [YSRoomUtil getwhiteboardIDFromFileId:self.fileid];

            NSString *key = [NSString stringWithFormat:@"clear_%f",[NSDate date].timeIntervalSince1970];
            NSDictionary *dic = @{@"eventType" : @"clearEvent", @"actionName" : @"ClearAction", @"clearActionId" : key, @"whiteboardID" : whiteboardID, @"nickname" : @"tmp"};
            NSError *error;
            NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
            if (error) {
                NSLog(@"error:%@",error);
                return;
            }
            NSString *shapeID = [NSString stringWithFormat:@"%@###_SharpsChange_%@_%d",key,self.fileid, self.pageId];
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [[YSRoomInterface instance] pubMsg:sYSSignalSharpsChange msgID:shapeID toID:YSRoomPubMsgTellAll data:dataString save:YES extensionData:@{} associatedMsgID:nil associatedUserID:nil expires:0 completion:^(NSError *error) {
                NSLog(@"%@",error);
            }];
            [self setNeedsDisplay];
            break;
        }
        case Draw_Undo:
        {
            [self undoDrawMap];
            //            if (self.drawDelegate && [self.drawDelegate respondsToSelector:@selector(addSharpWithFileID:shapeID:shapeData:)]) {
            //                NSDictionary *param = _drawBackArray[_operationPointer];
            //                DrawBase *draw = param[param.allKeys.firstObject];
            //                NSError *error;
            //                NSMutableDictionary *dic = [_draw serializedData];
            //                [dic setValue:@"undoEvent" forKey:@"eventType"];
            //                if (!dic || dic.allKeys.count == 0) {
            //                    return;
            //                }
            //                NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
            //                if (error) {
            //                    NSLog(@"error:%@",error);
            //                    return;
            //                }
            //
            //                [self.drawDelegate addSharpWithFileID:_fileid shapeID:[draw getDrawID] shapeData:data];
            //            }
            break;
        }
        case Draw_Redo:
        {
            [self redoDrawMapByClearID:nil];
            //            if (self.drawDelegate && [self.drawDelegate respondsToSelector:@selector(addSharpWithFileID:shapeID:shapeData:)]) {
            //                NSInteger pointer = _operationPointer + 1;
            //                NSDictionary *param = _drawBackArray[pointer];
            //                DrawBase *draw = param[param.allKeys.firstObject];
            //                NSError *error;
            //                NSMutableDictionary *dic = [_draw serializedData];
            //                [dic setValue:@"redoEvent" forKey:@"eventType"];
            //                if (!dic || dic.allKeys.count == 0) {
            //                    return;
            //                }
            //                NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
            //                if (error) {
            //                    NSLog(@"error:%@",error);
            //                    return;
            //                }
            //
            //                [self.drawDelegate addSharpWithFileID:_fileid shapeID:[draw getDrawID] shapeData:data];
            //            }
            
            break;
        }
    }
}

-(void)createDrawWithClass:(Class)type Empty:(bool)empty
{
    DRAWDATA d;
    memset(&d,0,sizeof(DRAWDATA));
    
    Pen pen;
    Brush brush;
    brush.color = _initializeRgb;
    if ([_draw isKindOfClass:[DrawText class]]) {
        pen.lpWidth = pen.lpWidth / 30 * self.iFontScale;
    }
    _draw = [[type alloc] initWithVersion:1 eventType:YSEventShapeAdd fileID:_fileid pageID:1 ScreenScale:_screenScale drawId:nil];
    if([_draw isKindOfClass:[DrawText class]]) {
        _draw.delegate = self;
    }
    
    brush.lbStyle = empty?BS_NULL:BS_SOLID;
    d.pen = pen;
    d.brush = brush;
    
    if([_draw isKindOfClass:[DrawLine class]] && _draw.drawData.brush.lbStyle==BS_NULL) {
        d.type = line;
    } else if ([_draw isKindOfClass:[DrawLine class]] && _draw.drawData.brush.lbStyle==BS_SOLID) {
        d.type = arrowLine;
    } else if ([_draw isKindOfClass:[DrawPen class]] && _currentType == Draw_MarkPen) {
        d.type = markerPen;
    } else if ([_draw isKindOfClass:[DrawRectangle class]]) {
        d.type = Rectangle;
    } else if ([_draw isKindOfClass:[DrawCircle class]]) {
        d.type = Ellipse;
    } else if ([_draw isKindOfClass:[DrawText class]]) {
        d.type = Text;
    } else if ([_draw isKindOfClass:[DrawPen class]] && _currentType == Draw_Eraser) {
        d.type = Eraser;
    } else if ([_draw isKindOfClass:[DrawPen class]] && _currentType == Draw_Pen) {
        d.type = markerPen;
    }
    
    _draw.drawData = d;
    if([_textView isFirstResponder]) {
        
        [_textView resignFirstResponder];
    }
    
    [_textView removeFromSuperview];
    _textView = nil;
}

- (void)sendTextDrawDirectly
{
    if (self.textView.superview) {
        [self touchesBegan:[NSSet setWithObject:_lastBeginTouch] withEvent:nil];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_mode == YSWorkModeControllor && ![YSRoomInterface instance].localUser.canDraw)
    {
        [super touchesBegan:touches withEvent:event];
        return;
    }

    if (_mode == YSWorkModeViewer || self.hidden)
    {
        [super touchesBegan:touches withEvent:event];
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    if (![_draw isKindOfClass:[DrawText class]]) {
        [_draw touchesBegan:point];
        _realTimeDraw = [_draw clone];
        _realTimeDraw.draw_id = [_draw getDrawID];
        [_realTimeDraw touchesBegan:point];
    } else {
        if (self.textView.text && self.textView.text.length > 0) {
            if (self.textView.isFirstResponder) {
                [self.textView resignFirstResponder];
            }
            [_draw touchesBegan:CGPointFromString(((DrawText *)_draw).pointString)];
            NSError *error;
            NSDictionary *dic = [_draw serializedData];
            if (!dic || dic.allKeys.count == 0) {
                return;
            }
            NSData *data = [NSJSONSerialization dataWithJSONObject:[_draw serializedData] options:NSJSONWritingPrettyPrinted error:&error];
            if (!error) {
                NSString *outID = [NSString stringWithFormat:@"%@###_SharpsChange_%@_%d", _draw.draw_id, self.fileid, self.pageId];
                if (_delegate && [_delegate respondsToSelector:@selector(addSharpWithFileID:shapeID:shapeData:)]) {
                    [_delegate addSharpWithFileID:_fileid shapeID:outID shapeData:data];
                }
            }
            [_draw touchesEnded:point];
        } else {
            _draw.iFontScale = self.iFontScale;
            [_draw touchesBegan:point];
            _lastBeginTouch = touch;
        }
    }
    
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    
    CGPoint point = [touch locationInView:self];
    
    if (_mode == YSWorkModeControllor && ![YSRoomInterface instance].localUser.canDraw)
    {
        [super touchesBegan:touches withEvent:event];
        return;
    }

    if (_mode == YSWorkModeViewer || self.hidden)
    {
        [super touchesMoved:touches withEvent:event];
        return;
    }
    
    if (!_draw) {
        return;
    }
    
    if ([_draw isKindOfClass:[DrawText class]])
    {
        return;
    }
    
    [_draw touchesMoved:point];
    
    if (![_draw isKindOfClass:[DrawText class]]) {
        [self realTimeDrawOnViewWithPoint:point];
    }
}

- (void)realTimeDrawOnViewWithPoint:(CGPoint)point
{
    if (!_realTimeDraw)
    {
        return;
    }
    
    //    //实时绘制
    [_realTimeDraw touchesMoved:point];
    
    __block BOOL has = NO;
    __block int index = 0;
    [_drawArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.allKeys.firstObject hasPrefix:@"RealTimeDraw-"]) {
            has = YES;
            index = (int)idx;
            *stop = YES;
        }
    }];
    if (has) {
        [_drawArray replaceObjectAtIndex:index withObject:@{[NSString stringWithFormat:@"RealTimeDraw-%@",_realTimeDraw.draw_id] : _realTimeDraw}];
    } else {
        //这里发生过闪退
        //reason:  attempt to insert nil object from objects[0]'
        [_drawArray addObject:@{[NSString stringWithFormat:@"RealTimeDraw-%@", _realTimeDraw.draw_id] : _realTimeDraw}];
    }
    if ([_realTimeDraw isKindOfClass:[DrawLine class]]) {
        if (!CGPointEqualToPoint(_realTimeDraw.drawData.start, _realTimeDraw.drawData.end)) {
             [self setNeedsDisplay];
        }
    } else {
         [self setNeedsDisplay];
    }
   
    
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //触控过短会导致系统认为canceltouchues执行本方法而不调用touchesEnded，需要将绘制移交到touchesEnded
    [self touchesEnded:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    if (_mode == YSWorkModeControllor && ![YSRoomInterface instance].localUser.canDraw)
    {
        [super touchesBegan:touches withEvent:event];
        return;
    }

    if (_mode == YSWorkModeViewer || self.hidden)
    {
        [super touchesBegan:touches withEvent:event];
        return;
    }
    
    if(!_draw) {
        return;
    }
    
    if (![_draw isKindOfClass:[DrawText class]]) {
        [_draw touchesEnded:point];
        [self realTimeDrawOnViewWithPoint:point];
    }
    
    if([_draw isKindOfClass:[DrawText class]] && (!((DrawText*)_draw).text || [((DrawText*)_draw).text isEqual:@""])) {
        return;
    }
    
    if (![_draw isKindOfClass:[DrawText class]]) {
        NSError *error;
        NSDictionary *dic = [_draw serializedData];
        if (!dic || dic.allKeys.count == 0) {
            return;
        }
        NSData *data = [NSJSONSerialization dataWithJSONObject:[_draw serializedData] options:NSJSONWritingPrettyPrinted error:&error];
        if (!error) {
            NSString *outID = [NSString stringWithFormat:@"%@###_SharpsChange_%@_%d", _draw.draw_id, self.fileid, self.pageId];
            if (_delegate && [_delegate respondsToSelector:@selector(addSharpWithFileID:shapeID:shapeData:)]) {
                [_delegate addSharpWithFileID:_fileid shapeID:outID shapeData:data];
            }
        }
    }
    
    _draw = [_draw clone];
}


//-(void)keyboardWillShow:(NSNotification*)notification
//{
//    if([_draw isKindOfClass:[DrawText class]])
//    {
//        [((DrawText*)_draw) keyboardWillShow:notification];
//    }
//}

- (void)switchFileID:(NSString *)fileID
      andCurrentPage:(int)currentPage
   updateImmediately:(BOOL)update
{
    if (!_drawDictionary) {
        _drawDictionary = [NSMutableDictionary dictionary];
    }
    
    //切换课件时总是先存下当前绘制信息
    NSString *oldKey = [NSString stringWithFormat:@"%@###%d", self.fileid, self.pageId];
    [_drawDictionary setValue:@[_drawBackArray, _drawArray, @(_operationPointer)] forKey:oldKey];
    
    
    //更新课件状态，fileid && pageid
    self.fileid = fileID;
    self.pageId = currentPage;
    
    //取更新状态的绘制数组
    NSString *newKey = [NSString stringWithFormat:@"%@###%d", self.fileid, self.pageId];
    NSArray *tmp = [_drawDictionary objectForKey:newKey];
    if (!tmp) {
        //重置
        _drawBackArray = [@[] mutableCopy];
        [_drawBackArray addObject:@{@"clear_" : [DrawBase new]}];
        _drawArray = [@[] mutableCopy];
        _operationPointer = 0;
    } else {
        NSArray *back = tmp[0];
        if (back.count >= 1) {
            //恢复_drawBackArray  &  _drawBackArray
            _drawBackArray = [NSMutableArray arrayWithArray:tmp[0]];
            _drawArray = [NSMutableArray arrayWithArray:tmp[1]];
            NSNumber *pointer = [tmp objectAtIndex:2];
            _operationPointer = pointer.integerValue;
        } else {
            //重置
            _drawBackArray = [@[] mutableCopy];
            [_drawBackArray addObject:@{@"clear_" : [DrawBase new]}];
            _drawArray = [@[] mutableCopy];
            _operationPointer = 0;
        }
    }
    
    if (update) {
        [self setNeedsDisplay];
    }
}

-(void)addDrawSharpData:(NSDictionary*)sharpData isUpdate:(BOOL)isUpdate
{
    _updateImmediately = isUpdate;
    [_drawArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.allKeys.firstObject hasPrefix:@"RealTimeDraw-"]) {
            [self->_drawArray removeObject:obj];
            *stop = YES;
        }
    }];
    
    DrawType factoryType = line;
    
    NSString *factoryTypeString = [[sharpData objectForKey:@"data"] objectForKey:@"className"];
    if ([factoryTypeString isEqualToString:@"LinePath"]) {
        //钢笔 or 记号笔(记号笔颜色半透明)
        factoryType = markerPen;
    }
    if ([factoryTypeString isEqualToString:@"Line"]) {
        NSArray *endCapShapes = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"endCapShapes"];
        if (endCapShapes.count > 1 && [[endCapShapes objectAtIndex:1] isKindOfClass:[NSString class]] && [[endCapShapes objectAtIndex:1] isEqualToString:@"arrow"]) {
            //箭头
            factoryType = arrowLine;
        } else {
            //直线
            factoryType = line;
        }
    }
    if ([factoryTypeString isEqualToString:@"Rectangle"]) {
        //方
        factoryType = Rectangle;
    }
    if ([factoryTypeString isEqualToString:@"Ellipse"]) {
        //圆
        factoryType = Ellipse;
    }
    if ([factoryTypeString isEqualToString:@"Text"]) {
        //文字
        factoryType = Text;
    }
    if ([factoryTypeString isEqualToString:@"ErasedLinePath"]) {
        //橡皮擦
        factoryType = Eraser;
    }
    
    
    DrawBase* dView;
    switch (factoryType) {
        case markerPen:
        {
            dView = [DrawPen deserializeData:sharpData];
        }
            break;
        case arrowLine:
        {
            dView = [DrawLine deserializeData:sharpData];
        }
            break;
        case line:
        {
            dView = [DrawLine deserializeData:sharpData];
        }
            break;
        case Rectangle:
        {
            dView = [DrawRectangle deserializeData:sharpData];
        }
            break;
        case Ellipse:
        {
            dView = [DrawCircle deserializeData:sharpData];
        }
            break;
        case Text:
        {
            dView = [DrawText deserializeData:sharpData];
        }
            break;
        case Eraser:
        {
            dView = [DrawPen deserializeData:sharpData];
        }
            break;
        default:
            break;
    }
    //坐标转换
    if (!dView) {
        return;
    }
    DRAWDATA drawData = dView.drawData;
    drawData.start = CGPointMake(dView.drawData.start.x, dView.drawData.start.y);
    drawData.end = CGPointMake(dView.drawData.end.x, dView.drawData.end.y);
    dView.drawData = drawData;
    
    [self putDrawersName:dView.nickname byPoint:drawData.end drawType:factoryType];
    
    _operationPointer++;
    if (_operationPointer >=  _drawBackArray.count) {
        _operationPointer = _drawBackArray.count;
        [_drawBackArray addObject:@{[dView getDrawID] : dView}];
        NSMutableArray *recoveryArray = [@[] mutableCopy];
        for (NSInteger i = _operationPointer; i >= 0; i--) {
            NSString *key = ((NSDictionary *)_drawBackArray[i]).allKeys.lastObject;
            if (![key hasPrefix:@"clear_"]) {
                [recoveryArray addObject:_drawBackArray[i]];
            } else {
                break;
            }
        }
        [_drawArray removeAllObjects];
        [_drawArray addObjectsFromArray:[recoveryArray reverseObjectEnumerator].allObjects];
    } else {
        NSString *nextKey = ((NSDictionary *)_drawBackArray[_operationPointer]).allKeys.firstObject;
        //需要增加的draw
        NSString *key = dView.draw_id;
        if ([key isEqualToString:nextKey]) {
            //只需移动指针
            NSMutableArray *recoveryArray = [@[] mutableCopy];
            for (NSInteger i = _operationPointer; i >= 0; i--) {
                NSString *key = ((NSDictionary *)_drawBackArray[i]).allKeys.lastObject;
                if (![key hasPrefix:@"clear_"]) {
                    [recoveryArray addObject:_drawBackArray[i]];
                } else {
                    break;
                }
            }
            [_drawArray removeAllObjects];
            [_drawArray addObjectsFromArray:[recoveryArray reverseObjectEnumerator].allObjects];
            
        } else {
            //先移除后面所有draw
            [_drawBackArray removeObjectsInRange:NSMakeRange(_operationPointer, _drawBackArray.count - _operationPointer)];
            //更新draw
            [_drawBackArray addObject:@{dView.draw_id : dView}];
            NSMutableArray *recoveryArray = [@[] mutableCopy];
            for (NSInteger i = _operationPointer; i >= 0; i--) {
                NSString *key = ((NSDictionary *)_drawBackArray[i]).allKeys.lastObject;
                if (![key hasPrefix:@"clear_"]) {
                    [recoveryArray addObject:_drawBackArray[i]];
                } else {
                    break;
                }
            }
            [_drawArray removeAllObjects];
            [_drawArray addObjectsFromArray:[recoveryArray reverseObjectEnumerator].allObjects];
            
        }
    }
    if (isUpdate) {
        [self setNeedsDisplay];
    }
}

-(void)removeDrawData:(NSString*)sharpid
{
    for (NSDictionary *dic in _drawArray) {
        NSString *key = dic.allKeys.firstObject;
        if ([key isEqualToString:sharpid]) {
            [_drawArray removeObject:dic];
            _operationPointer--;
            break;
        }
    }
    [self setNeedsDisplay];
}

//撤销绘制
- (void)undoDrawMap
{
    _operationPointer--;
    if (_operationPointer < 0) {
        _operationPointer = 0;
        return;
    }
    NSString *currentKey = ((NSDictionary *)_drawBackArray[_operationPointer]).allKeys.lastObject;
    if ([currentKey hasPrefix:@"clear_"]) {
        [_drawArray removeAllObjects];
    } else {
        NSMutableArray *recoveryArray = [@[] mutableCopy];
        for (NSInteger i = _operationPointer; i >= 0; i--) {
            NSString *key = ((NSDictionary *)_drawBackArray[i]).allKeys.lastObject;
            if (![key hasPrefix:@"clear_"]) {
                [recoveryArray addObject:_drawBackArray[i]];
            } else {
                break;
            }
        }
        [_drawArray removeAllObjects];
        [_drawArray addObjectsFromArray:[recoveryArray reverseObjectEnumerator].allObjects];
    }
    
    [self setNeedsDisplay];
}

//重置绘制，只有不需要redo而是add的时候才返回NO
- (BOOL)redoDrawMapByClearID:(NSString *)redoID
{
    if (![redoID bm_isNotEmpty])
    {
        return NO;
    }
    //如果本地没有redo数据远端直接redo相当于add数据
    BOOL has = NO;
    for (NSDictionary *dic in _drawBackArray) {
        if ([dic bm_isNotEmptyDictionary])
        {
            NSString *key = dic.allKeys.firstObject;
            if ([key bm_isNotEmpty])
            {
                if ([key isEqualToString:redoID]) {
                    has = YES;
                    break;
                }
            }
        }
    }
    
    if (!has) {
        return NO;
    }
    
    _operationPointer++;
    if (_operationPointer >= _drawBackArray.count) {
        _operationPointer = _drawBackArray.count - 1;
        return YES;
    }
    
    NSString *currentKey = ((NSDictionary *)_drawBackArray[_operationPointer]).allKeys.lastObject;
    if ([currentKey hasPrefix:@"clear_"]) {
        [_drawArray removeAllObjects];
    } else {
        NSMutableArray *recoveryArray = [@[] mutableCopy];
        for (NSInteger i = _operationPointer; i >= 0; i--) {
            NSString *key = ((NSDictionary *)_drawBackArray[i]).allKeys.lastObject;
            if (![key hasPrefix:@"clear_"]) {
                [recoveryArray addObject:_drawBackArray[i]];
            } else {
                break;
            }
        }
        [_drawArray removeAllObjects];
        [_drawArray addObjectsFromArray:[recoveryArray reverseObjectEnumerator].allObjects];
    }
    
    [self setNeedsDisplay];
    return YES;
}

//恢复清空
- (void)recoveryDrawMapByClearID:(NSString *)clearID
{
//    BOOL hasClearID = NO;
    NSMutableArray *showDataArray = [@[] mutableCopy];
    for (NSInteger i = _drawBackArray.count - 1; i >= 0; i --) {
        NSString *key = ((NSDictionary *)_drawBackArray[i]).allKeys.firstObject;
        if ([key isEqualToString:clearID]) {
//            hasClearID = YES;
            for (NSInteger j = i - 1; j >= 0; j--) {
                NSString *innerKey = ((NSDictionary *)_drawBackArray[j]).allKeys.firstObject;
                if (![innerKey hasPrefix:@"clear_"]) {
                    [showDataArray addObject:_drawBackArray[j]];
                } else {
                    _operationPointer = j;
                    break;
                }
            }
        }
    }
    
    if (showDataArray.count > 0) {
        [_drawArray removeAllObjects];
    }
    
    [_drawArray addObjectsFromArray:[showDataArray reverseObjectEnumerator].allObjects];
    
    [self setNeedsLayout];
}

//清空绘制
-(void)clearDrawMapByClearID:(NSString *)clearID
{
    if ([((NSDictionary *)_drawArray.lastObject).allKeys.firstObject hasPrefix:@"clear_"]) {
        return;
    }
    
    NSMutableArray *moveArray = [@[] mutableCopy];
    for (long i = _operationPointer + 1; i < _drawBackArray.count; i++) {
        [moveArray addObject:_drawBackArray[i]];
    }
    [_drawBackArray removeObjectsInArray:moveArray];
    
    [_drawBackArray addObject:@{clearID : [DrawBase new]}];
    _operationPointer = _drawBackArray.count - 1;
    
    [_drawArray removeAllObjects];
    
    [self setNeedsDisplay];
}

//下课调用
- (void)clearDataAfterClass
{
    [_drawArray removeAllObjects];
    [_drawBackArray removeAllObjects];
    [_drawBackArray addObject:@{@"clear_" : [DrawBase new]}];
    _operationPointer = 0;
    [_drawDictionary removeAllObjects];
    [self setNeedsDisplay];
}

-(void)clearDrawMap:(NSString *)fileId
{
    if (_drawArray.count > 0) {
        for (NSDictionary *dic in _drawArray) {
            DrawBase *data = dic[dic.allKeys.firstObject];
            if (data.fileId == fileId) {
                [_drawArray removeObject:dic];
                break;
            }
        }
    }
}

- (void)clearOnePageWithFileID:(NSString *)fileID pageNum:(int)pageNum
{
    [_drawDictionary removeObjectForKey:[NSString stringWithFormat:@"%@###%d",fileID,pageNum]];
}

- (void)removeOneDraw:(NSString *)drawID
{
    [_drawArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        DrawBase *data = obj[obj.allKeys.firstObject];
        if ([data.draw_id isEqualToString:drawID]) {
            [self->_drawArray removeObject:obj];
            *stop = YES;
            [self setNeedsDisplay];
        }
    }];
}

- (void)putDrawersName:(NSString *)name byPoint:(CGPoint)point drawType:(DrawType)type
{
    if (type == Eraser) {
        return;
    }
    
    if (!_shouldShowdraweraName) {
        return;
    }
    if (!_updateImmediately) {
        return;
    }
    UIFont *font = [UIFont systemFontOfSize:10];    //字体大小
    int64_t delaySeconds = 3;                       //延迟消失时间
    
    CGSize size = [name boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, font.lineHeight) options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : font} context:nil].size;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(point.x / _screenScale.x, point.y / _screenScale.y, size.width, size.height)];
    label.font = font;
    label.text = name;
    label.textColor = UIColor.blackColor;
    [self addSubview:label];
    [_drawersNames addObject:label];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [label removeFromSuperview];
        [self->_drawersNames removeObject:label];
    });
}

- (void)clearDrawersNameAfterShowPage
{
    [_drawersNames enumerateObjectsUsingBlock:^(UILabel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
}

@end
