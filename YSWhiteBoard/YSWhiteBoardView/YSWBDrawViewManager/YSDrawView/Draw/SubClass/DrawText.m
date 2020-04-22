//
//  DrawText.m
//  WhiteBoard
//
//  Created by macmini on 14/11/12.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "DrawText.h"
#import "DrawView.h"
#import <YSRoomSDK/YSRoomSDK.h>
//#import "YSWhiteBoardConfiguration.h"

@interface DrawText()<UITextViewDelegate>
{
    NSMutableDictionary *_serializedData;
}
@end

@implementation DrawText

-(id)init
{
    self = [super init];
    if (self != nil)
    {
        
    }
    return self;
}
//TODO: 开始画图
-(void)onDraw:(CGContextRef)context
{
    //IOS6 需要适配
    //    [_text drawin]
    if([[[UIDevice currentDevice] systemVersion] floatValue]>=7.0)
    {
        //        NSLog(@"$$$$$$$$$$ %@ ------ %@", self.forceWidth, self.forcedHeight);
        //float lpWidth = (self.drawData.pen.lpWidth <= 15) ? 15 :self.drawData.pen.lpWidth;
        float lpWidth = self.drawData.pen.lpWidth;
        int tFontLdWidth = lpWidth * self.iFontScale;
        NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:tFontLdWidth], NSFontAttributeName,[UIColor colorWithRed:self.drawData.brush.color.r green:self.drawData.brush.color.g blue:self.drawData.brush.color.b alpha:self.drawData.brush.color.a], NSForegroundColorAttributeName, nil];
        
        CGRect rect;
        if (![self.forceWidth isEqual:[NSNull null]] && self.forceWidth.floatValue > 0) {
            if (![self.forcedHeight isEqual:[NSNull null]] && self.forcedHeight.floatValue > 0) {
                rect = [_text boundingRectWithSize:CGSizeMake(self.forceWidth.floatValue * self.iFontScale, self.forcedHeight.floatValue * self.iFontScale) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dic context:nil];
            } else {
                rect = [_text boundingRectWithSize:CGSizeMake(self.forceWidth.floatValue * self.iFontScale, MAXFLOAT) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dic context:nil];
            }
        } else {
            if (![self.forcedHeight isEqual:[NSNull null]] && self.forcedHeight.floatValue > 0) {
                rect = [_text boundingRectWithSize:CGSizeMake(MAXFLOAT, self.forcedHeight.floatValue * self.iFontScale) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dic context:nil];
            } else {
                rect = [_text boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dic context:nil];
            }
        }
        
        [_text drawInRect:CGRectMake(_textFrame.origin.x/self.sacle.x, _textFrame.origin.y/self.sacle.y, rect.size.width, rect.size.height) withAttributes:dic];
    }
    else
    {
//        CGContextSetStrokeColorWithColor(context, RGBACOLOR(self.drawData.brush.color.r*255,self.drawData.brush.color.g*255,self.drawData.brush.color.b*255,self.drawData.brush.color.a*255).CGColor);
//        CGContextSetFillColorWithColor(context, RGBACOLOR(self.drawData.brush.color.r*255,self.drawData.brush.color.g*255,self.drawData.brush.color.b*255,self.drawData.brush.color.a*255).CGColor);
//        [_text drawInRect:CGRectMake(_textFrame.origin.x/self.sacleX+5, _textFrame.origin.y/self.sacleY+7, _textFrame.size.width/self.sacleX, _textFrame.size.height/self.sacleY) withFont:[UIFont systemFontOfSize:self.drawData.pen.lpWidth>5?self.drawData.pen.lpWidth:18.0]];
    }
    if(self.draw_select)//绘制选中状态
    {
        CGContextSetLineWidth(context, 0.2);
        CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1);//黑
        const CGFloat  dashArray1[] = {3, 2};
        CGContextSetLineDash(context, 0, dashArray1, 2);
        CGContextAddRect(context,CGRectMake(_textFrame.origin.x/self.sacleX+5, _textFrame.origin.y/self.sacleY+7, _textFrame.size.width/self.sacleX, _textFrame.size.height/self.sacleY));
        CGContextStrokePath(context);
        
    }
    
}
-(bool)select:(CGRect)rect
{
    return CGRectIntersectsRect(rect,_textFrame);
}
-(DrawBase*)clone
{
    DrawText* text = [[DrawText alloc] init];
    text.draw_select = self.draw_select;
    text.version = self.version;
    text.type = self.type;
    text.fileId = self.fileId;
    text.pageid = self.pageid;
    text.sacle =self.sacle;
    text.sacleX = self.sacleX;
    text.sacleY = self.sacleY;
    
    text.drawData = self.drawData;
    text.delegate = self.delegate;
    return text;
}
-(void)touchesBegan:(CGPoint)point
{
    [super touchesBegan:point];
    self.pointString = NSStringFromCGPoint(point);
    DrawView* drawView = self.delegate;
    if (!drawView.textView||[drawView.textView.text isEqualToString:@""] )
    {
        if([drawView.textView.text isEqualToString:@""])
        {
            [drawView.textView removeFromSuperview];
            drawView.textView = nil;
            return;
        }
        
        if (!drawView.textView) {
            drawView.textView = [[UITextView alloc]initWithFrame:CGRectMake(point.x - 8, point.y - 8, [UIFont systemFontOfSize:self.drawData.pen.lpWidth  * self.iFontScale].lineHeight + 16, [UIFont systemFontOfSize:self.drawData.pen.lpWidth  * self.iFontScale].lineHeight + 16)];
            drawView.textView.tag = YSWHITEBOARD_TEXTVIEWTAG;
        }
        drawView.textView.delegate = self;

        drawView.textView.textColor = (self.drawData.brush.color.r==0&&self.drawData.brush.color.g==0&&self.drawData.brush.color.b==0)?[UIColor blackColor]:[UIColor colorWithRed:self.drawData.brush.color.r green:self.drawData.brush.color.g blue:self.drawData.brush.color.b alpha:1.0];//设置textview里面的字体颜色
        drawView.textView.returnKeyType = UIReturnKeyDefault;//返回键的类型
        
        drawView.textView.keyboardType = UIKeyboardTypeDefault;//键盘类型
        drawView.textView.layer.borderWidth=0.5;
        drawView.textView.scrollEnabled = NO;//是否可以拖动
        
        drawView.textView.font = [UIFont systemFontOfSize:(int)(self.drawData.pen.lpWidth) * self.iFontScale];//设置字体名字和字体大小
        drawView.textView.autoresizingMask = UIViewAutoresizingFlexibleHeight;//自适应高度
        drawView.textView.backgroundColor = [UIColor clearColor];
        [drawView addSubview:drawView.textView];
        [drawView.textView becomeFirstResponder];
    }
    else
    {
        [drawView.textView resignFirstResponder];
        [drawView.textView removeFromSuperview];
    }
}

-(void)touchesMoved:(CGPoint)point
{
    [super touchesMoved:point];
}

-(void)touchesEnded:(CGPoint)point
{
    [super touchesMoved:point];
    DrawView* drawView = self.delegate;
    if(!drawView.textView )
    {
        return;
    } else {
        if([drawView.textView.text isEqualToString:@""]) {
            return;
            
        } else {
            self.text = drawView.textView.text;
            CGPoint center = drawView.textView.center;
            center.y = drawView.textCenter.y;
            drawView.textView.center = center;
            self.textFrame = CGRectMake(drawView.textView.frame.origin.x, drawView.textView.frame.origin.y, drawView.textView.frame.size.width, drawView.textView.frame.size.height);
            drawView.textView = nil;
        }
    }
}

//-(void)setOffset:(CGPoint)offset
//{
//    [super setOffset:offset];
//    _textFrame.origin= CGPointMake(_textFrame.origin.x+offset.x*self.sacle.x, _textFrame.origin.y+offset.y*self.sacle.y);
//}

- (void)textViewDidChange:(UITextView *)textView
{
    DrawView* drawView = self.delegate;
//    drawView.textView.font = [UIFont systemFontOfSize:self.drawData.pen.lpWidth * self.iFontScale];
    if([[[UIDevice currentDevice] systemVersion] floatValue]>=7.0)
    {
        float maxWidth = drawView.frame.size.width - drawView.textView.frame.origin.x - 16;
        float maxHeight = drawView.frame.size.height - drawView.textView.frame.origin.y - 16;
        NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:(int)(self.drawData.pen.lpWidth) * self.iFontScale], NSFontAttributeName,[UIColor colorWithRed:self.drawData.brush.color.r green:self.drawData.brush.color.g blue:self.drawData.brush.color.b alpha:self.drawData.brush.color.a], NSForegroundColorAttributeName, nil];
        CGRect rect = [drawView.textView.text boundingRectWithSize:CGSizeMake(maxWidth, maxHeight) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dic context:nil];
        drawView.textView.frame = CGRectMake(drawView.textView.frame.origin.x, drawView.textView.frame.origin.y, rect.size.width + 16, rect.size.height + 16);
        
        self.forceWidth = @(rect.size.width + 16);
        self.forcedHeight = @(rect.size.height + 16);
    }
}

+ (DrawText *)deserializeData:(NSDictionary *)data
{
    DrawBase * drawBase = [super deserializeData:data];
    
    NSDictionary *sharpData = data;
    DRAWDATA drawData;
    drawData.version = 1;
    drawBase.draw_id = [sharpData objectForKey:@"shapeId"];
    drawData.type = Text;
    
    NSNumber *x = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"x"];
    NSNumber *y = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"y"];
    
    x       = [x isEqual:[NSNull null]] ? @(0) : x;
    y       = [y isEqual:[NSNull null]] ? @(0) : y;
    
    drawData.start =CGPointMake(x.floatValue, y.floatValue);
    drawData.end = CGPointMake(x.floatValue, y.floatValue);
    
    ScreenScale scale = {0,0};
    DrawText *drawText = [[DrawText alloc]initWithVersion:drawBase.version eventType:drawBase.type fileID:drawBase.fileId pageID:drawBase.pageid ScreenScale:scale drawId:drawBase.draw_id];
    drawText.nickname = drawBase.nickname;
    drawText.forceWidth =[[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"forcedWidth"];
    drawText.forcedHeight =[[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"forcedHeight"];
    
    drawText.text = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"text"];
    
    drawText.fontString = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"font"];
    NSArray *fontComponent = [drawText.fontString componentsSeparatedByString:@" "];
    NSString *fontSize = [fontComponent objectAtIndex:2];
    fontSize = [fontSize substringToIndex:fontSize.length - 2];
    NSString *fontName = [fontComponent objectAtIndex:3];
    if ([fontName isEqualToString:@"微软雅黑"]) {
        
    }
    if ([fontName isEqualToString:@"宋体"]) {
        
    }
    if ([fontName isEqualToString:@"Arial"]) {
        
    }
    
    CGSize size = [drawText.text boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:fontSize.integerValue]} context:nil].size;
    drawText.textFrame = CGRectMake(drawData.start.x, drawData.start.y, drawData.start.x + size.width, drawData.start.y + size.height);
    
    
    NSString *colorString = [[[sharpData objectForKey:@"data"] objectForKey:@"data"] objectForKey:@"color"];
    Brush bush;
    bush.color = [DrawBase rgbaColorFromColorString:colorString];
    Pen pen;
    pen.lpWidth = fontSize.floatValue;
    pen.color = bush.color;
    drawData.brush = bush;
    drawData.pen = pen;
    drawText.drawData = drawData;
    drawText.nickname = drawBase.nickname;
    return drawText;
}

- (NSMutableDictionary *)serializedData
{
    NSMutableDictionary *dictionary = [super serializedData];
    [dictionary setObject:@"shapeSaveEvent" forKey:@"eventType"];
    [dictionary setObject:@"AddShapeAction" forKey:@"actionName"];
    [dictionary setObject:[self getDrawID] forKey:@"shapeId"];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:@"Text" forKey:@"className"];
    
    NSMutableDictionary *innerData = [NSMutableDictionary dictionary];
    [innerData setObject:@(self.drawData.start.x) forKey:@"x"];
    [innerData setObject:@(self.drawData.start.y) forKey:@"y"];
    [innerData setObject:((DrawView *)self.delegate).textView.text forKey:@"text"];
    [innerData setObject:[DrawBase colorStringFromRGBAType:self.drawData.brush.color] forKey:@"color"];
    if (!self.fontString || self.fontString.length == 0) {
        self.fontString = [NSString stringWithFormat:@"normal normal %dpx 微软雅黑", (int)(self.drawData.pen.lpWidth)];
    }
    [innerData setObject:self.fontString forKey:@"font"];
    [innerData setObject:@((self.forceWidth.floatValue) / self.iFontScale) forKey:@"forcedWidth"];
    [innerData setObject:@(0) forKey:@"forcedHeight"];
    [innerData setObject:@(1) forKey:@"v"];
    
    [data setObject:innerData forKey:@"data"];
    [data setObject:[self getDrawID] forKey:@"id"];
    
    [dictionary setObject:data forKey:@"data"];
    if ([self.fileId isEqualToString:@"0"])
    {
        [dictionary setObject:@"default" forKey:@"whiteboardID"];
    }
    else
    {
        NSString *whiteboardID = [NSString stringWithFormat:@"%@%@", YSWhiteBoardId_Header, self.fileId];
        [dictionary setObject:whiteboardID forKey:@"whiteboardID"];
    }
    [dictionary setObject:[YSRoomInterface instance].localUser.nickName ? : @" " forKey:@"nickname"];
    
    _serializedData = dictionary;
    
    return _serializedData;
}

-(bool)isHorizontalScreen
{
    UIDeviceOrientation orientaiton = [[UIDevice currentDevice] orientation];
    
    return orientaiton == UIDeviceOrientationLandscapeLeft||orientaiton == UIDeviceOrientationLandscapeLeft;
}
@end
