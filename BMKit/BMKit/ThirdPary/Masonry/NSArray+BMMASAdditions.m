//
//  NSArray+MASAdditions.m
//  
//
//  Created by Daniel Hammond on 11/26/13.
//
//

#import "NSArray+BMMASAdditions.h"
#import "View+BMMASAdditions.h"

@implementation NSArray (BMMASAdditions)

- (NSArray *)bmmas_makeConstraints:(void(NS_NOESCAPE ^)(BMMASConstraintMaker *make))block {
    NSMutableArray *constraints = [NSMutableArray array];
    for (BMMAS_VIEW *view in self) {
        NSAssert([view isKindOfClass:[BMMAS_VIEW class]], @"All objects in the array must be views");
        [constraints addObjectsFromArray:[view bmmas_makeConstraints:block]];
    }
    return constraints;
}

- (NSArray *)bmmas_updateConstraints:(void(NS_NOESCAPE ^)(BMMASConstraintMaker *make))block {
    NSMutableArray *constraints = [NSMutableArray array];
    for (BMMAS_VIEW *view in self) {
        NSAssert([view isKindOfClass:[BMMAS_VIEW class]], @"All objects in the array must be views");
        [constraints addObjectsFromArray:[view bmmas_updateConstraints:block]];
    }
    return constraints;
}

- (NSArray *)bmmas_remakeConstraints:(void(NS_NOESCAPE ^)(BMMASConstraintMaker *make))block {
    NSMutableArray *constraints = [NSMutableArray array];
    for (BMMAS_VIEW *view in self) {
        NSAssert([view isKindOfClass:[BMMAS_VIEW class]], @"All objects in the array must be views");
        [constraints addObjectsFromArray:[view bmmas_remakeConstraints:block]];
    }
    return constraints;
}

- (void)bmmas_distributeViewsAlongAxis:(BMMASAxisType)axisType withFixedSpacing:(CGFloat)fixedSpacing leadSpacing:(CGFloat)leadSpacing tailSpacing:(CGFloat)tailSpacing {
    if (self.count < 2) {
        NSAssert(self.count>1,@"views to distribute need to bigger than one");
        return;
    }
    
    BMMAS_VIEW *tempSuperView = [self bmmas_commonSuperviewOfViews];
    if (axisType == BMMASAxisTypeHorizontal) {
        BMMAS_VIEW *prev;
        for (int i = 0; i < self.count; i++) {
            BMMAS_VIEW *v = self[i];
            [v bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
                if (prev) {
                    make.width.equalTo(prev);
                    make.left.equalTo(prev.bmmas_right).offset(fixedSpacing);
                    if (i == self.count - 1) {//last one
                        make.right.equalTo(tempSuperView).offset(-tailSpacing);
                    }
                }
                else {//first one
                    make.left.equalTo(tempSuperView).offset(leadSpacing);
                }
                
            }];
            prev = v;
        }
    }
    else {
        BMMAS_VIEW *prev;
        for (int i = 0; i < self.count; i++) {
            BMMAS_VIEW *v = self[i];
            [v bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
                if (prev) {
                    make.height.equalTo(prev);
                    make.top.equalTo(prev.bmmas_bottom).offset(fixedSpacing);
                    if (i == self.count - 1) {//last one
                        make.bottom.equalTo(tempSuperView).offset(-tailSpacing);
                    }                    
                }
                else {//first one
                    make.top.equalTo(tempSuperView).offset(leadSpacing);
                }
                
            }];
            prev = v;
        }
    }
}

- (void)bmmas_distributeViewsAlongAxis:(BMMASAxisType)axisType withFixedItemLength:(CGFloat)fixedItemLength leadSpacing:(CGFloat)leadSpacing tailSpacing:(CGFloat)tailSpacing {
    if (self.count < 2) {
        NSAssert(self.count>1,@"views to distribute need to bigger than one");
        return;
    }
    
    BMMAS_VIEW *tempSuperView = [self bmmas_commonSuperviewOfViews];
    if (axisType == BMMASAxisTypeHorizontal) {
        BMMAS_VIEW *prev;
        for (int i = 0; i < self.count; i++) {
            BMMAS_VIEW *v = self[i];
            [v bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
                make.width.equalTo(@(fixedItemLength));
                if (prev) {
                    if (i == self.count - 1) {//last one
                        make.right.equalTo(tempSuperView).offset(-tailSpacing);
                    }
                    else {
                        CGFloat offset = (1-(i/((CGFloat)self.count-1)))*(fixedItemLength+leadSpacing)-i*tailSpacing/(((CGFloat)self.count-1));
                        make.right.equalTo(tempSuperView).multipliedBy(i/((CGFloat)self.count-1)).with.offset(offset);
                    }
                }
                else {//first one
                    make.left.equalTo(tempSuperView).offset(leadSpacing);
                }
            }];
            prev = v;
        }
    }
    else {
        BMMAS_VIEW *prev;
        for (int i = 0; i < self.count; i++) {
            BMMAS_VIEW *v = self[i];
            [v bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
                make.height.equalTo(@(fixedItemLength));
                if (prev) {
                    if (i == self.count - 1) {//last one
                        make.bottom.equalTo(tempSuperView).offset(-tailSpacing);
                    }
                    else {
                        CGFloat offset = (1-(i/((CGFloat)self.count-1)))*(fixedItemLength+leadSpacing)-i*tailSpacing/(((CGFloat)self.count-1));
                        make.bottom.equalTo(tempSuperView).multipliedBy(i/((CGFloat)self.count-1)).with.offset(offset);
                    }
                }
                else {//first one
                    make.top.equalTo(tempSuperView).offset(leadSpacing);
                }
            }];
            prev = v;
        }
    }
}

- (BMMAS_VIEW *)bmmas_commonSuperviewOfViews
{
    BMMAS_VIEW *commonSuperview = nil;
    BMMAS_VIEW *previousView = nil;
    for (id object in self) {
        if ([object isKindOfClass:[BMMAS_VIEW class]]) {
            BMMAS_VIEW *view = (BMMAS_VIEW *)object;
            if (previousView) {
                commonSuperview = [view bmmas_closestCommonSuperview:commonSuperview];
            } else {
                commonSuperview = view;
            }
            previousView = view;
        }
    }
    NSAssert(commonSuperview, @"Can't constrain views that do not share a common superview. Make sure that all the views in this array have been added into the same view hierarchy.");
    return commonSuperview;
}

@end
