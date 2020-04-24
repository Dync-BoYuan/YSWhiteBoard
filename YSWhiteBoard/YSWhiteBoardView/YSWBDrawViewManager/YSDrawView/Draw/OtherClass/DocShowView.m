//
//  DocShowView.m
//  WhiteBoard
//
//  Created by frank lin on 15-1-30.
//  Copyright (c) 2015年 itcast. All rights reserved.
//

#import "DocShowView.h"
#import "DrawView.h"
#import "UIImageView+VYWebCache.h"
#import "LKPDFView.h"
#import <YSRoomSDK/YSRoomSDK.h>

#pragma mark -定义宏常量
//#define kImgViewCount 3
//
//#define kImgZoomScaleMin 1
//#define kImgZoomScaleMax 5
//#define kWithAndHeighRadio (4.0/3.0)
//#define kHeighAndWithRadio (3.0/4.0)

#pragma mark -定义展示板

@interface DocShowView() <YSDrawViewDelegate>

@end

@implementation DocShowView
{
    DocUnderView *_underView;
    UIColor *_whiteBoardColor;
}

- (id)init
{
    if (self = [super init]) {
        // 设置代理
        self.delegate = self;
        
        // 暂时禁掉翻页
        self.scrollEnabled = NO;
        self.pagingEnabled = NO;
        
        // 设置背景颜色
        self.backgroundColor = [UIColor clearColor];
        _whiteBoardColor = [UIColor clearColor];
        
        [self initScrollView];
    }
    
    return self;
}

#pragma mark -初始化控件
- (void)initScrollView
{
    // 构建展示组
    self.contentSize = self.bounds.size;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0)
    {
        self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    }

    _underView = [[DocUnderView alloc] init];
    _underView.backgroundColor = UIColor.clearColor;
    [self addSubview:_underView];
    
    _displayView = [[UIView alloc] init];
    [_underView addSubview:_displayView];
    
    
    _pdfView = [[LKPDFView alloc] init];
    [_displayView addSubview:_pdfView];
    
    _imageView = [[UIImageView alloc] init];
    _imageView.userInteractionEnabled = YES;
    [_displayView addSubview:_imageView];
    
    
    _ysDrawView = [[YSDrawView alloc] initWithDelegate:self];
    [_displayView addSubview:_ysDrawView];
    
    [_ysDrawView bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
        make.left.bmmas_equalTo(self->_displayView.bmmas_left);
        make.right.bmmas_equalTo(self->_displayView.bmmas_right);
        make.top.bmmas_equalTo(self->_displayView.bmmas_top);
        make.bottom.bmmas_equalTo(self->_displayView.bmmas_bottom);
    }];
    
    [_pdfView bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
        make.left.bmmas_equalTo(self->_ysDrawView.bmmas_left);
        make.right.bmmas_equalTo(self->_ysDrawView.bmmas_right);
        make.top.bmmas_equalTo(self->_ysDrawView.bmmas_top);
        make.bottom.bmmas_equalTo(self->_ysDrawView.bmmas_bottom);
    }];
    
    [_imageView bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
        make.left.bmmas_equalTo(self->_ysDrawView.bmmas_left);
        make.right.bmmas_equalTo(self->_ysDrawView.bmmas_right);
        make.top.bmmas_equalTo(self->_ysDrawView.bmmas_top);
        make.bottom.bmmas_equalTo(self->_ysDrawView.bmmas_bottom);
    }];
    
    _whiteBoardColorView = [[UIView alloc] init];
    [_displayView addSubview:_whiteBoardColorView];
    [_whiteBoardColorView bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
        make.left.bmmas_equalTo(self->_ysDrawView.bmmas_left);
        make.right.bmmas_equalTo(self->_ysDrawView.bmmas_right);
        make.top.bmmas_equalTo(self->_ysDrawView.bmmas_top);
        make.bottom.bmmas_equalTo(self->_ysDrawView.bmmas_bottom);
    }];
    
    [_displayView sendSubviewToBack:_whiteBoardColorView];
    
    _pdfView.hidden = YES;
    _imageView.hidden = YES;
}

- (void)setWhiteBoardColor:(UIColor *)color
{
    if (color)
    {
        _whiteBoardColor = color;
    }
    else
    {
        _whiteBoardColor = [UIColor clearColor];
    }
}

- (void)showWhiteBoard0
{
    self.hidden = NO;
    _pdfView.hidden = YES;
    _imageView.hidden = YES;
    _whiteBoardColorView.hidden = NO;
    _whiteBoardColorView.backgroundColor = _whiteBoardColor;
}

- (void)showOnWeb
{
    _ysDrawView.drawView.hidden = NO;
    _pdfView.hidden = YES;
    _imageView.hidden = YES;
    _whiteBoardColorView.backgroundColor = UIColor.clearColor;
}

- (void)showPDFwithDataDictionary:(NSDictionary *)dictionary
                         Doc_Host:(NSString *)doc_host
                     Doc_Protocol:(NSString *)doc_protocol
                    didFinishLoad:(pdfDidLoadBlock)block
{
    _pdfView.hidden = NO;
    _imageView.hidden = YES;
    _whiteBoardColorView.hidden = YES;
    _whiteBoardColorView.backgroundColor = _whiteBoardColor;
    [_pdfView showPDFwithDataDictionary:dictionary
                               Doc_Host:doc_host
                           Doc_Protocol:doc_protocol
                          didFinishLoad:block];
}

- (void)showImage:(NSURL *)url host:(NSString *)host finishBlock:(FinishBlock)block
{
    _pdfView.hidden = YES;
    _imageView.hidden = NO;
    _whiteBoardColorView.hidden = NO;
    _whiteBoardColorView.backgroundColor = _whiteBoardColor;
    [self setNeedsLayout];
    [self layoutIfNeeded];
    VYSDWebImageDownloader *downloader = [VYSDWebImageDownloader sharedDownloader];
    downloader.maxConcurrentDownloads = 1;
    //    [downloader cancelAllDownloads];
    [downloader downloadImageWithURL:url host:host options:VYSDWebImageDownloaderHighPriority | VYSDWebImageDownloaderUseNSURLCache progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image) {
                if (block) {
                    block(image.size.width / image.size.height);
                }
                self->_imageView.image = image;
            }
            if (error)
            {
                NSString *log = [NSString stringWithFormat:@"图片文件读取失败 url_%@  host_%@", url, host];
                [[YSRoomInterface instance] serverLog:log];
            }
            else
            {
                NSString *log = [NSString stringWithFormat:@"图片文件读取成功 url_%@  host_%@", url, host];
                [[YSRoomInterface instance] serverLog:log];
            }
        });
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;                                               // any offset changes
{
    if ([self.zoomDelegate respondsToSelector:@selector(onScrollViewDidScroll)])
    {
        [self.zoomDelegate onScrollViewDidScroll];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _displayView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    //scrollView.zoomScale = scale;
    
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if (scrollView.contentSize.width <= scrollView.frame.size.width) {
        if (scrollView.contentSize.height <= scrollView.frame.size.height) {
            _displayView.center = CGPointMake(scrollView.frame.size.width / 2, scrollView.frame.size.height / 2);
        } else {
            _displayView.center = CGPointMake(scrollView.frame.size.width / 2, scrollView.contentSize.height / 2);
        }
    } else {
        if (scrollView.contentSize.height <= scrollView.frame.size.height) {
            _displayView.center = CGPointMake(scrollView.contentSize.width / 2, scrollView.frame.size.height / 2);
        } else {
            _displayView.center = CGPointMake(scrollView.contentSize.width / 2, scrollView.contentSize.height / 2);
        }
    }
    
    if ([self.zoomDelegate respondsToSelector:@selector(onZoomScaleChanged:)])
    {
        [self.zoomDelegate onZoomScaleChanged:scrollView.zoomScale];
    }
}

- (void)addSharpWithFileID:(NSString *)fileid shapeID:(NSString *)shapeID shapeData:(NSData *)shapeData
{
    NSString *dataString = [[NSString alloc] initWithData:shapeData encoding:NSUTF8StringEncoding];
    NSString *s1 = [dataString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
//    NSString *s2 = [s1 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *associatedMsgID = [NSString stringWithFormat:@"%@%@", sYSSignalDocumentFilePage_ExtendShowPage, [YSRoomUtil getwhiteboardIDFromFileId:fileid]];

    [[YSRoomInterface instance] pubMsg:sYSSignalSharpsChange msgID:shapeID toID:YSRoomPubMsgTellAll data:s1 save:YES extensionData:@{} associatedMsgID:associatedMsgID associatedUserID:nil expires:0 completion:^(NSError *error) {
        NSLog(@"%@",error);
    }];
    
}

/// 穿透操作，不做事件截获
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    if (_isPenetration == YES) {
        
        return nil;
    }
    else {
        return [super hitTest:point withEvent:event];
    }
}

- (void)clearAfterClass
{
    [_ysDrawView clearDataAfterClass];
//    _imageView.image = nil;
//    [_pdfView clearAfterClass];
}
@end

