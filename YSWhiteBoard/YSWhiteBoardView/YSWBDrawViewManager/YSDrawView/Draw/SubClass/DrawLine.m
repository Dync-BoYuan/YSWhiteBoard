//
//  DrawLine.m
//  WhiteBoard
//
//  Created by macmini on 14/11/7.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "DrawLine.h"
#import <YSRoomSDK/YSRoomSDK.h>
#define lineWidth 5
@interface DrawLine ()
{
    NSMutableDictionary *_serializedData;
}
@end
@implementation DrawLine
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
    [super onDraw:context];
    
    CGPoint start = CGPointMake(self.drawData.start.x/self.sacle.x, self.drawData.start.y/self.sacle.y);
    CGPoint end = CGPointMake(self.drawData.end.x/self.sacle.x, self.drawData.end.y/self.sacle.y);

    const CGFloat  dashArray1[] = {3, 2};//虚线
    const CGFloat  dashArray2[] = {0, 0};//实线
    CGContextSetStrokeColorWithColor(context, BMRGBColor(self.drawData.brush.color.r*255,self.drawData.brush.color.g*255,self.drawData.brush.color.b*255,self.drawData.brush.color.a*255).CGColor);
    CGContextSetFillColorWithColor(context, BMRGBColor(self.drawData.brush.color.r*255,self.drawData.brush.color.g*255,self.drawData.brush.color.b*255,self.drawData.brush.color.a*255).CGColor);
    CGContextMoveToPoint(context, start.x, start.y);
    CGContextAddLineToPoint(context, end.x, end.y);
    CGContextSetLineWidth(context, self.drawData.pen.lpWidth * self.iFontScale);
    CGContextSetLineDash(context, 0, dashArray2, 0);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    if(self.drawData.brush.lbStyle == BS_SOLID) {
        //这里是箭头
        
        CGContextStrokePath(context);
        
        double slopy , cosy , siny;
        double Par = self.drawData.pen.lpWidth * self.iFontScale * 2;//ARROWLENGTH
        slopy = atan2((start.y - end.y),
                      (start.x - end.x));
        
        cosy = cos( slopy );
        siny = sin( slopy );

//        CGContextMoveToPoint(context, end.x, end.y);
//
//        CGContextAddLineToPoint( context,end.x + ( Par * cosy - ( Par /2.0 * siny ) ),
//                                end.y + ( Par * siny + ( Par /2.0 * cosy ) ) );
//
//        CGContextMoveToPoint( context,end.x + ( Par * cosy + Par /2.0 * siny ),
//                             end.y - ( Par /2.0 * cosy - Par * siny ) );
//
//        CGContextAddLineToPoint(context, end.x, end.y);
        CGContextSetLineWidth(context, 2);
        CGContextSetFillColorWithColor(context, BMRGBColor(self.drawData.brush.color.r*255,self.drawData.brush.color.g*255,self.drawData.brush.color.b*255,self.drawData.brush.color.a*255).CGColor);
        //移动到三角顶点C
        CGContextMoveToPoint(context, end.x - cosy * Par, end.y - siny * Par);
        //添加边线到底部A点
        CGContextAddLineToPoint(context, end.x - cosy * Par + ( Par * cosy - ( Par /2.0 * siny ) ), end.y - siny * Par + ( Par * siny + ( Par /2.0 * cosy ) ) );
        //添加边线到底部B点
        CGContextAddLineToPoint(context, end.x - cosy * Par + ( Par * cosy + Par /2.0 * siny ), end.y - siny * Par - ( Par /2.0 * cosy - Par * siny ) );
        //添加边线到三角顶点C
        CGContextClosePath(context);
        CGContextFillPath(context);
//        CGContextStrokePath(context);
    } else {
        CGContextStrokePath(context);
    }

    
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
-(DrawBase*)clone
{
    DrawLine* line = [[DrawLine alloc] init];
    line.draw_select = self.draw_select;
    line.version = self.version;
    line.type = self.type;
    line.fileId = self.fileId;
    line.pageid = self.pageid;
    line.sacle =self.sacle;
    line.sacleX = self.sacleX;
    line.sacleY = self.sacleY;
    line.drawData = self.drawData;
    
    return line;
}


-(bool)select:(CGRect)rect
{
    CGPoint start = CGPointMake(self.drawData.start.x, self.drawData.start.y);
    CGPoint end = CGPointMake(self.drawData.end.x, self.drawData.end.y);
    //线段长度：
    float lineLength = sqrtf((end.x - start.x)*(end.x - start.x)+(end.y - start.y)*(end.y - start.y));
    int num = lineLength/self.drawData.pen.lpWidth;//类似微积分原理
    for(int i = 0;i<num;i++)
    {
        CGRect viewRect = CGRectMake(start.x+(end.x - start.x)*i/num, start.y+(end.y - start.y)*i/num, (end.x - start.x)/num, (end.y - start.y)/num);
        if(CGRectIntersectsRect(rect,viewRect))
            return true;
    }
    return false;
}

+ (DrawLine *)deserializeData:(NSDictionary *)data
{
    DrawBase * drawBase = [super deserializeData:data];
    
    NSDictionary *sharpData = data;
    DRAWDATA drawData;
    drawData.version = 1;
    drawBase.draw_id =[sharpData objectForKey:@"shapeId"];
    drawData.type = line;
    
    NSNumber *x1 = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"x1"];
    NSNumber *y1 = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"y1"];
    NSNumber *x2 = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"x2"];
    NSNumber *y2 = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"y2"];
    
    x1 = [x1 isEqual:[NSNull null]] ? @(0) : x1;
    y1 = [y1 isEqual:[NSNull null]] ? @(0) : y1;
    x2 = [x2 isEqual:[NSNull null]] ? @(0) : x2;
    y2 = [y2 isEqual:[NSNull null]] ? @(0) : y2;
    
    drawData.start =CGPointMake(x1.floatValue, y1.floatValue);
    drawData.end = CGPointMake(x2.floatValue, y2.floatValue);
    if (CGPointEqualToPoint(drawData.start, drawData.end)) {
        return nil;
    }
    ScreenScale scale = {0,0};
    DrawLine *drawLine = [[DrawLine alloc]initWithVersion:drawBase.version eventType:drawBase.type fileID:drawBase.fileId pageID:drawBase.pageid ScreenScale:scale drawId:drawBase.draw_id];
    drawLine.nickname = drawBase.nickname;
    NSString *colorString = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"color"];
    Brush bush;

    bush.color = [DrawBase rgbaColorFromColorString:colorString];
    NSString *arrowType = nil;
    NSArray *endCapShapes = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"endCapShapes"];
    if (endCapShapes.count < 2) {
        arrowType = @"line";
    } else {
        arrowType = [endCapShapes objectAtIndex:1];
    }
    
    bush.lbStyle = ([arrowType isKindOfClass:[NSString class]] && [arrowType isEqualToString:@"arrow"]) == arrowLine?BS_SOLID:BS_NULL;
    Pen pen;
    pen.color = bush.color;
    NSNumber *strokeWidth = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"strokeWidth"];
    pen.lpWidth = [strokeWidth isEqual:[NSNull null]] ? 0 : strokeWidth.floatValue;
    drawData.brush = bush;
    drawData.pen = pen;
    drawLine.drawData = drawData;
    
    drawLine.nickname = drawBase.nickname;
    
    return drawLine;
}

- (NSMutableDictionary *)serializedData
{
//    if (_serializedData == nil)
//    {
    if (CGPointEqualToPoint(self.drawData.start, self.drawData.end)) {
        return nil;
    }
        NSMutableDictionary *dictionary = [super serializedData];
        [dictionary setObject:@"shapeSaveEvent" forKey:@"eventType"];
        [dictionary setObject:@"AddShapeAction" forKey:@"actionName"];
        [dictionary setObject:[self getDrawID] forKey:@"shapeId"];
        
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        [data setObject:@"Line" forKey:@"className"];
        
        NSMutableDictionary *innerData = [NSMutableDictionary dictionary];
        [innerData setObject:@(self.drawData.start.x) forKey:@"x1"];
        [innerData setObject:@(self.drawData.start.y) forKey:@"y1"];
        [innerData setObject:@(self.drawData.end.x) forKey:@"x2"];
        [innerData setObject:@(self.drawData.end.y) forKey:@"y2"];
        [innerData setObject:@(self.drawData.pen.lpWidth) forKey:@"strokeWidth"];
        [innerData setObject:[DrawBase colorStringFromRGBAType:self.drawData.brush.color] forKey:@"color"];
        [innerData setObject:@"round" forKey:@"capStyle"];
        [innerData setObject:[NSNull null] forKey:@"dash"];
        
        NSMutableArray *endCapShapes = [@[] mutableCopy];
        [endCapShapes addObject:[NSNull null]];
        [endCapShapes addObject:(self.drawData.brush.lbStyle == 0) ? @"arrow" : [NSNull null]];
        
        [innerData setObject:endCapShapes forKey:@"endCapShapes"];
        [data setObject:innerData forKey:@"data"];
        [data setObject:[self getDrawID] forKey:@"id"];
        
        [dictionary setObject:data forKey:@"data"];
        NSString *whiteboardID = [YSRoomUtil getwhiteboardIDFromFileId:self.fileId];
        [dictionary setObject:whiteboardID forKey:@"whiteboardID"];
        [dictionary setObject:[YSRoomInterface instance].localUser.nickName ? : @" " forKey:@"nickname"];
        
        _serializedData = dictionary;
    return _serializedData;
}
@end
