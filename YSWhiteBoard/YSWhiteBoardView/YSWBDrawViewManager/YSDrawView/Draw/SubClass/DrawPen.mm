//
//  DrawPen.m
//  WhiteBoard
//
//  Created by macmini on 14/11/7.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "DrawPen.h"
#import <YSRoomSDK/YSRoomSDK.h>
//#import "WhiteBoard.h"

@interface DrawPen ()
{
    NSMutableDictionary *_serializedData;
    BOOL _isErase;
}

@end
@implementation DrawPen
-(id)init
{
    self = [super init];
    if (self != nil)
    {
    }
    return self;
}

-(void)onDraw:(CGContextRef)context
{
    CGPoint start = CGPointMake(self.drawData.start.x/self.sacleX, self.drawData.start.y/self.sacleY);
    CGPoint end = CGPointMake(self.drawData.end.x/self.sacleX, self.drawData.end.y/self.sacleY);
    const CGFloat  dashArray1[] = {3, 2};//虚线
    const CGFloat  dashArray2[] = {0, 0};//实线
    CGContextSetLineWidth(context, self.drawData.pen.lpWidth * self.iFontScale);
    CGContextSetLineDash(context, 0, dashArray2, 0);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, BMRGBColor(self.drawData.brush.color.r*255,self.drawData.brush.color.g*255,self.drawData.brush.color.b*255,self.drawData.brush.color.a).CGColor);
    CGContextSetFillColorWithColor(context, BMRGBColor(self.drawData.brush.color.r*255,self.drawData.brush.color.g*255,self.drawData.brush.color.b*255,self.drawData.brush.color.a).CGColor);
    auto it = _pointList.begin();
    CGPoint lastPoint = CGPointMake((*it).x/self.sacle.x, (*it).y/self.sacle.y);
    CGContextMoveToPoint(context, lastPoint.x, lastPoint.y);
    for (; it!= _pointList.end(); it++)
    {
        //        lastPoint = CGPointMake((*it).x/self.sacle.x, (*it).y/self.sacle.y);
        //        CGContextAddLineToPoint(context, lastPoint.x, lastPoint.y);
        CGPoint nextPoint = CGPointMake((*it).x/self.sacle.x, (*it).y/self.sacle.y);
        CGPoint middlePoint = CGPointMake((lastPoint.x + nextPoint.x) / 2, (lastPoint.y + nextPoint.y) / 2);
        CGContextAddQuadCurveToPoint(context, lastPoint.x, lastPoint.y, middlePoint.x, middlePoint.y);
        //        CGContextMoveToPoint(context, nextPoint.x, nextPoint.y);
        lastPoint = nextPoint;
    }
    
    //橡皮擦
    if (self.drawData.type == Eraser) {
        CGContextSetBlendMode(context, kCGBlendModeClear);
    }
    CGContextStrokePath(context);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    //橡皮擦使用完之后切换绘制混合模式为原来模式
    
    if(self.draw_select)//绘制选中状态
    {
        CGContextSetLineWidth(context, 0.2);
        CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1);//黑
        CGContextSetLineDash(context, 0, dashArray1, 2);
        CGRect rect = CGRectMake(start.x-5, start.y-5, end.x - start.x+10, end.y - start.y+10);
        CGContextAddRect(context,rect);
        CGContextStrokePath(context);
    }
}
-(bool)select:(CGRect)rect
{
    bool isSelect = false;
    
    for(auto it = _pointList.begin();it!=_pointList.end();it++)
    {
        CGPoint p =*it;
        if(CGRectContainsPoint(rect,p))
        {
            isSelect= true;
        }
        if(isSelect)
        {
            float minX = self.drawData.start.x;
            float minY = self.drawData.start.y;
            
            float maxX = self.drawData.end.x;
            float maxY = self.drawData.end.y;
            for(auto itetor = _pointList.begin();itetor!=_pointList.end();itetor++)
            {
                CGPoint myPoint = *itetor;
                //最小的x
                minX = fmin(minX,myPoint.x);
                //最小的y
                minY = fmin(minY,myPoint.y);
                
                //最大的x
                maxX = fmax(maxX,myPoint.x);
                //最大的y
                maxY = fmax(maxY,myPoint.y);
                
            }
            DRAWDATA data = self.drawData;
            data.start = CGPointMake(minX, minY);
            data.end = CGPointMake(maxX, maxY);
            self.drawData = data;
            return true;
        }
    }
    return false;
}

-(DrawBase*)clone
{
    DrawPen* pen = [[DrawPen alloc] init];
    pen.draw_select = self.draw_select;
    pen.version = self.version;
    pen.type = self.type;
    pen.fileId = self.fileId;
    pen.pageid = self.pageid;
    pen.sacle =self.sacle;
    
    pen.drawData = self.drawData;
    pen.draw_select = self.draw_select;
    return pen;
}
-(void)touchesBegan:(CGPoint)point
{
    [super touchesBegan:point];
    CGPoint relativePoint = CGPointMake(point.x*self.sacle.x, point.y*self.sacle.y);
    _pointList.push_back(relativePoint);
}

-(void)touchesMoved:(CGPoint)point
{
    [super touchesMoved:point];
    CGPoint relativePoint = CGPointMake(point.x*self.sacle.x, point.y*self.sacle.y);
    _pointList.push_back( relativePoint );
}

-(void)touchesEnded:(CGPoint)point
{
    [super touchesEnded:point];
    CGPoint relativePoint = CGPointMake(point.x*self.sacle.x, point.y*self.sacle.y);
    _pointList.push_back( relativePoint );
}

-(void)setOffset:(CGPoint)offset
{
    auto it = _pointList.begin();
    for(;it!=_pointList.end();it++)
    {
        CGPoint p =*it;
        *it = CGPointMake(p.x+offset.x*self.sacle.x, p.y+offset.y*self.sacle.y);
        //算出选中框存放在起点终点里
    }
    DRAWDATA data =self.drawData;
    data.start =CGPointMake(self.drawData.start.x+offset.x*self.sacle.x, self.drawData.start.y+offset.y*self.sacle.y);
    data.end =CGPointMake(self.drawData.end.x+offset.x*self.sacle.x, self.drawData.end.y+offset.y*self.sacle.y);
    self.drawData = data;
}

+ (DrawPen *)deserializeData:(NSDictionary *)data
{
    DrawBase * drawBase = [super deserializeData:data];
    
    NSDictionary *sharpData = data;
    DRAWDATA drawData;
    drawData.version = 1;
    drawBase.draw_id = [sharpData objectForKey:@"shapeId"];
    NSString *className = [[data objectForKey:@"data"] objectForKey:@"className"];
    //    drawData.type = line;
    
    ///???:此处会为NULL 导致崩溃
    drawData.type = [className isEqualToString:@"ErasedLinePath"] ? Eraser : markerPen;
    NSArray *startPoint = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"pointCoordinatePairs"];
    
    NSNumber *firstX = (NSNumber *)([startPoint.firstObject objectAtIndex:0]);
    NSNumber *firstY = (NSNumber *)([startPoint.firstObject objectAtIndex:1]);
    float startX = 0;
    float startY = 0;
    if (![firstX isEqual:[NSNull null]]) {
        startX = firstX.floatValue;
    }
    if (![firstY isEqual:[NSNull null]]) {
        startY = firstY.floatValue;
    }
    drawData.start =CGPointMake(startX, startY);
    
    NSNumber *lastX = (NSNumber *)([startPoint.lastObject objectAtIndex:0]);
    NSNumber *lastY = (NSNumber *)([startPoint.lastObject objectAtIndex:1]);
    float endX = 0;
    float endY = 0;
    if (![lastX isEqual:[NSNull null]]) {
        endX = lastX.floatValue;
    }
    if (![lastY isEqual:[NSNull null]]) {
        endY = lastY.floatValue;
    }
    drawData.end = CGPointMake(endX, endY);
    ScreenScale scale = {0,0};
    DrawPen *drawPen = [[DrawPen alloc]initWithVersion:drawBase.version eventType:drawBase.type fileID:drawBase.fileId pageID:drawBase.pageid ScreenScale:scale drawId:drawBase.draw_id];
    drawPen.nickname = drawBase.nickname;
    NSString *colorString = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"pointColor"];
    
    Brush bush;
    bush.color = [DrawBase rgbaColorFromColorString:colorString];
    Pen pen;
    pen.color = bush.color;
    NSNumber *pointSize = (NSNumber *)[[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"pointSize"];
    pen.lpWidth = 0;
    if (![pointSize isEqual:[NSNull null]]) {
        pen.lpWidth = pointSize.floatValue;
    }
    drawData.brush = bush;
    drawData.pen = pen;
    drawPen.drawData = drawData;
    
    NSArray*points = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"pointCoordinatePairs"];
    std::list<CGPoint> pointList;
    for(NSArray* point in points)
    {
        NSNumber *X = (NSNumber *)[point objectAtIndex:0];
        NSNumber *Y = (NSNumber *)[point objectAtIndex:1];
        float x = 0;
        float y = 0;
        if (![X isEqual:[NSNull null]]) {
            x = X.floatValue;
        }
        if (![Y isEqual:[NSNull null]]) {
            y = Y.floatValue;
        }
        CGPoint p = CGPointMake(x, y);
        pointList.push_front(p);
    }
    drawPen.pointList = pointList;
    return drawPen;
}

- (NSMutableDictionary *)serializedData
{
    //    if (_serializedData == nil) {
    NSMutableDictionary *dictionary = [super serializedData];
    [dictionary setObject:@"shapeSaveEvent" forKey:@"eventType"];
    [dictionary setObject:@"AddShapeAction" forKey:@"actionName"];
    [dictionary setObject:[self getDrawID] forKey:@"shapeId"];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:@"LinePath" forKey:@"className"];
    if (self.drawData.type == Eraser) {
        [data setObject:@"ErasedLinePath" forKey:@"className"];
    }
    
    NSMutableDictionary *innerData = [NSMutableDictionary dictionary];
    [innerData setObject:@(3) forKey:@"order"];
    [innerData setObject:@(3) forKey:@"tailSize"];
    [innerData setObject:@(YES) forKey:@"smooth"];
    NSMutableArray* points =[[NSMutableArray alloc]init];
    auto it = _pointList.begin();
    for(;it!= _pointList.end();it++)
    {
        CGPoint p = *it;
        NSArray *point = [NSArray arrayWithObjects:@(ceil(p.x)),@(ceil(p.y)), nil];
        if (![point.firstObject isKindOfClass:NSNull.class] && ![point.lastObject isKindOfClass:NSNull.class]) {
            
            [points addObject:point];
        }
    }
    
    NSArray *firstOfThefirstPoint = [NSArray arrayWithArray:points.firstObject];
    //    NSArray *lastOfTheLastPoint = [NSArray arrayWithArray:points.lastObject];
    [points insertObject:firstOfThefirstPoint atIndex:0];
    //    [points addObject:lastOfTheLastPoint];
    
    [innerData setObject:points forKey:@"pointCoordinatePairs"];
    [innerData setObject:@(self.drawData.pen.lpWidth) forKey:@"pointSize"];
    
    if (self.drawData.brush.lbStyle) {
        RGBAType rgba = self.drawData.brush.color;
        RGBAType color = {rgba.r, rgba.g, rgba.b, 0.5f};
        [innerData setObject:[DrawBase colorStringFromRGBAType:color] forKey:@"pointColor"];
    } else {
        [innerData setObject:[DrawBase colorStringFromRGBAType:self.drawData.brush.color] forKey:@"pointColor"];
    }
    
    
    [data setValue:innerData forKey:@"data"];
    [data setValue:[self getDrawID] forKey:@"id"];
    
    [dictionary setObject:data forKey:@"data"];
    [dictionary setObject:@"default" forKey:@"whiteboardID"];
    [dictionary setObject:[YSRoomInterface instance].localUser.nickName ? : @" " forKey:@"nickname"];
    
    _serializedData = dictionary;
    
    return _serializedData;
}

@end
