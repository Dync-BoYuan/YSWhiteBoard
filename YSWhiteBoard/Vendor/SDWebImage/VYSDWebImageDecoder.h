/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) james <https://github.com/mystcolor>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "VYSDWebImageCompat.h"

@interface UIImage (VYForceDecode)

+ (nullable UIImage *)VYdecodedImageWithImage:(nullable UIImage *)image;

+ (nullable UIImage *)VYdecodedAndScaledDownImageWithImage:(nullable UIImage *)image;

@end
