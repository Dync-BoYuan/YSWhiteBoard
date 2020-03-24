/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "VYSDWebImageCompat.h"
#import "NSData+VYImageContentType.h"

@interface UIImage (VYMultiFormat)

+ (nullable UIImage *)VYsd_imageWithData:(nullable NSData *)data;
- (nullable NSData *)VYsd_imageData;
- (nullable NSData *)VYsd_imageDataAsFormat:(VYSDImageFormat)imageFormat;

@end
