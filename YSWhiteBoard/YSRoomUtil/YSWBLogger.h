//
//  Logger.h
//
//  Created by Alvaro Gil on 7/15.
//  LICENSE: nil
//

#import <Foundation/Foundation.h>

//#define YSWBLOG_MODES YSWBLOG_MODE_DEBUG_MASK

#ifdef DEBUG
#define WB_DEBUG(f, ...) { \
logThis(YSWBLOG_MODE_DEBUG, @(__FILE__), @(__LINE__), f, ##__VA_ARGS__); \
}
#else
#define WB_DEBUG(f, ...) {}
#endif

#define WB_ERROR(f, ...) { \
logThis(YSWBLOG_MODE_ERROR, @(__FILE__), @(__LINE__), f, ##__VA_ARGS__); \
}

#define WB_WARNING(f, ...) { \
logThis(YSWBLOG_MODE_WARNING, @(__FILE__), @(__LINE__), f, ##__VA_ARGS__); \
}

#define WB_INFO(f, ...) { \
logThis(YSWBLOG_MODE_INFO, nil, nil, f, ##__VA_ARGS__); \
}

NS_ASSUME_NONNULL_BEGIN

@class YSWBLogger;

typedef enum {
    YSWBLOG_MODE_UNKNOWN,
    YSWBLOG_MODE_DEBUG,
    YSWBLOG_MODE_INFO,
    YSWBLOG_MODE_WARNING,
    YSWBLOG_MODE_ERROR
} YSWBLOG_MODE;

typedef NS_OPTIONS(NSUInteger, YSWBLOG_MODE_MASK) {
    YSWBLOG_MODE_DEBUG_MASK         = 1 << YSWBLOG_MODE_DEBUG,
    YSWBLOG_MODE_INFO_MASK          = 1 << YSWBLOG_MODE_INFO,
    YSWBLOG_MODE_WARNING_MASK       = 1 << YSWBLOG_MODE_WARNING,
    YSWBLOG_MODE_ERROR_MASK         = 1 << YSWBLOG_MODE_ERROR
};


@interface YSWBLogger : NSObject

///-----------------------------------
/// @name Initializers
///-----------------------------------

- (instancetype)init;
+ (instancetype)sharedInstance;

///-----------------------------------
/// @name Properties
///-----------------------------------

@property YSWBLOG_MODE_MASK logModes;
@property NSMutableArray *prefixes;

///-----------------------------------
/// @name Methods
///-----------------------------------

- (void)log:(YSWBLOG_MODE)mode file:(NSString *)file line:(NSNumber *)line format:(NSString *)format, ...;
- (void)log:(YSWBLOG_MODE)mode file:(NSString *)file line:(NSNumber *)line format:(NSString *)format args:(va_list)args;
- (void)logWithModesOverride:(YSWBLOG_MODE_MASK)overrideModes mode:(YSWBLOG_MODE)mode file:(NSString *)file line:(NSNumber *)line
                      format:(NSString *)format args:(va_list)args;

@end

FOUNDATION_STATIC_INLINE void logThis(YSWBLOG_MODE mode, NSString *file, NSNumber *line, NSString *format, ...) {
    va_list args;
    va_start(args, format);
#ifdef YSWBLOG_MODES
    YSWBLOG_MODE_MASK overrideModes = YSWBLOG_MODES;
    [[YSWBLogger sharedInstance] logWithModesOverride:overrideModes mode:mode file:file line:line format:format args:args];
#else
    [[YSWBLogger sharedInstance] log:mode file:file line:line format:format args:args];
#endif
    va_end(args);
}

NS_ASSUME_NONNULL_END
