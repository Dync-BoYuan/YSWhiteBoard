//
//  UIView+MASShorthandAdditions.h
//  Masonry
//
//  Created by Jonas Budelmann on 22/07/13.
//  Copyright (c) 2013 Jonas Budelmann. All rights reserved.
//

#import "View+BMMASAdditions.h"

#ifdef MAS_SHORTHAND

/**
 *	Shorthand view additions without the 'mas_' prefixes,
 *  only enabled if MAS_SHORTHAND is defined
 */
@interface MAS_VIEW (BMMASShorthandAdditions)

@property (nonatomic, strong, readonly) BMMASViewAttribute *left;
@property (nonatomic, strong, readonly) BMMASViewAttribute *top;
@property (nonatomic, strong, readonly) BMMASViewAttribute *right;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bottom;
@property (nonatomic, strong, readonly) BMMASViewAttribute *leading;
@property (nonatomic, strong, readonly) BMMASViewAttribute *trailing;
@property (nonatomic, strong, readonly) BMMASViewAttribute *width;
@property (nonatomic, strong, readonly) BMMASViewAttribute *height;
@property (nonatomic, strong, readonly) BMMASViewAttribute *centerX;
@property (nonatomic, strong, readonly) BMMASViewAttribute *centerY;
@property (nonatomic, strong, readonly) BMMASViewAttribute *baseline;
@property (nonatomic, strong, readonly) BMMASViewAttribute *(^attribute)(NSLayoutAttribute attr);

@property (nonatomic, strong, readonly) BMMASViewAttribute *firstBaseline;
@property (nonatomic, strong, readonly) BMMASViewAttribute *lastBaseline;

#if TARGET_OS_IPHONE || TARGET_OS_TV

@property (nonatomic, strong, readonly) BMMASViewAttribute *leftMargin;
@property (nonatomic, strong, readonly) BMMASViewAttribute *rightMargin;
@property (nonatomic, strong, readonly) BMMASViewAttribute *topMargin;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bottomMargin;
@property (nonatomic, strong, readonly) BMMASViewAttribute *leadingMargin;
@property (nonatomic, strong, readonly) BMMASViewAttribute *trailingMargin;
@property (nonatomic, strong, readonly) BMMASViewAttribute *centerXWithinMargins;
@property (nonatomic, strong, readonly) BMMASViewAttribute *centerYWithinMargins;

#endif

#if TARGET_OS_IPHONE || TARGET_OS_TV

@property (nonatomic, strong, readonly) BMMASViewAttribute *safeAreaLayoutGuideLeading NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *safeAreaLayoutGuideTrailing NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *safeAreaLayoutGuideLeft NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *safeAreaLayoutGuideRight NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *safeAreaLayoutGuideTop NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *safeAreaLayoutGuideBottom NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *safeAreaLayoutGuideWidth NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *safeAreaLayoutGuideHeight NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *safeAreaLayoutGuideCenterX NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *safeAreaLayoutGuideCenterY NS_AVAILABLE_IOS(11.0);

#endif

- (NSArray *)bmmakeConstraints:(void(^)(MASConstraintMaker *make))block;
- (NSArray *)bmupdateConstraints:(void(^)(MASConstraintMaker *make))block;
- (NSArray *)bmremakeConstraints:(void(^)(MASConstraintMaker *make))block;

@end

#define BMMAS_ATTR_FORWARD(attr)  \
- (BMMASViewAttribute *)attr {    \
    return [self mas_##attr];   \
}

#define BMMAS_ATTR_FORWARD_AVAILABLE(attr, available)  \
- (BMMASViewAttribute *)attr available {    \
    return [self mas_##attr];   \
}

@implementation MAS_VIEW (BMMASShorthandAdditions)

BMMAS_ATTR_FORWARD(top);
BMMAS_ATTR_FORWARD(left);
BMMAS_ATTR_FORWARD(bottom);
BMMAS_ATTR_FORWARD(right);
BMMAS_ATTR_FORWARD(leading);
BMMAS_ATTR_FORWARD(trailing);
BMMAS_ATTR_FORWARD(width);
BMMAS_ATTR_FORWARD(height);
BMMAS_ATTR_FORWARD(centerX);
BMMAS_ATTR_FORWARD(centerY);
BMMAS_ATTR_FORWARD(baseline);

BMMAS_ATTR_FORWARD(firstBaseline);
BMMAS_ATTR_FORWARD(lastBaseline);

#if TARGET_OS_IPHONE || TARGET_OS_TV

BMMAS_ATTR_FORWARD(leftMargin);
BMMAS_ATTR_FORWARD(rightMargin);
BMMAS_ATTR_FORWARD(topMargin);
BMMAS_ATTR_FORWARD(bottomMargin);
BMMAS_ATTR_FORWARD(leadingMargin);
BMMAS_ATTR_FORWARD(trailingMargin);
BMMAS_ATTR_FORWARD(centerXWithinMargins);
BMMAS_ATTR_FORWARD(centerYWithinMargins);

BMMAS_ATTR_FORWARD_AVAILABLE(safeAreaLayoutGuideLeading, NS_AVAILABLE_IOS(11.0));
BMMAS_ATTR_FORWARD_AVAILABLE(safeAreaLayoutGuideTrailing, NS_AVAILABLE_IOS(11.0));
BMMAS_ATTR_FORWARD_AVAILABLE(safeAreaLayoutGuideLeft, NS_AVAILABLE_IOS(11.0));
BMMAS_ATTR_FORWARD_AVAILABLE(safeAreaLayoutGuideRight, NS_AVAILABLE_IOS(11.0));
BMMAS_ATTR_FORWARD_AVAILABLE(safeAreaLayoutGuideTop, NS_AVAILABLE_IOS(11.0));
BMMAS_ATTR_FORWARD_AVAILABLE(safeAreaLayoutGuideBottom, NS_AVAILABLE_IOS(11.0));
BMMAS_ATTR_FORWARD_AVAILABLE(safeAreaLayoutGuideWidth, NS_AVAILABLE_IOS(11.0));
BMMAS_ATTR_FORWARD_AVAILABLE(safeAreaLayoutGuideHeight, NS_AVAILABLE_IOS(11.0));
BMMAS_ATTR_FORWARD_AVAILABLE(safeAreaLayoutGuideCenterX, NS_AVAILABLE_IOS(11.0));
BMMAS_ATTR_FORWARD_AVAILABLE(safeAreaLayoutGuideCenterY, NS_AVAILABLE_IOS(11.0));

#endif

- (BMMASViewAttribute *(^)(NSLayoutAttribute))bmattribute {
    return [self bmmas_attribute];
}

- (NSArray *)bmmakeConstraints:(void(NS_NOESCAPE ^)(MASConstraintMaker *))block {
    return [self bmmas_makeConstraints:block];
}

- (NSArray *)bmupdateConstraints:(void(NS_NOESCAPE ^)(MASConstraintMaker *))block {
    return [self bmmas_updateConstraints:block];
}

- (NSArray *)bmremakeConstraints:(void(NS_NOESCAPE ^)(MASConstraintMaker *))block {
    return [self bmmas_remakeConstraints:block];
}

@end

#endif
