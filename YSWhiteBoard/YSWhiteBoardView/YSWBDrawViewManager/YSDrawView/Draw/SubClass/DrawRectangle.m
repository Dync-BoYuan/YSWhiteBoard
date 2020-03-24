//
//  DrawRectangle.m
//  WhiteBoard
//
//  Created by macmini on 14/11/10.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "DrawRectangle.h"
#import <YSRoomSDK/YSRoomSDK.h>
//#import "WhiteBoard.h"
@interface DrawRectangle ()
{
    NSMutableDictionary *_serializedData;
}
@end
@implementation DrawRectangle
-(void) onDraw:(CGContextRef)context
{
    CGPoint start = CGPointMake(self.drawData.start.x/self.sacle.x, self.drawData.start.y/self.sacle.y);
    CGPoint end = CGPointMake(self.drawData.end.x/self.sacle.x, self.drawData.end.y/self.sacle.y);
    
    const CGFloat  dashArray1[] = {3, 2};//虚线
    const CGFloat  dashArray2[] = {0, 0};//实线
    CGContextSetLineWidth(context, self.drawData.pen.lpWidth * self.iFontScale);
    CGContextSetLineDash(context, 0, dashArray2, 0);
    CGContextSetStrokeColorWithColor(context, BMRGBColor(self.drawData.brush.color.r*255,self.drawData.brush.color.g*255,self.drawData.brush.color.b*255,self.drawData.brush.color.a*255).CGColor);
    CGContextSetFillColorWithColor(context, BMRGBColor(self.drawData.brush.color.r*255,self.drawData.brush.color.g*255,self.drawData.brush.color.b*255,self.drawData.brush.color.a*255).CGColor);
    
    CGRect rect = CGRectMake(start.x, start.y, end.x - start.x, end.y - start.y);
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    CGContextAddRect(context,rect);
    
    if(self.drawData.brush.lbStyle == BS_SOLID) {
        CGContextFillRect(context, rect);
    }
    CGContextStrokePath(context);
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
    CGRect viewRect = CGRectMake(self.drawData.start.x, self.drawData.start.y, self.drawData.end.x - self.drawData.start.x, self.drawData.end.y - self.drawData.start.y);
    return CGRectIntersectsRect(rect,viewRect);
}
-(DrawBase*)clone
{
    DrawRectangle* rectangle = [[DrawRectangle alloc] init];
    rectangle.draw_select = self.draw_select;
    rectangle.version = self.version;
    rectangle.type = self.type;
    rectangle.fileId = self.fileId;
    rectangle.pageid = self.pageid;
    rectangle.sacle =self.sacle;
    
    rectangle.drawData = self.drawData;
    
    return rectangle;
}

+ (DrawRectangle *)deserializeData:(NSDictionary *)data
{
    DrawBase * drawBase = [super deserializeData:data];
    
    NSDictionary *sharpData = data;
    DRAWDATA drawData;
    drawData.version = 1;
    drawBase.draw_id =[sharpData objectForKey:@"shapeId"];
    drawData.type = Rectangle;
    NSNumber *x = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"x"];
    NSNumber *y = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"y"];
    NSNumber *width = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"width"];
    NSNumber *height = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"height"];
    
    x       = [x isEqual:[NSNull null]] ? @(0) : x;
    y       = [y isEqual:[NSNull null]] ? @(0) : y;
    width   = [width isEqual:[NSNull null]] ? @(0) : width;
    height  = [height isEqual:[NSNull null]] ? @(0) : height;
    
    drawData.start =CGPointMake(x.floatValue, y.floatValue);
    drawData.end = CGPointMake(x.floatValue + width.floatValue, y.floatValue + height.floatValue);
    
    ScreenScale scale = {0,0};
    DrawRectangle *drawRectangle = [[DrawRectangle alloc]initWithVersion:drawBase.version eventType:drawBase.type fileID:drawBase.fileId pageID:drawBase.pageid ScreenScale:scale drawId:drawBase.draw_id];
    drawRectangle.nickname = drawBase.nickname;
    NSString *colorString = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"strokeColor"];    Brush bush;
    bush.color = [DrawBase rgbaColorFromColorString:colorString];
    NSString *fillType = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"fillColor"];
    bush.lbStyle = ![fillType isEqualToString:@"transparent"]?BS_SOLID:BS_NULL;
    Pen pen;
    pen.color = bush.color;
    NSNumber *strokeWidth = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"strokeWidth"];
    pen.lpWidth = [strokeWidth isEqual:[NSNull null]] ? 0 : strokeWidth.floatValue;
    drawData.brush = bush;
    drawData.pen = pen;
    drawRectangle.drawData = drawData;
    
    return drawRectangle;
}

- (NSMutableDictionary *)serializedData
{
    //    if (_serializedData == nil)
    //    {
    NSMutableDictionary *dictionary = [super serializedData];
    [dictionary setObject:@"shapeSaveEvent" forKey:@"eventType"];
    [dictionary setObject:@"AddShapeAction" forKey:@"actionName"];
    [dictionary setObject:[self getDrawID] forKey:@"shapeId"];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:@"Rectangle" forKey:@"className"];
    
    NSMutableDictionary *innerData = [NSMutableDictionary dictionary];
    [innerData setObject:@(self.drawData.start.x) forKey:@"x"];
    [innerData setObject:@(self.drawData.start.y) forKey:@"y"];
    [innerData setObject:@(self.drawData.end.x - self.drawData.start.x) forKey:@"width"];
    [innerData setObject:@(self.drawData.end.y - self.drawData.start.y) forKey:@"height"];
    [innerData setObject:@(self.drawData.pen.lpWidth) forKey:@"strokeWidth"];
    [innerData setObject:[DrawBase colorStringFromRGBAType:self.drawData.brush.color] forKey:@"strokeColor"];
    [innerData setObject:(self.drawData.brush.lbStyle == 0) ? [DrawBase colorStringFromRGBAType:self.drawData.brush.color] : @"transparent" forKey:@"fillColor"];
    
    [data setObject:innerData forKey:@"data"];
    [data setObject:[self getDrawID] forKey:@"id"];
    
    [dictionary setObject:data forKey:@"data"];
    [dictionary setObject:@"default" forKey:@"whiteboardID"];
    [dictionary setObject:[YSRoomInterface instance].localUser.nickName ? : @" " forKey:@"nickname"];
    
    _serializedData = dictionary;
    return _serializedData;
}


@end
