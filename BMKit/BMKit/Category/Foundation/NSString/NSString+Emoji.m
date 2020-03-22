//
//  NSString+Emoji.m
//  BMBaseKit
//
//  Created by jiang deng on 2019/7/23.
//Copyright © 2019 BM. All rights reserved.
//

#import "NSString+Emoji.h"
#import "emojiCodes.h"

BOOL NSRangeIntersectsRange(NSRange range1, NSRange range2)
{
    if (range1.location > range2.location + range2.length) return NO;
    if (range2.location > range1.location + range1.length) return NO;
    return YES;
}

@implementation NSString (Emoji)

+ (NSDictionary *)emojiAliases
{
    static NSDictionary *_emojiAliases;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _emojiAliases = EMOJI_CODE;
    });
    return _emojiAliases;
}

// emoji转字符
+ (NSString *)encodeEmojiStringWithString:(NSString *)text
{
    if (text.length)
    {
        __block NSMutableString *resultText = [NSMutableString stringWithString:text];
        [self.emojiAliases enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *code = obj;
            [resultText replaceOccurrencesOfString:code withString:key options:NSLiteralSearch range:NSMakeRange(0, resultText.length)];
        }];
        
        return resultText;
    }
    
    return text;
}

- (NSString *)encodeEmojiString
{
    return [NSString encodeEmojiStringWithString:self];
}

// 字符转emoji
+ (NSDictionary *)decodeEmojiStringWithString:(NSString *)text
{
    static dispatch_once_t onceToken;
    static NSRegularExpression *regex = nil;
    static dispatch_once_t dDetector = 0;
    static NSDataDetector *urlDetector = nil;
    
    NSMutableArray *matchingRanges = [NSMutableArray new];
    NSMutableArray *matchingLengthChanges = [NSMutableArray new];
    
    dispatch_once(&onceToken, ^{
        regex = [[NSRegularExpression alloc] initWithPattern:@"(:[a-z0-9-+_]+:)" options:NSRegularExpressionCaseInsensitive error:NULL];
    });
    
    dispatch_once(&dDetector, ^{
        urlDetector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:nil];
    });
    
    __block NSString *resultText = [NSString stringWithString:text];
    NSRange matchingRange = NSMakeRange(0, [resultText length]);
    NSArray<NSTextCheckingResult *> *urlMatches = [urlDetector matchesInString:text options:NSMatchingReportCompletion range:matchingRange];
    [regex enumerateMatchesInString:resultText options:NSMatchingReportCompletion range:matchingRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if ( result &&
            ([result resultType] == NSTextCheckingTypeRegularExpression) &&
            !(flags & NSMatchingInternalError) )
        {
            NSRange range = result.range;
            if (range.location != NSNotFound)
            {
                BOOL rangesIntersects = NO;
                for (NSTextCheckingResult *urlMatch in urlMatches)
                {
                    rangesIntersects = NSRangeIntersectsRange(urlMatch.range, range);
                    if (rangesIntersects)
                    {
                        break;
                    }
                }
                
                NSString *code = [text substringWithRange:range];
                NSString *unicode = self.emojiAliases[code];
               if (unicode && !rangesIntersects)
                {
                    resultText = [resultText stringByReplacingOccurrencesOfString:code withString:unicode];
                    [matchingRanges addObject:[NSValue valueWithRange: range]];
                    //range.length with be the number of characters reduced
                    range.length -= [unicode length];
                    [matchingLengthChanges addObject:[NSValue valueWithRange: range]];
                }
            }
        }
    }];
    
    return @{BMEmojizedStringKey : resultText, BMEmojiRangesKey : matchingRanges, BMEmojiLengthChangesKey : matchingLengthChanges};
}

- (NSDictionary *)decodeEmojiString
{
    return [NSString decodeEmojiStringWithString:self];
}

@end
