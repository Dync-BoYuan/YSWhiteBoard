//
//  BMKit.h
//  BMKit
//
//  Created by jiang deng on 2019/11/5.
//  Copyright © 2019 DennisDeng. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for BMKit.
FOUNDATION_EXPORT double BMKitVersionNumber;

//! Project version string for BMKit.
FOUNDATION_EXPORT const unsigned char BMKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <BMKit/PublicHeader.h>

// 编码解码
#define BMBasekit_Category_Encrypt  1

#if __has_include(<BMKit/BMkitMacros.h>)
#import <BMKit/BMkitMacros.h>
#else
#import "BMkitMacros.h"
#endif

#import "BMClassCategory.h"
#import "BMUICategory.h"

#import "BMKitThird.h"

#import "BMTools.h"

#import "BMApp.h"
