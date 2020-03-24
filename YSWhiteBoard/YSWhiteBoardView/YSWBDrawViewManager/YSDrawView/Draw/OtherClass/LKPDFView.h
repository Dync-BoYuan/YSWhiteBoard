//
//  PDFView.h
//  YSWhiteBoard
//
//  Created by 周洁 on 2018/12/20.
//  Copyright © 2018 MAC-MiNi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DocUnderView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKPDFView : UIView

typedef void (^pdfDidLoadBlock)(float ratio);

@property (nonatomic, weak) DocUnderView *underView;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)showPDFwithDataDictionary:(NSDictionary *)dictionary
                         Doc_Host:(NSString *)doc_host
                     Doc_Protocol:(NSString *)doc_protocol
                    didFinishLoad:(pdfDidLoadBlock)block;

- (void)enlargeOrNarrow:(float)delta;

- (void)clearAfterClass;

@end

NS_ASSUME_NONNULL_END
