//
//  DrawBase.m
//  WhiteBoard
//
//  Created by macmini on 14/11/6.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "DrawBase.h"
#import <Foundation/Foundation.h>
#import <BMKit/BMKit.h>

@interface DrawBase ()
{
    NSMutableDictionary *_serializedData;
}

@end

@implementation DrawBase
-(id)initWithVersion:(int)version eventType:(YSEvent)type fileID:(NSString *)fileId pageID:(int)pageid ScreenScale:(ScreenScale)sacle drawId:(NSString*)drawId
{
    self = [super init];
    if (self != nil)
    {
        _draw_select = false;
        _version = version;
        _type = type;
        _fileId = fileId;
        _pageid = pageid;
        _sacle = sacle;
        _draw_id = drawId;
    }
    return self;
}
-(NSString*)getDrawID
{
    if (_draw_id == nil) {
        _draw_id = [NSString stringWithFormat:@"%p-%f",self,[[NSDate date] timeIntervalSince1970]];
    }
    return _draw_id;
}
- (void)onDraw:(CGContextRef)context
{
    
}
- (bool)select:(CGRect)rect
{
    return false;
}
- (DrawBase*)clone
{
    return nil;
}
- (void)setOffset:(CGPoint)offset
{
    _drawData.start = CGPointMake(_drawData.start.x+offset.x*self.sacle.x, _drawData.start.y+offset.y*self.sacle.y);
    _drawData.end = CGPointMake(_drawData.end.x+offset.x*self.sacle.x, _drawData.end.y+offset.y*self.sacle.y);
}
- (void)touchesBegan:(CGPoint)point
{
    _drawData.start = _drawData.end = CGPointMake(point.x*self.sacle.x, point.y*self.sacle.y);
    
    if ([YSRoomInterface instance].localUser.role == YSUserType_Teacher)
    {
        [[YSWhiteBoardManager shareInstance] setTheCurrentDocumentFileID:self.fileId];
    }
}

- (void)touchesMoved:(CGPoint)point
{
    _drawData.end = CGPointMake(point.x*self.sacle.x, point.y*self.sacle.y);
}

- (void)touchesEnded:(CGPoint)point
{
    _drawData.end = CGPointMake(point.x*self.sacle.x, point.y*self.sacle.y);
}

+ (DrawBase *)deserializeData:(NSDictionary *)data
{
    DrawBase * drawBase = [[DrawBase alloc]init];
    drawBase.version = 0;
    
    YSEvent eventType = 0;
    NSString *eventTypeString = [data objectForKey:@"eventType"];
    if ([eventTypeString isEqualToString:@"shapeSaveEvent"]) {
        eventType = YSEventShapeAdd;
    }
    drawBase.type = eventType;
    
    drawBase.nickname = [data objectForKey:@"nickname"];
    
    return drawBase;
}

- (NSMutableDictionary *)serializedData
{
    if(_serializedData == nil){
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        switch (_type) {
            case YSEventShapeAdd:
            {
                [dictionary setObject:@"shapeSaveEvent" forKey:@"eventType"];
                break;
            }
            case YSEventShapeClean:
            {
                [dictionary setObject:@"clearEvent" forKey:@"eventType"];
                break;
            }
            default:
                break;
        }
        
        
        _serializedData = dictionary;
    }
    
    return _serializedData;
}

//+(CGColorRef) getColorFromRed:(int)red Green:(int)green Blue:(int)blue Alpha:(int)alpha
//{
//    CGFloat r = (CGFloat) red/255.0;
//    CGFloat g = (CGFloat) green/255.0;
//    CGFloat b = (CGFloat) blue/255.0;
//    CGFloat a = (CGFloat) alpha/255.0;
//    CGFloat components[4] = {r,g,b,a};
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    
//    CGColorRef color = CGColorCreate(colorSpace, components);
//    CGColorSpaceRelease(colorSpace);
//    
//    return color;
//}

- (UInt32)rgbaHex:(RGBAType) color {
    return (((int)roundf(color.r * 255)) << 24)
    | (((int)roundf(color.g * 255)) << 16)
    | (((int)roundf(color.b * 255)) << 8)
    | (((int)roundf(color.a * 255)));
}

+ (RGBAType)rgbaColorWithRGBAHex:(UInt32)hex
{
    int r = (hex >> 24) & 0xFF;
    int g = (hex >> 16) & 0xFF;
    int b = (hex >> 8) & 0xFF;
    int a = (hex) & 0xFF;
    
    RGBAType color = {r/255.0f,g/255.0f,b/255.0f,a/255.0f};
    return color;
}

+ (RGBAType)rgbaColorFromColorString:(NSString *)colorString
{
    if (![colorString bm_isNotEmpty]) {
        RGBAType rgba = {0,0,0,0};
        return rgba;
    }
    
    if ([colorString isEqualToString:@"#000"]) {
        RGBAType type = {0,0,0,0};
        return type;
    }
    
    if ([colorString hasPrefix:@"rgba"]) {
        //rgb表示法
        NSString *str = [colorString substringWithRange:NSMakeRange(5, colorString.length - 6)];
        NSArray *rgbaArray = [str componentsSeparatedByString:@","];
        if (rgbaArray.count == 3) {
            NSNumber *r = rgbaArray[0];
            NSNumber *g = rgbaArray[1];
            NSNumber *b = rgbaArray[2];
            RGBAType color = {r.intValue/255.0f,g.intValue/255.0f,b.intValue/255.0f,255/255.0f};
            return color;
        }
        if (rgbaArray.count == 4) {
            NSNumber *r = rgbaArray[0];
            NSNumber *g = rgbaArray[1];
            NSNumber *b = rgbaArray[2];
            NSNumber *a = rgbaArray[3];
            RGBAType color = {r.intValue/255.0f,g.intValue/255.0f,b.intValue/255.0f,a.floatValue};
            return color;
        }
        
    } else {
        //16进制表示法
        NSString *pureString = [colorString substringFromIndex:1];
        NSString *realColor;
        if (pureString.length  == 6) {
            realColor = [pureString stringByAppendingString:@"FF"];
        }
        const char *hexChar = [realColor cStringUsingEncoding:NSASCIIStringEncoding];
        int hexNumber;
        sscanf(hexChar, "%x", &hexNumber);
        return [self rgbaColorWithRGBAHex:hexNumber];
    }
    
    RGBAType color = {0,0,0,0};
    return color;
}

+ (NSString *)colorStringFromRGBAType:(RGBAType)rgba
{
    float r = rgba.r * 255.0f;
    float g = rgba.g * 255.0f;
    float b = rgba.b * 255.0f;
    float a = rgba.a;
    if (a != 1) {
        //rgba表示法
        return [NSString stringWithFormat:@"rgba(%d,%d,%d,%.1f)",(int)r, (int)g, (int)b, a];
    } else {
        //hex表示法
        NSMutableString *hex = [NSMutableString stringWithString:@"#"];
        if (ceil(r) > 15) {
            [hex appendFormat:@"%X",(unsigned)ceil(r)];
        } else {
            [hex appendFormat:@"0%X",(unsigned)ceil(r)];
        }
        if (ceil(g) > 15) {
            [hex appendFormat:@"%X",(unsigned)ceil(g)];
        } else {
            [hex appendFormat:@"0%X",(unsigned)ceil(g)];
        }
        if (ceil(b) > 15) {
            [hex appendFormat:@"%X",(unsigned)ceil(b)];
        } else {
            [hex appendFormat:@"0%X",(unsigned)ceil(b)];
        }
        return hex;
    }
}

@end
