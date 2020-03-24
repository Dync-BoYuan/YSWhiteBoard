/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Fabrice Aneche
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "NSData+VYImageContentType.h"


@implementation NSData (VYImageContentType)

+ (VYSDImageFormat)VYsd_imageFormatForImageData:(nullable NSData *)data {
    if (!data) {
        return VYSDImageFormatUndefined;
    }
    
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return VYSDImageFormatJPEG;
        case 0x89:
            return VYSDImageFormatPNG;
        case 0x47:
            return VYSDImageFormatGIF;
        case 0x49:
        case 0x4D:
            return VYSDImageFormatTIFF;
        case 0x52:
            // R as RIFF for WEBP
            if (data.length < 12) {
                return VYSDImageFormatUndefined;
            }
            
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                return VYSDImageFormatWebP;
            }
    }
    return VYSDImageFormatUndefined;
}

@end
