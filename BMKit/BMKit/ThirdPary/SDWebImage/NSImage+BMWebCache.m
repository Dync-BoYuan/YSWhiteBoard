/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "NSImage+BMWebCache.h"

#if SD_MAC

@implementation NSImage (BMWebCache)

- (CGImageRef)bm_CGImage {
    NSRect imageRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    CGImageRef cgImage = [self CGImageForProposedRect:&imageRect context:NULL hints:nil];
    return cgImage;
}

- (NSArray<NSImage *> *)bm_images {
    return nil;
}

- (BOOL)bm_isGIF {
    return NO;
}

@end

#endif

