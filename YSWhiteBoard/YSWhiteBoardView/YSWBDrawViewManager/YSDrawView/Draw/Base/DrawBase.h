//
//  DrawBase.h
//  WhiteBoard
//
//  Created by macmini on 14/11/6.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HSV.h"
//#import "YSWhiteBoardController.h"


//#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)/255.0f]

#define GetRGBAValue(r,g,b,a,color) \
const CGFloat *components = CGColorGetComponents(color.CGColor);\
r = components[0]*255.0f;\
g = components[1]*255.0f;\
b = components[2]*255.0f;\
a = components[3]*255.0f;
//CHECKANDGET(arr, 1, NSNumber, eventType);
#define CHECKANDGET(a, idx, type, dest) \
type *dest = [a objectAtIndex:idx];\
if(![dest isKindOfClass:[type class]])\
{\
NSLog(@"Got bad message %d", __LINE__);\
NSLog(@"%@, Need %@, Got %@", @#idx, [type class], [dest class]);\
return;\
}
typedef enum
{
    BS_SOLID = 0,  //实心
    BS_NULL        //空心
} BrushType;

typedef struct {float r, g, b,a;} RGBAType;

typedef struct {
    float lpWidth;    //线宽
    RGBAType color;
} Pen;

typedef struct {
    BrushType lbStyle;
    RGBAType color;
} Brush;

typedef enum
{
    markerPen = 0,        //记号笔
    arrowLine = 1,        //箭头
    line      = 2,      //直线
    Rectangle = 3,      //矩形
    Ellipse   = 4,      //椭圆
    Text      = 5,      //文字
    Eraser    = 6,      //橡皮擦
} DrawType;

typedef struct {
    int      version;
    DrawType     type;
    CGPoint  start;
    CGPoint  end;
    Pen      pen;
    Brush    brush;
} DRAWDATA;
typedef struct {
    double  x;
    double  y;
} ScreenScale;


@interface DrawBase : NSObject

@property (nonatomic , strong) NSString *draw_id;
@property (nonatomic ) DRAWDATA drawData;
@property(nonatomic,weak) id delegate;
@property (nonatomic ) bool draw_select;

@property (nonatomic ) int version;
@property (nonatomic ) YSEvent type;
@property (nonatomic, copy) NSString *fileId;
@property (nonatomic ) int pageid;
@property (nonatomic ) ScreenScale sacle;
@property (nonatomic ) double sacleX;
@property (nonatomic ) double sacleY;
@property (nonatomic, strong) NSNumber *forcedHeight;
@property (nonatomic, strong) NSNumber *forceWidth;
@property (nonatomic, strong) NSString *nickname;
/**
 *  字体缩放比例
 */
@property (nonatomic ) CGFloat iFontScale;
-(NSString*)getDrawID;
-(void) onDraw:(CGContextRef)context;
-(bool)select:(CGRect)rect;
-(DrawBase*)clone;
-(void)touchesBegan:(CGPoint)point;
-(void)touchesMoved:(CGPoint)point;
-(void)touchesEnded:(CGPoint)point;
-(void)setOffset:(CGPoint)offset;

+ (DrawBase *)deserializeData:(NSDictionary *)data;
- (NSMutableDictionary *)serializedData;

+(CGColorRef) getColorFromRed:(int)red Green:(int)green Blue:(int)blue Alpha:(int)alpha;
-(id)initWithVersion:(int)version eventType:(YSEvent)type fileID:(NSString *)fileId pageID:(int)pageid ScreenScale:(ScreenScale)sacle drawId:(NSString*)drawId;

- (UInt32)rgbaHex:(RGBAType) color ;
+ (RGBAType)rgbaColorWithRGBAHex:(UInt32)hex;
+ (RGBAType)rgbaColorFromColorString:(NSString *)colorString;
+ (NSString *)colorStringFromRGBAType:(RGBAType)rgba;

@end
