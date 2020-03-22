//
//  MASConstraintMaker.h
//  Masonry
//
//  Created by Jonas Budelmann on 20/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import "BMMASConstraint.h"
#import "BMMASUtilities.h"

typedef NS_OPTIONS(NSInteger, BMMASAttribute) {
    BMMASAttributeLeft = 1 << NSLayoutAttributeLeft,
    BMMASAttributeRight = 1 << NSLayoutAttributeRight,
    BMMASAttributeTop = 1 << NSLayoutAttributeTop,
    BMMASAttributeBottom = 1 << NSLayoutAttributeBottom,
    BMMASAttributeLeading = 1 << NSLayoutAttributeLeading,
    BMMASAttributeTrailing = 1 << NSLayoutAttributeTrailing,
    BMMASAttributeWidth = 1 << NSLayoutAttributeWidth,
    BMMASAttributeHeight = 1 << NSLayoutAttributeHeight,
    BMMASAttributeCenterX = 1 << NSLayoutAttributeCenterX,
    BMMASAttributeCenterY = 1 << NSLayoutAttributeCenterY,
    BMMASAttributeBaseline = 1 << NSLayoutAttributeBaseline,

    BMMASAttributeFirstBaseline = 1 << NSLayoutAttributeFirstBaseline,
    BMMASAttributeLastBaseline = 1 << NSLayoutAttributeLastBaseline,
    
#if TARGET_OS_IPHONE || TARGET_OS_TV
    
    BMMASAttributeLeftMargin = 1 << NSLayoutAttributeLeftMargin,
    BMMASAttributeRightMargin = 1 << NSLayoutAttributeRightMargin,
    BMMASAttributeTopMargin = 1 << NSLayoutAttributeTopMargin,
    BMMASAttributeBottomMargin = 1 << NSLayoutAttributeBottomMargin,
    BMMASAttributeLeadingMargin = 1 << NSLayoutAttributeLeadingMargin,
    BMMASAttributeTrailingMargin = 1 << NSLayoutAttributeTrailingMargin,
    BMMASAttributeCenterXWithinMargins = 1 << NSLayoutAttributeCenterXWithinMargins,
    BMMASAttributeCenterYWithinMargins = 1 << NSLayoutAttributeCenterYWithinMargins,

#endif
    
};

/**
 *  Provides factory methods for creating MASConstraints.
 *  Constraints are collected until they are ready to be installed
 *
 */
@interface BMMASConstraintMaker : NSObject

/**
 *	The following properties return a new MASViewConstraint
 *  with the first item set to the makers associated view and the appropriate MASViewAttribute
 */
@property (nonatomic, strong, readonly) BMMASConstraint *left;
@property (nonatomic, strong, readonly) BMMASConstraint *top;
@property (nonatomic, strong, readonly) BMMASConstraint *right;
@property (nonatomic, strong, readonly) BMMASConstraint *bottom;
@property (nonatomic, strong, readonly) BMMASConstraint *leading;
@property (nonatomic, strong, readonly) BMMASConstraint *trailing;
@property (nonatomic, strong, readonly) BMMASConstraint *width;
@property (nonatomic, strong, readonly) BMMASConstraint *height;
@property (nonatomic, strong, readonly) BMMASConstraint *centerX;
@property (nonatomic, strong, readonly) BMMASConstraint *centerY;
@property (nonatomic, strong, readonly) BMMASConstraint *baseline;

@property (nonatomic, strong, readonly) BMMASConstraint *firstBaseline;
@property (nonatomic, strong, readonly) BMMASConstraint *lastBaseline;

#if TARGET_OS_IPHONE || TARGET_OS_TV

@property (nonatomic, strong, readonly) BMMASConstraint *leftMargin;
@property (nonatomic, strong, readonly) BMMASConstraint *rightMargin;
@property (nonatomic, strong, readonly) BMMASConstraint *topMargin;
@property (nonatomic, strong, readonly) BMMASConstraint *bottomMargin;
@property (nonatomic, strong, readonly) BMMASConstraint *leadingMargin;
@property (nonatomic, strong, readonly) BMMASConstraint *trailingMargin;
@property (nonatomic, strong, readonly) BMMASConstraint *centerXWithinMargins;
@property (nonatomic, strong, readonly) BMMASConstraint *centerYWithinMargins;

#endif

/**
 *  Returns a block which creates a new MASCompositeConstraint with the first item set
 *  to the makers associated view and children corresponding to the set bits in the
 *  MASAttribute parameter. Combine multiple attributes via binary-or.
 */
@property (nonatomic, strong, readonly) BMMASConstraint *(^attributes)(BMMASAttribute attrs);

/**
 *	Creates a MASCompositeConstraint with type MASCompositeConstraintTypeEdges
 *  which generates the appropriate MASViewConstraint children (top, left, bottom, right)
 *  with the first item set to the makers associated view
 */
@property (nonatomic, strong, readonly) BMMASConstraint *edges;

/**
 *	Creates a MASCompositeConstraint with type MASCompositeConstraintTypeSize
 *  which generates the appropriate MASViewConstraint children (width, height)
 *  with the first item set to the makers associated view
 */
@property (nonatomic, strong, readonly) BMMASConstraint *size;

/**
 *	Creates a MASCompositeConstraint with type MASCompositeConstraintTypeCenter
 *  which generates the appropriate MASViewConstraint children (centerX, centerY)
 *  with the first item set to the makers associated view
 */
@property (nonatomic, strong, readonly) BMMASConstraint *center;

/**
 *  Whether or not to check for an existing constraint instead of adding constraint
 */
@property (nonatomic, assign) BOOL updateExisting;

/**
 *  Whether or not to remove existing constraints prior to installing
 */
@property (nonatomic, assign) BOOL removeExisting;

/**
 *	initialises the maker with a default view
 *
 *	@param	view	any MASConstraint are created with this view as the first item
 *
 *	@return	a new MASConstraintMaker
 */
- (id)initWithView:(BMMAS_VIEW *)view;

/**
 *	Calls install method on any MASConstraints which have been created by this maker
 *
 *	@return	an array of all the installed MASConstraints
 */
- (NSArray *)install;

- (BMMASConstraint * (^)(dispatch_block_t))group;

@end
