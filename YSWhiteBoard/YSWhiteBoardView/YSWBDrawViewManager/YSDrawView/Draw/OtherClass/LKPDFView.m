
//
//  PDFView.m
//  YSWhiteBoard
//
//  Created by 周洁 on 2018/12/20.
//  Copyright © 2018 MAC-MiNi. All rights reserved.
//

#import "LKPDFView.h"
#import "VYSDWebImageDownloader.h"
#import "YSWhiteBordHttpDNSUtil.h"
#import <YSRoomSDK/YSRoomSDK.h>

@implementation LKPDFView
{
    NSInteger _currentPage;
    NSInteger _totalPage;
    NSString *_swfPath;
    NSString *_fileId;
    
    VYSDWebImageDownloadToken *_downloadToken;
    
    CGRect _drawRect;
    CGPDFDocumentRef _pdfRef;
    CGPDFPageRef _pageRef;
    
    NSString *_doc_host;
    NSString *_doc_protocol;
    
    float _delta;
    
    pdfDidLoadBlock _block;
    CGSize _originSize;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _originSize = frame.size;
    }
    
    return self;
}

- (void)showPDFwithDataDictionary:(NSDictionary *)dictionary
                         Doc_Host:(NSString *)doc_host
                     Doc_Protocol:(NSString *)doc_protocol
                    didFinishLoad:(nonnull pdfDidLoadBlock)block
{
    if (!dictionary || dictionary.allKeys.count == 0) {
        return;
    }
    NSDictionary *filedata = [dictionary objectForKey:@"filedata"];
    _delta = 1;
    _currentPage    = ((NSNumber *)[filedata objectForKey:@"currpage"]).integerValue;
    _totalPage      = ((NSNumber *)[filedata objectForKey:@"pagenum"]).integerValue;
    _swfPath        = [filedata objectForKey:@"swfpath"];
    _fileId         = [[dictionary objectForKey:@"filedata"] bm_stringForKey:@"fileid"];
    
    _doc_host       = doc_host;
    _doc_protocol   = doc_protocol;
    
    _block = block;
    
    [self getPDFData];
}

- (void)prePage
{
    if (_currentPage == 0) {
        return;
    }
    
    _currentPage--;
    
    [self getPDFData];
}

- (void)nextPage
{
    if (_currentPage == _totalPage) {
        return;
    }
    
    _currentPage++;
    
    [self getPDFData];
}

- (NSURL *)getURLByCurrentPage
{
    NSArray *components = [_swfPath componentsSeparatedByString:@"."];
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@://%@",_doc_protocol, _doc_host];
    for (int i = 0; i < components.count - 1; i++) {
        [urlString appendString:components[i]];
        [urlString appendString:@"."];
    }
    //避免文件名中b包含多个"."
    [urlString replaceCharactersInRange:NSMakeRange(urlString.length - 1, 1) withString:@"-"];
    [urlString appendString:[NSString stringWithFormat:@"%ld",(long)_currentPage]];
    [urlString appendString:@"."];
    [urlString appendString:@"pdf"];//
    
    urlString = [NSMutableString stringWithString:[YSWhiteBordHttpDNSUtil getIpUrlPathWithPath:urlString fileId:_fileId currentPage:_currentPage]];

    return [NSURL URLWithString:urlString];
}

- (void)getPDFData
{
    NSURL *url = [self getURLByCurrentPage];

    NSString *host = _doc_host;

    BMWeakSelf
    VYSDWebImageDownloader *downloader = [VYSDWebImageDownloader sharedDownloader];
    downloader.maxConcurrentDownloads = 1;
    //    [downloader cancelAllDownloads];
    _downloadToken = [downloader downloadImageWithURL:url host:host options:VYSDWebImageDownloaderHighPriority | VYSDWebImageDownloaderUseNSURLCache progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf analyzeData:data];
            if (error)
            {
                NSString *log = [NSString stringWithFormat:@"PDF文件读取失败 fileId_%@  currentPage_%@", self->_fileId, @(self->_currentPage)];
                [[YSRoomInterface instance] serverLog:log];
            }
            else
            {
                NSString *log = [NSString stringWithFormat:@"PDF文件读取成功 fileId_%@  currentPage_%@", self->_fileId, @(self->_currentPage)];
                [[YSRoomInterface instance] serverLog:log];
            }
        });
    }];
}

- (void)analyzeData:(NSData *)data
{
    if (!data) {
        return;
    }
    
    CFDataRef dataRef = (__bridge_retained CFDataRef)data;
    
    CGDataProviderRef providerRef = CGDataProviderCreateWithCFData(dataRef);
    CFRelease(dataRef);
    
    _pdfRef = CGPDFDocumentCreateWithProvider(providerRef);
    CFRelease(providerRef);
    
    //获取总页数. 总是一次下发一页，暂时没用
    //    size_t totalPage = CGPDFDocumentGetNumberOfPages(pdfRef);
    
    //页码起始值为1
    _pageRef = CGPDFDocumentGetPage(_pdfRef, 1);
    _drawRect = CGPDFPageGetBoxRect(_pageRef, kCGPDFCropBox);
    
    //    _block(_drawRect.size.width / _drawRect.size.height);
    int angle = CGPDFPageGetRotationAngle(_pageRef);
    if ((angle / 90) % 2 == 1) {
        _block(_drawRect.size.height / _drawRect.size.width);
    } else {
        _block(_drawRect.size.width / _drawRect.size.height);
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextRetain(context);
    CGContextSaveGState(context);
    [UIColor.whiteColor set];
    CGContextFillRect(context, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
    
    //确定放大倍数
    float pdfRatio = 0;
    int angle = CGPDFPageGetRotationAngle(_pageRef);
    if ((angle / 90) % 2 == 0) {
        pdfRatio = _drawRect.size.width / _drawRect.size.height;
    } else {
        pdfRatio = _drawRect.size.height / _drawRect.size.width;
    }
    
    float selfRatio = self.frame.size.width / self.frame.size.height;
    float scale = 1;
    if (pdfRatio >= selfRatio) {
        if ((angle / 90) % 2 == 0) {
            scale = self.frame.size.width / _drawRect.size.width;
        } else {
            scale = self.frame.size.width / _drawRect.size.height;
        }
    } else {
        if ((angle / 90) % 2 == 0) {
            scale = self.frame.size.height / _drawRect.size.height;
        } else {
            scale = self.frame.size.height / _drawRect.size.width;
        }
    }
    
    //上下翻转图像
    if ( (abs(angle) % 360) != 180)
    {
        CGContextTranslateCTM(context, 0.0, rect.size.height);
        CGContextScaleCTM(context, 1, -1);
    }
    // 左右翻转图像
    else
    {
        CGContextTranslateCTM(context, rect.size.width, 0.0f);
        CGContextScaleCTM(context, -1.f, 1.f);
    }

    //缩放
    CGContextConcatCTM(context, CGAffineTransformMakeScale(scale, scale));
    
    //平移截取到pdf的CGPDFPageGetBoxRect
    CGContextTranslateCTM(context, -_drawRect.origin.x, -_drawRect.origin.y);
    
    //旋转
    if (angle != 180)
    {
    if ((angle / 90) % 2 == 1) {
        CGContextRotateCTM(context, - (angle / 90) * M_PI_2);
        CGContextTranslateCTM(context, -_drawRect.size.width, 0);
    }
    }
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetRenderingIntent(context, kCGRenderingIntentRelativeColorimetric);
    CGContextDrawPDFPage(context, _pageRef);//绘制pdf
    CGContextRestoreGState(context);
    CGContextRelease(context);
}

- (void)enlargeOrNarrow:(float)delta
{
    _delta = delta;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, _originSize.width * delta, _originSize.height * delta);
    [self setNeedsDisplay];
}

-(void)clearAfterClass
{
    if (_downloadToken)
    {
        VYSDWebImageDownloader *downloader = [VYSDWebImageDownloader sharedDownloader];
        [downloader cancel:_downloadToken];
        _downloadToken = nil;
    }
    
    if (_pdfRef)
    {
        CGPDFDocumentRelease(_pdfRef);
        _pdfRef = nil;
    }
    
    _pageRef = nil;
    [self setNeedsDisplay];
}

@end
