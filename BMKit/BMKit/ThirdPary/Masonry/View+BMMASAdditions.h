//
//  UIView+MASAdditions.h
//  Masonry
//
//  Created by Jonas Budelmann on 20/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import "BMMASUtilities.h"
#import "BMMASConstraintMaker.h"
#import "BMMASViewAttribute.h"

/**
 *	Provides constraint maker block
 *  and convience methods for creating MASViewAttribute which are view + NSLayoutAttribute pairs
 */
@interface BMMAS_VIEW (BMMASAdditions)

/**
 *	following properties return a new MASViewAttribute with current view and appropriate NSLayoutAttribute
 */
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_left;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_top;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_right;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_bottom;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_leading;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_trailing;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_width;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_height;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_centerX;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_centerY;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_baseline;
@property (nonatomic, strong, readonly) BMMASViewAttribute *(^bmmas_attribute)(NSLayoutAttribute attr);

@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_firstBaseline;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_lastBaseline;

#if TARGET_OS_IPHONE || TARGET_OS_TV

@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_leftMargin;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_rightMargin;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_topMargin;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_bottomMargin;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_leadingMargin;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_trailingMargin;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_centerXWithinMargins;
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_centerYWithinMargins;

@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_safeAreaLayoutGuide NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_safeAreaLayoutGuideLeading NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_safeAreaLayoutGuideTrailing NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_safeAreaLayoutGuideLeft NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_safeAreaLayoutGuideRight NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_safeAreaLayoutGuideTop NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_safeAreaLayoutGuideBottom NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_safeAreaLayoutGuideWidth NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_safeAreaLayoutGuideHeight NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_safeAreaLayoutGuideCenterX NS_AVAILABLE_IOS(11.0);
@property (nonatomic, strong, readonly) BMMASViewAttribute *bmmas_safeAreaLayoutGuideCenterY NS_AVAILABLE_IOS(11.0);

#endif

/**
 *	a key to associate with this view
 */
@property (nonatomic, strong) id bmmas_key;

/**
 *	Finds the closest common superview between this view and another view
 *
 *	@param	view	other view
 *
 *	@return	returns nil if common superview could not be found
 */
- (instancetype)bmmas_closestCommonSuperview:(BMMAS_VIEW *)view;

/**
 *  Creates a MASConstraintMaker with the callee view.
 *  Any constraints defined are added to the view or the appropriate superview once the block has finished executing
 *
 *  @param block scope within which you can build up the constraints which you wish to apply to the view.
 *
 *  @return Array of created MASConstraints
 */
- (NSArray *)bmmas_makeConstraints:(void(NS_NOESCAPE ^)(BMMASConstraintMaker *make))block;

/**
 *  Creates a MASConstraintMaker with the callee view.
 *  Any constraints defined are added to the view or the appropriate superview once the block has finished executing.
 *  If an existing constraint exists then it will be updated instead.
 *
 *  @param block scope within which you can build up the constraints which you wish to apply to the view.
 *
 *  @return Array of created/updated MASConstraints
 */
- (NSArray *)bmmas_updateConstraints:(void(NS_NOESCAPE ^)(BMMASConstraintMaker *make))block;

/**
 *  Creates a MASConstraintMaker with the callee view.
 *  Any constraints defined are added to the view or the appropriate superview once the block has finished executing.
 *  All constraints previously installed for the view will be removed.
 *
 *  @param block scope within which you can build up the constraints which you wish to apply to the view.
 *
 *  @return Array of created/updated MASConstraints
 */
- (NSArray *)bmmas_remakeConstraints:(void(NS_NOESCAPE ^)(BMMASConstraintMaker *make))block;

@end
