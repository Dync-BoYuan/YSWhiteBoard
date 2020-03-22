//
//  UIView+MASAdditions.m
//  Masonry
//
//  Created by Jonas Budelmann on 20/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import "View+BMMASAdditions.h"
#import <objc/runtime.h>

@implementation BMMAS_VIEW (BMMASAdditions)

- (NSArray *)bmmas_makeConstraints:(void(NS_NOESCAPE ^)(BMMASConstraintMaker *))block {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    BMMASConstraintMaker *constraintMaker = [[BMMASConstraintMaker alloc] initWithView:self];
    block(constraintMaker);
    return [constraintMaker install];
}

- (NSArray *)bmmas_updateConstraints:(void(NS_NOESCAPE ^)(BMMASConstraintMaker *))block {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    BMMASConstraintMaker *constraintMaker = [[BMMASConstraintMaker alloc] initWithView:self];
    constraintMaker.updateExisting = YES;
    block(constraintMaker);
    return [constraintMaker install];
}

- (NSArray *)bmmas_remakeConstraints:(void(NS_NOESCAPE ^)(BMMASConstraintMaker *make))block {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    BMMASConstraintMaker *constraintMaker = [[BMMASConstraintMaker alloc] initWithView:self];
    constraintMaker.removeExisting = YES;
    block(constraintMaker);
    return [constraintMaker install];
}

#pragma mark - NSLayoutAttribute properties

- (BMMASViewAttribute *)bmmas_left {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeLeft];
}

- (BMMASViewAttribute *)bmmas_top {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeTop];
}

- (BMMASViewAttribute *)bmmas_right {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeRight];
}

- (BMMASViewAttribute *)bmmas_bottom {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeBottom];
}

- (BMMASViewAttribute *)bmmas_leading {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeLeading];
}

- (BMMASViewAttribute *)bmmas_trailing {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeTrailing];
}

- (BMMASViewAttribute *)bmmas_width {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeWidth];
}

- (BMMASViewAttribute *)bmmas_height {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeHeight];
}

- (BMMASViewAttribute *)bmmas_centerX {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeCenterX];
}

- (BMMASViewAttribute *)bmmas_centerY {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeCenterY];
}

- (BMMASViewAttribute *)bmmas_baseline {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeBaseline];
}

- (BMMASViewAttribute *(^)(NSLayoutAttribute))bmmas_attribute
{
    return ^(NSLayoutAttribute attr) {
        return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:attr];
    };
}

- (BMMASViewAttribute *)bmmas_firstBaseline {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeFirstBaseline];
}
- (BMMASViewAttribute *)bmmas_lastBaseline {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeLastBaseline];
}

#if TARGET_OS_IPHONE || TARGET_OS_TV

- (BMMASViewAttribute *)bmmas_leftMargin {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeLeftMargin];
}

- (BMMASViewAttribute *)bmmas_rightMargin {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeRightMargin];
}

- (BMMASViewAttribute *)bmmas_topMargin {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeTopMargin];
}

- (BMMASViewAttribute *)bmmas_bottomMargin {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeBottomMargin];
}

- (BMMASViewAttribute *)bmmas_leadingMargin {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeLeadingMargin];
}

- (BMMASViewAttribute *)bmmas_trailingMargin {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeTrailingMargin];
}

- (BMMASViewAttribute *)bmmas_centerXWithinMargins {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeCenterXWithinMargins];
}

- (BMMASViewAttribute *)bmmas_centerYWithinMargins {
    return [[BMMASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeCenterYWithinMargins];
}

- (BMMASViewAttribute *)bmmas_safeAreaLayoutGuide {
    return [[BMMASViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeNotAnAttribute];
}

- (BMMASViewAttribute *)bmmas_safeAreaLayoutGuideLeading {
    return [[BMMASViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeLeading];
}

- (BMMASViewAttribute *)bmmas_safeAreaLayoutGuideTrailing {
    return [[BMMASViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeTrailing];
}

- (BMMASViewAttribute *)bmmas_safeAreaLayoutGuideLeft {
    return [[BMMASViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeLeft];
}

- (BMMASViewAttribute *)bmmas_safeAreaLayoutGuideRight {
    return [[BMMASViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeRight];
}

- (BMMASViewAttribute *)bmmas_safeAreaLayoutGuideTop {
    return [[BMMASViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeTop];
}

- (BMMASViewAttribute *)bmmas_safeAreaLayoutGuideBottom {
    return [[BMMASViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeBottom];
}

- (BMMASViewAttribute *)bmmas_safeAreaLayoutGuideWidth {
    return [[BMMASViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeWidth];
}

- (BMMASViewAttribute *)bmmas_safeAreaLayoutGuideHeight {
    return [[BMMASViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeHeight];
}

- (BMMASViewAttribute *)bmmas_safeAreaLayoutGuideCenterX {
    return [[BMMASViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeCenterX];
}

- (BMMASViewAttribute *)bmmas_safeAreaLayoutGuideCenterY {
    return [[BMMASViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeCenterY];
}

#endif

#pragma mark - associated properties

- (id)bmmas_key {
    return objc_getAssociatedObject(self, @selector(bmmas_key));
}

- (void)setBmmas_key:(id)key {
    objc_setAssociatedObject(self, @selector(bmmas_key), key, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - heirachy

- (instancetype)bmmas_closestCommonSuperview:(BMMAS_VIEW *)view {
    BMMAS_VIEW *closestCommonSuperview = nil;

    BMMAS_VIEW *secondViewSuperview = view;
    while (!closestCommonSuperview && secondViewSuperview) {
        BMMAS_VIEW *firstViewSuperview = self;
        while (!closestCommonSuperview && firstViewSuperview) {
            if (secondViewSuperview == firstViewSuperview) {
                closestCommonSuperview = secondViewSuperview;
            }
            firstViewSuperview = firstViewSuperview.superview;
        }
        secondViewSuperview = secondViewSuperview.superview;
    }
    return closestCommonSuperview;
}

@end
