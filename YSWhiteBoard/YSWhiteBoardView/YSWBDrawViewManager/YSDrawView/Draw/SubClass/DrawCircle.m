//
//  DrawCircle.m
//  WhiteBoard
//
//  Created by macmini on 14/11/10.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "DrawCircle.h"
#import <YSRoomSDK/YSRoomSDK.h>
@interface DrawCircle ()
{
    NSMutableDictionary *_serializedData;
}
@end

@implementation DrawCircle
-(void) onDraw:(CGContextRef)context
{
    CGPoint start = CGPointMake(self.drawData.start.x/self.sacle.x, self.drawData.start.y/self.sacle.y);
    CGPoint end = CGPointMake(self.drawData.end.x/self.sacle.x, self.drawData.end.y/self.sacle.y);
    if (CGPointEqualToPoint(start, end)) {
        return;
    }
    const CGFloat  dashArray1[] = {3, 2};//虚线
    const CGFloat  dashArray2[] = {0, 0};//实线
    CGContextSetLineWidth(context, self.drawData.pen.lpWidth * self.iFontScale);
    CGContextSetLineDash(context, 0, dashArray2, 0);

    CGContextSetStrokeColorWithColor(context, BMRGBColor(self.drawData.brush.color.r*255,self.drawData.brush.color.g*255,self.drawData.brush.color.b*255,self.drawData.brush.color.a*255).CGColor);
    CGContextSetFillColorWithColor(context, BMRGBColor(self.drawData.brush.color.r*255,self.drawData.brush.color.g*255,self.drawData.brush.color.b*255,self.drawData.brush.color.a*255).CGColor);
    CGRect rect = CGRectMake(start.x <= end.x ? start.x : end.x, start.y <= end.y ? start.y : end.y, fabs(end.x - start.x), fabs(end.y - start.y));
    CGContextAddEllipseInRect(context, rect);
    if(self.drawData.brush.lbStyle == BS_SOLID) {
        CGRect fillRect = CGRectMake(start.x - self.drawData.pen.lpWidth * self.iFontScale <= end.x ? start.x - self.drawData.pen.lpWidth * self.iFontScale : end.x, start.y - self.drawData.pen.lpWidth * self.iFontScale <= end.y ? start.y - self.drawData.pen.lpWidth * self.iFontScale : end.y, fabs(end.x - start.x + self.drawData.pen.lpWidth * self.iFontScale), fabs(end.y - start.y + self.drawData.pen.lpWidth * self.iFontScale));
        CGContextFillEllipseInRect(context, fillRect);
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
    DrawCircle* circle = [[DrawCircle alloc] init];
    circle.draw_select = self.draw_select;
    circle.version = self.version;
    circle.type = self.type;
    circle.fileId = self.fileId;
    circle.pageid = self.pageid;
    circle.sacle =self.sacle;
    
    circle.drawData = self.drawData;
    return circle;
}

+ (DrawCircle *)deserializeData:(NSDictionary *)data
{
    DrawBase * drawBase = [super deserializeData:data];
    
    NSDictionary *sharpData = data;
    DRAWDATA drawData;
    drawData.version = 1;
    drawBase.draw_id =[sharpData objectForKey:@"shapeId"];
    drawData.type = Ellipse;
    
    NSNumber *x = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"x"];
    NSNumber *y = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"y"];
    NSNumber *width = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"width"];
    NSNumber *height = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"height"];
    NSNumber *strokeWidth = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"strokeWidth"];
    
    x       = [x isEqual:[NSNull null]] ? @(0) : x;
    y       = [y isEqual:[NSNull null]] ? @(0) : y;
    width   = [width isEqual:[NSNull null]] ? @(0) : width;
    height  = [height isEqual:[NSNull null]] ? @(0) : height;
    
    drawData.start =CGPointMake(x.floatValue, y.floatValue);
//    float finalWidth = 0;
//    float finalHeight = 0;
    float finalStrokeWidth = [strokeWidth isEqual:[NSNull null]] ? 5 : strokeWidth.floatValue;
//    if ([width isEqual:[NSNull null]] || width.floatValue == 0) {
//        finalWidth = finalStrokeWidth;
//    } else {
//        finalWidth = fabs(width.floatValue) >= finalStrokeWidth ? width.floatValue : finalStrokeWidth;
//    }
//
//    if ([height isEqual:[NSNull null]] || height.floatValue == 0) {
//        finalHeight = finalStrokeWidth;
//    } else {
//        finalHeight = fabs(height.floatValue) >= finalStrokeWidth ? height.floatValue : finalStrokeWidth;
//    }
    
    drawData.end = CGPointMake(x.floatValue + width.floatValue, y.floatValue + height.floatValue);
    if (drawData.start.x <= drawData.end.x) {
        drawData.start = CGPointMake(drawData.start.x, drawData.start.y);
        drawData.end = CGPointMake(drawData.end.x, drawData.end.y);
    } else {
        float x = drawData.start.x;
        drawData.start = CGPointMake(drawData.end.x, drawData.start.y);
        drawData.end = CGPointMake(x, drawData.end.y);
    }
    
    if (drawData.start.y <= drawData.end.y) {
        drawData.start = CGPointMake(drawData.start.x, drawData.start.y);
        drawData.end = CGPointMake(drawData.end.x, drawData.end.y);
    } else {
        float y = drawData.start.y;
        drawData.start = CGPointMake(drawData.start.x, drawData.end.y);
        drawData.end = CGPointMake(drawData.end.x, y);
    }
    
    
    ScreenScale scale = {0,0};
    DrawCircle *drawCircle = [[DrawCircle alloc]initWithVersion:drawBase.version eventType:drawBase.type fileID:drawBase.fileId pageID:drawBase.pageid ScreenScale:scale drawId:drawBase.draw_id];
    drawCircle.nickname = drawBase.nickname;
    NSString *colorString = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"strokeColor"];

    Brush bush;
    bush.color = [DrawBase rgbaColorFromColorString:colorString];
    NSString *fillType = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"fillColor"];
    bush.lbStyle = ![fillType isEqualToString:@"transparent"]?BS_SOLID:BS_NULL;
    Pen pen;
    pen.color = bush.color;
    
    pen.lpWidth = finalStrokeWidth;
    drawData.brush = bush;
    drawData.pen = pen;
    drawCircle.drawData = drawData;
    drawCircle.nickname = drawBase.nickname;
    return drawCircle;
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
        [data setObject:@"Ellipse" forKey:@"className"];
        
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
        NSString *whiteboardID = [YSRoomUtil getwhiteboardIDFromFileId:self.fileId];
        [dictionary setObject:whiteboardID forKey:@"whiteboardID"];
        [dictionary setObject:[YSRoomInterface instance].localUser.nickName ? : @" " forKey:@"nickname"];
        
        _serializedData = dictionary;
    
    return _serializedData;}

@end
