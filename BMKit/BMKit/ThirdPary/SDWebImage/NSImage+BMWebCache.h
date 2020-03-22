/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "BMSDWebImageCompat.h"

#if SD_MAC

#import <Cocoa/Cocoa.h>

@interface NSImage (BMWebCache)

- (CGImageRef)bm_CGImage;
- (NSArray<NSImage *> *)bm_images;
- (BOOL)bm_isGIF;

@end

#endif
