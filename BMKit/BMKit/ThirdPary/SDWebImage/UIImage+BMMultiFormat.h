/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "BMSDWebImageCompat.h"
#import "NSData+BMImageContentType.h"

@interface UIImage (BMMultiFormat)

+ (nullable UIImage *)bm_imageWithData:(nullable NSData *)data;
- (nullable NSData *)bm_imageData;
- (nullable NSData *)bm_imageDataAsFormat:(BMSDImageFormat)imageFormat;

@end
