//
//  MASConstraintMaker.m
//  Masonry
//
//  Created by Jonas Budelmann on 20/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import "BMMASConstraintMaker.h"
#import "BMMASViewConstraint.h"
#import "BMMASCompositeConstraint.h"
#import "BMMASConstraint+Private.h"
#import "BMMASViewAttribute.h"
#import "View+BMMASAdditions.h"

@interface BMMASConstraintMaker () <BMMASConstraintDelegate>

@property (nonatomic, weak) BMMAS_VIEW *view;
@property (nonatomic, strong) NSMutableArray *constraints;

@end

@implementation BMMASConstraintMaker

- (id)initWithView:(BMMAS_VIEW *)view {
    self = [super init];
    if (!self) return nil;
    
    self.view = view;
    self.constraints = NSMutableArray.new;
    
    return self;
}

- (NSArray *)install {
    if (self.removeExisting) {
        NSArray *installedConstraints = [BMMASViewConstraint installedConstraintsForView:self.view];
        for (BMMASConstraint *constraint in installedConstraints) {
            [constraint uninstall];
        }
    }
    NSArray *constraints = self.constraints.copy;
    for (BMMASConstraint *constraint in constraints) {
        constraint.updateExisting = self.updateExisting;
        [constraint install];
    }
    [self.constraints removeAllObjects];
    return constraints;
}

#pragma mark - MASConstraintDelegate

- (void)constraint:(BMMASConstraint *)constraint shouldBeReplacedWithConstraint:(BMMASConstraint *)replacementConstraint {
    NSUInteger index = [self.constraints indexOfObject:constraint];
    NSAssert(index != NSNotFound, @"Could not find constraint %@", constraint);
    [self.constraints replaceObjectAtIndex:index withObject:replacementConstraint];
}

- (BMMASConstraint *)constraint:(BMMASConstraint *)constraint addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute {
    BMMASViewAttribute *viewAttribute = [[BMMASViewAttribute alloc] initWithView:self.view layoutAttribute:layoutAttribute];
    BMMASViewConstraint *newConstraint = [[BMMASViewConstraint alloc] initWithFirstViewAttribute:viewAttribute];
    if ([constraint isKindOfClass:BMMASViewConstraint.class]) {
        //replace with composite constraint
        NSArray *children = @[constraint, newConstraint];
        BMMASCompositeConstraint *compositeConstraint = [[BMMASCompositeConstraint alloc] initWithChildren:children];
        compositeConstraint.delegate = self;
        [self constraint:constraint shouldBeReplacedWithConstraint:compositeConstraint];
        return compositeConstraint;
    }
    if (!constraint) {
        newConstraint.delegate = self;
        [self.constraints addObject:newConstraint];
    }
    return newConstraint;
}

- (BMMASConstraint *)addConstraintWithAttributes:(BMMASAttribute)attrs {
    __unused BMMASAttribute anyAttribute = (BMMASAttributeLeft | BMMASAttributeRight | BMMASAttributeTop | BMMASAttributeBottom | BMMASAttributeLeading
                                          | BMMASAttributeTrailing | BMMASAttributeWidth | BMMASAttributeHeight | BMMASAttributeCenterX
                                          | BMMASAttributeCenterY | BMMASAttributeBaseline
                                          | BMMASAttributeFirstBaseline | BMMASAttributeLastBaseline
#if TARGET_OS_IPHONE || TARGET_OS_TV
                                          | BMMASAttributeLeftMargin | BMMASAttributeRightMargin | BMMASAttributeTopMargin | BMMASAttributeBottomMargin
                                          | BMMASAttributeLeadingMargin | BMMASAttributeTrailingMargin | BMMASAttributeCenterXWithinMargins
                                          | BMMASAttributeCenterYWithinMargins
#endif
                                          );
    
    NSAssert((attrs & anyAttribute) != 0, @"You didn't pass any attribute to make.attributes(...)");
    
    NSMutableArray *attributes = [NSMutableArray array];
    
    if (attrs & BMMASAttributeLeft) [attributes addObject:self.view.bmmas_left];
    if (attrs & BMMASAttributeRight) [attributes addObject:self.view.bmmas_right];
    if (attrs & BMMASAttributeTop) [attributes addObject:self.view.bmmas_top];
    if (attrs & BMMASAttributeBottom) [attributes addObject:self.view.bmmas_bottom];
    if (attrs & BMMASAttributeLeading) [attributes addObject:self.view.bmmas_leading];
    if (attrs & BMMASAttributeTrailing) [attributes addObject:self.view.bmmas_trailing];
    if (attrs & BMMASAttributeWidth) [attributes addObject:self.view.bmmas_width];
    if (attrs & BMMASAttributeHeight) [attributes addObject:self.view.bmmas_height];
    if (attrs & BMMASAttributeCenterX) [attributes addObject:self.view.bmmas_centerX];
    if (attrs & BMMASAttributeCenterY) [attributes addObject:self.view.bmmas_centerY];
    if (attrs & BMMASAttributeBaseline) [attributes addObject:self.view.bmmas_baseline];
    if (attrs & BMMASAttributeFirstBaseline) [attributes addObject:self.view.bmmas_firstBaseline];
    if (attrs & BMMASAttributeLastBaseline) [attributes addObject:self.view.bmmas_lastBaseline];
    
#if TARGET_OS_IPHONE || TARGET_OS_TV
    
    if (attrs & BMMASAttributeLeftMargin) [attributes addObject:self.view.bmmas_leftMargin];
    if (attrs & BMMASAttributeRightMargin) [attributes addObject:self.view.bmmas_rightMargin];
    if (attrs & BMMASAttributeTopMargin) [attributes addObject:self.view.bmmas_topMargin];
    if (attrs & BMMASAttributeBottomMargin) [attributes addObject:self.view.bmmas_bottomMargin];
    if (attrs & BMMASAttributeLeadingMargin) [attributes addObject:self.view.bmmas_leadingMargin];
    if (attrs & BMMASAttributeTrailingMargin) [attributes addObject:self.view.bmmas_trailingMargin];
    if (attrs & BMMASAttributeCenterXWithinMargins) [attributes addObject:self.view.bmmas_centerXWithinMargins];
    if (attrs & BMMASAttributeCenterYWithinMargins) [attributes addObject:self.view.bmmas_centerYWithinMargins];
    
#endif
    
    NSMutableArray *children = [NSMutableArray arrayWithCapacity:attributes.count];
    
    for (BMMASViewAttribute *a in attributes) {
        [children addObject:[[BMMASViewConstraint alloc] initWithFirstViewAttribute:a]];
    }
    
    BMMASCompositeConstraint *constraint = [[BMMASCompositeConstraint alloc] initWithChildren:children];
    constraint.delegate = self;
    [self.constraints addObject:constraint];
    return constraint;
}

#pragma mark - standard Attributes

- (BMMASConstraint *)addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute {
    return [self constraint:nil addConstraintWithLayoutAttribute:layoutAttribute];
}

- (BMMASConstraint *)left {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeLeft];
}

- (BMMASConstraint *)top {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeTop];
}

- (BMMASConstraint *)right {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeRight];
}

- (BMMASConstraint *)bottom {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeBottom];
}

- (BMMASConstraint *)leading {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeLeading];
}

- (BMMASConstraint *)trailing {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeTrailing];
}

- (BMMASConstraint *)width {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeWidth];
}

- (BMMASConstraint *)height {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeHeight];
}

- (BMMASConstraint *)centerX {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeCenterX];
}

- (BMMASConstraint *)centerY {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeCenterY];
}

- (BMMASConstraint *)baseline {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeBaseline];
}

- (BMMASConstraint *(^)(BMMASAttribute))attributes {
    return ^(BMMASAttribute attrs){
        return [self addConstraintWithAttributes:attrs];
    };
}

- (BMMASConstraint *)firstBaseline {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeFirstBaseline];
}

- (BMMASConstraint *)lastBaseline {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeLastBaseline];
}

#if TARGET_OS_IPHONE || TARGET_OS_TV

- (BMMASConstraint *)leftMargin {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeLeftMargin];
}

- (BMMASConstraint *)rightMargin {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeRightMargin];
}

- (BMMASConstraint *)topMargin {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeTopMargin];
}

- (BMMASConstraint *)bottomMargin {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeBottomMargin];
}

- (BMMASConstraint *)leadingMargin {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeLeadingMargin];
}

- (BMMASConstraint *)trailingMargin {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeTrailingMargin];
}

- (BMMASConstraint *)centerXWithinMargins {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeCenterXWithinMargins];
}

- (BMMASConstraint *)centerYWithinMargins {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeCenterYWithinMargins];
}

#endif


#pragma mark - composite Attributes

- (BMMASConstraint *)edges {
    return [self addConstraintWithAttributes:BMMASAttributeTop | BMMASAttributeLeft | BMMASAttributeRight | BMMASAttributeBottom];
}

- (BMMASConstraint *)size {
    return [self addConstraintWithAttributes:BMMASAttributeWidth | BMMASAttributeHeight];
}

- (BMMASConstraint *)center {
    return [self addConstraintWithAttributes:BMMASAttributeCenterX | BMMASAttributeCenterY];
}

#pragma mark - grouping

- (BMMASConstraint *(^)(dispatch_block_t group))group {
    return ^id(dispatch_block_t group) {
        NSInteger previousCount = self.constraints.count;
        group();

        NSArray *children = [self.constraints subarrayWithRange:NSMakeRange(previousCount, self.constraints.count - previousCount)];
        BMMASCompositeConstraint *constraint = [[BMMASCompositeConstraint alloc] initWithChildren:children];
        constraint.delegate = self;
        return constraint;
    };
}

@end
