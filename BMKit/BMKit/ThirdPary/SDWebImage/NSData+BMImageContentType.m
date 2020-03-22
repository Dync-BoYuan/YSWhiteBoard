/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Fabrice Aneche
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "NSData+BMImageContentType.h"


@implementation NSData (BMImageContentType)

+ (BMSDImageFormat)bm_imageFormatForImageData:(nullable NSData *)data {
    if (!data) {
        return BMSDImageFormatUndefined;
    }
    
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return BMSDImageFormatJPEG;
        case 0x89:
            return BMSDImageFormatPNG;
        case 0x47:
            return BMSDImageFormatGIF;
        case 0x49:
        case 0x4D:
            return BMSDImageFormatTIFF;
        case 0x52:
            // R as RIFF for WEBP
            if (data.length < 12) {
                return BMSDImageFormatUndefined;
            }
            
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                return BMSDImageFormatWebP;
            }
    }
    return BMSDImageFormatUndefined;
}

@end
