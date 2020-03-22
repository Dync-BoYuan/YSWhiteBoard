//
//  BMFreshView.h
//  FengTiaoYuShun
//
//  Created by best2wa on 2018/8/23.
//  Copyright © 2018年 BMSoft. All rights reserved.
//

#ifndef BMFreshView_h
#define BMFreshView_h

#import "NSObject+BMCategory.h"
#import "UILabel+BMCategory.h"
#import "UIColor+BMCategory.h"
#import "CALayer+BMSize.h"
#import "UIView+BMSize.h"

extern NSString *const BMFreshKeyPathContentOffset;
extern NSString *const BMFreshKeyPathContentSize;
extern NSString *const BMFreshKeyPathContentInset;
extern NSString *const BMFreshKeyPathPanState;

static const NSTimeInterval BMFreshAnimationDuration = 0.25f;

#ifdef DEBUG
#define BMFRESH_SHOWPULLINGPERCENT      0
#endif


#define BMFRESH_DEFAULT_NORMALHEADERTEXT        BMKitLocalized(@"Fresh.Default.NormalHeaderText", @"")
#define BMFRESH_DEFAULT_WILLLOADHEADERTEXT      BMKitLocalized(@"Fresh.Default.WillLoadHeaderText", @"")
#define BMFRESH_DEFAULT_LOADINGHEADERTEXT       BMKitLocalized(@"Fresh.Default.LoadingHeaderText", @"")

#define BMFRESH_DEFAULT_NORMALFOOTERTEXT        BMKitLocalized(@"Fresh.Default.NormalFooterText", @"")
#define BMFRESH_DEFAULT_AUTONORMALFOOTERTEXT    BMKitLocalized(@"Fresh.Default.AutoNormalFooterText", @"")
#define BMFRESH_DEFAULT_WILLLOADFOOTERTEXT      BMKitLocalized(@"Fresh.Default.WilllLoadFooterText", @"")
#define BMFRESH_DEFAULT_LOADINGFOOTERTEXT       BMKitLocalized(@"Fresh.Default.LoadingFooterText", @"")
#define BMFRESH_DEFAULT_NOMOREDATAFOOTERTEXT    BMKitLocalized(@"Fresh.Default.NoMoredataFooterText", @"")


static const CGFloat BMFreshDefaultContainerSize = 36.0f;
static const CGFloat BMFreshDefaultContainerLabelGap = 8.0f;

typedef NS_OPTIONS(NSUInteger, BMFreshViewType)
{
    BMFreshViewType_NONE = 0,
    BMFreshViewType_Head = 1 << 0,
    BMFreshViewType_Bottom = 1 << 1,
    BMFreshViewType_ALL = BMFreshViewType_Head | BMFreshViewType_Bottom
};

typedef NS_ENUM(NSUInteger, BMFreshHeaderViewType)
{
    BMFreshHeaderViewType_None,
    BMFreshHeaderViewType_Normal,
    BMFreshHeaderViewType_Circle,
    BMFreshHeaderViewType_SemiCircle,
    BMFreshHeaderViewType_DotCircle,
    BMFreshHeaderViewType_Arc,
    BMFreshHeaderViewType_Dot,
    BMFreshHeaderViewType_TriangleDot,
    BMFreshHeaderViewType_FiveStar,
    BMFreshHeaderViewType_Gif
};

typedef NS_ENUM(NSUInteger, BMFreshFooterViewType)
{
    BMFreshFooterViewType_None,
    BMFreshFooterViewType_BackNormal
};

// 刷新控件的状态
typedef NS_ENUM(NSUInteger, BMFreshState)
{
    BMFreshStateError = 0,
    // 普通闲置状态
    BMFreshStateIdle = 1,
    // 即将刷新的状态，松手即刷新
    BMFreshStateWillRefresh,
    // 正在刷新中的状态
    BMFreshStateRefreshing,
    // 所有数据加载完毕，没有更多的数据
    BMFreshStateNoMoreData
};

#endif /* BMFreshView_h */
