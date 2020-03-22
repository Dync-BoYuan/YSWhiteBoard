//
//  NSString+Emoji.h
//  BMBaseKit
//
//  Created by jiang deng on 2019/7/23.
//Copyright © 2019 BM. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BMEmojizedStringKey         @"emojizedString"
#define BMEmojiRangesKey            @"emojiRanges"
#define BMEmojiLengthChangesKey     @"emojiLengthChanges"

@interface NSString (Emoji)

+ (NSString *)encodeEmojiStringWithString:(NSString *)text;
- (NSString *)encodeEmojiString;

+ (NSDictionary *)decodeEmojiStringWithString:(NSString *)text;
- (NSDictionary *)decodeEmojiString;


@end
