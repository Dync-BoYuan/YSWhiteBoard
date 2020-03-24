/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "VYSDWebImageCompat.h"

#if SD_MAC

#import <Cocoa/Cocoa.h>

@interface NSImage (VYWebCache)

- (CGImageRef)VYCGImage;
- (NSArray<NSImage *> *)VYimages;
- (BOOL)VYisGIF;

@end

#endif
