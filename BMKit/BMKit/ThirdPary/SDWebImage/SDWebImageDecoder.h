/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) james <https://github.com/mystcolor>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "BMSDWebImageCompat.h"

@interface UIImage (BMForceDecode)

+ (nullable UIImage *)bm_decodedImageWithImage:(nullable UIImage *)image;

+ (nullable UIImage *)bm_decodedAndScaledDownImageWithImage:(nullable UIImage *)image;

@end
