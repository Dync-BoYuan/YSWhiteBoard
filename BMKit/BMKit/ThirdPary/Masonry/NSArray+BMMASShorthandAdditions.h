//
//  NSArray+MASShorthandAdditions.h
//  Masonry
//
//  Created by Jonas Budelmann on 22/07/13.
//  Copyright (c) 2013 Jonas Budelmann. All rights reserved.
//

#import "NSArray+BMMASAdditions.h"

#ifdef MAS_SHORTHAND

/**
 *	Shorthand array additions without the 'mas_' prefixes,
 *  only enabled if MAS_SHORTHAND is defined
 */
@interface NSArray (BMMASShorthandAdditions)

- (NSArray *)bmmakeConstraints:(void(^)(BMMASConstraintMaker *make))block;
- (NSArray *)bmupdateConstraints:(void(^)(BMMASConstraintMaker *make))block;
- (NSArray *)bmremakeConstraints:(void(^)(BMMASConstraintMaker *make))block;

@end

@implementation NSArray (BMMASShorthandAdditions)

- (NSArray *)bmmakeConstraints:(void(^)(BMMASConstraintMaker *))block {
    return [self mas_makeConstraints:block];
}

- (NSArray *)bmupdateConstraints:(void(^)(BMMASConstraintMaker *))block {
    return [self mas_updateConstraints:block];
}

- (NSArray *)bmremakeConstraints:(void(^)(BMMASConstraintMaker *))block {
    return [self mas_remakeConstraints:block];
}

@end

#endif
