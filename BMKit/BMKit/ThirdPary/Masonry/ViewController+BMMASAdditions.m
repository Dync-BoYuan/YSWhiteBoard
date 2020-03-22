//
//  UIViewController+MASAdditions.m
//  Masonry
//
//  Created by Craig Siemens on 2015-06-23.
//
//

#import "ViewController+BMMASAdditions.h"

#ifdef BMMAS_VIEW_CONTROLLER

@implementation BMMAS_VIEW_CONTROLLER (BMMASAdditions)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (BMMASViewAttribute *)bmmas_topLayoutGuide {
    return [[BMMASViewAttribute alloc] initWithView:self.view item:self.topLayoutGuide layoutAttribute:NSLayoutAttributeBottom];
}
- (BMMASViewAttribute *)bmmas_topLayoutGuideTop {
    return [[BMMASViewAttribute alloc] initWithView:self.view item:self.topLayoutGuide layoutAttribute:NSLayoutAttributeTop];
}
- (BMMASViewAttribute *)bmmas_topLayoutGuideBottom {
    return [[BMMASViewAttribute alloc] initWithView:self.view item:self.topLayoutGuide layoutAttribute:NSLayoutAttributeBottom];
}

- (BMMASViewAttribute *)bmmas_bottomLayoutGuide {
    return [[BMMASViewAttribute alloc] initWithView:self.view item:self.bottomLayoutGuide layoutAttribute:NSLayoutAttributeTop];
}
- (BMMASViewAttribute *)bmmas_bottomLayoutGuideTop {
    return [[BMMASViewAttribute alloc] initWithView:self.view item:self.bottomLayoutGuide layoutAttribute:NSLayoutAttributeTop];
}
- (BMMASViewAttribute *)bmmas_bottomLayoutGuideBottom {
    return [[BMMASViewAttribute alloc] initWithView:self.view item:self.bottomLayoutGuide layoutAttribute:NSLayoutAttributeBottom];
}

#pragma clang diagnostic pop

@end

#endif
