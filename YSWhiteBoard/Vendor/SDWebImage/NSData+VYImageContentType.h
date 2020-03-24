/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Fabrice Aneche
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "VYSDWebImageCompat.h"

typedef NS_ENUM(NSInteger, VYSDImageFormat) {
    VYSDImageFormatUndefined = -1,
    VYSDImageFormatJPEG = 0,
    VYSDImageFormatPNG,
    VYSDImageFormatGIF,
    VYSDImageFormatTIFF,
    VYSDImageFormatWebP
};

@interface NSData (VYImageContentType)

/**
 *  Return image format
 *
 *  @param data the input image data
 *
 *  @return the image format as `SDImageFormat` (enum)
 */
+ (VYSDImageFormat)VYsd_imageFormatForImageData:(nullable NSData *)data;

@end
