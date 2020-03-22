/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Fabrice Aneche
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "BMSDWebImageCompat.h"

typedef NS_ENUM(NSInteger, BMSDImageFormat) {
    BMSDImageFormatUndefined = -1,
    BMSDImageFormatJPEG = 0,
    BMSDImageFormatPNG,
    BMSDImageFormatGIF,
    BMSDImageFormatTIFF,
    BMSDImageFormatWebP
};

@interface NSData (BMImageContentType)

/**
 *  Return image format
 *
 *  @param data the input image data
 *
 *  @return the image format as `SDImageFormat` (enum)
 */
+ (BMSDImageFormat)bm_imageFormatForImageData:(nullable NSData *)data;

@end
