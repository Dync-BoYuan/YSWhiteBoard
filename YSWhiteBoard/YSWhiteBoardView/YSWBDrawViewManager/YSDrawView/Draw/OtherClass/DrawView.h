//
//  DrawView.h
//  WhiteBoard
//
//  Created by macmini on 14/11/6.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DrawBase.h"
//#import "YSWhiteBoardController.h"
#ifdef __cplusplus
#include <map>
#endif

@protocol UITouchDeleagte <NSObject>
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
@end

@protocol DrawViewDelegate <NSObject>

- (void)addSharpWithFileID:(NSString *)fileid shapeID:(NSString *)shapeID shapeData:(NSData *)shapeData;
@end

@interface DrawView : UIView
@property (nonatomic ) YSWorkMode mode; //控制模式  viewer controller
@property(nonatomic, copy) NSString *fileid;
@property (nonatomic) int pageId;
@property (nonatomic ,strong)DrawBase* draw;
@property (nonatomic)DRAWDATA drawData;
@property(nonatomic,strong) UITextView* textView;
@property(nonatomic) CGPoint textCenter;
@property (nonatomic )CGColorRef color;
@property (nonatomic,assign) RGBAType initializeRgb;
@property (nonatomic, assign) BOOL shouldShowdraweraName;
@property (nonatomic, weak) id <DrawViewDelegate>delegate;

/**
 *  字体缩放比例
 */
@property (nonatomic ) CGFloat iFontScale;

- (void)clearDrawVideoMark;
- (void)clearDraw;

-(void)selectDraw:(int)type;
-(id)initWithFrame:(CGRect)frame;

-(void)refreshcreenScale;
-(void)removeDrawData:(NSString*)sharpid;
-(void)addDrawSharpData:(NSDictionary*)sharpData isUpdate:(BOOL)isUpdate;

-(void)clearDrawMap:(NSString *)fileId;

- (void)switchFileID:(NSString *)fileID
      andCurrentPage:(int)currentPage
   updateImmediately:(BOOL)update;

//清空绘制
- (void)clearDrawMapByClearID:(NSString *)clearID;

//恢复清空
- (void)recoveryDrawMapByClearID:(NSString *)clearID;

//撤回
- (void)undoDrawMap;

//重做
- (BOOL)redoDrawMapByClearID:(NSString *)redoID;

//下课后清空数据
- (void)clearDataAfterClass;

//清空某一页数据
- (void)clearOnePageWithFileID:(NSString *)fileID pageNum:(int)pageNum;

//清理某一笔
- (void)removeOneDraw:(NSString *)drawID;

//翻页直接清理落笔名字
- (void)clearDrawersNameAfterShowPage;
@end
