//
//  DocShowView.h
//  WhiteBoard
//
//  Created by frank lin on 15-1-30.
//  Copyright (c) 2015年 itcast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LKPDFView.h"
//#import "YSWhiteBoardController.h"
#import "DocUnderView.h"
#import "YSDrawView.h"

#pragma mark -MRImgShowView

typedef void(^FinishBlock)(float ratio);

@protocol DocShowViewZoomScaleDelegate;

@interface DocShowView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, weak) id <DocShowViewZoomScaleDelegate> zoomDelegate;

@property (nonatomic, strong) DocUnderView *underView;
@property (nonatomic, strong) UIView *displayView;
@property (nonatomic, strong) UIView * whiteBoardColorView;
@property (nonatomic ,strong) LKPDFView *pdfView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) YSDrawView *ysDrawView;
@property (nonatomic, assign) BOOL       isPenetration; // 动态课件 是否穿透画布

- (void)setWhiteBoardColor:(UIColor *)color;

- (void)showWhiteBoard0;

- (void)showPDFwithDataDictionary:(NSDictionary *)dictionary
                         Doc_Host:(NSString *)doc_host
                     Doc_Protocol:(NSString *)doc_protocol
                    didFinishLoad:(pdfDidLoadBlock)block;

- (void)showImage:(NSURL *)url host:(NSString *)host finishBlock:(FinishBlock)block;

- (void)showOnWeb;

- (void)clearAfterClass;
@end

@protocol DocShowViewZoomScaleDelegate <NSObject>

@optional

/// 移动ScrollView
- (void)onScrollViewDidScroll;

/// 手势改变ZoomScale
- (void)onZoomScaleChanged:(CGFloat)zoomScale;

@end
