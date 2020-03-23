//
//  Logger.m
//  Rhinobird-Camera-IOS
//
//  Created by Alvaro Gil on 7/15/15.
//  Copyright (c) 2015 Rhinobird. All rights reserved.
//

#import "YSWBLogger.h"

@implementation YSWBLogger

- (instancetype)init
{
    if (self = [super init])
    {
        // By default log everthing.
        self.logModes = YSWBLOG_MODE_DEBUG_MASK | YSWBLOG_MODE_INFO_MASK | YSWBLOG_MODE_WARNING_MASK | YSWBLOG_MODE_ERROR_MASK;
        
        // Prefixes for different log modes
        self.prefixes = [NSMutableArray arrayWithCapacity:5];
        [self.prefixes insertObject:@"Unknown" atIndex:0];
        [self.prefixes insertObject:@"💙DEBUG💙"    atIndex:YSWBLOG_MODE_DEBUG];
        [self.prefixes insertObject:@"💚INFO💚"     atIndex:YSWBLOG_MODE_INFO];
        [self.prefixes insertObject:@"💛WARN💛"     atIndex:YSWBLOG_MODE_WARNING];
        [self.prefixes insertObject:@"💔ERROR💔"    atIndex:YSWBLOG_MODE_ERROR];
    }
    
    return self;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)log:(YSWBLOG_MODE)mode file:(NSString *)file line:(NSNumber *)line format:(NSString *)format args:(va_list)args
{
    if (!(self.logModes & (1 << mode)))
    {
        return;
    }
    
    NSString *source;
    NSString *message;
    NSString *output;
    
    message = [NSString stringWithFormat:@"\n%@: %@", [self.prefixes objectAtIndex:mode], format];
    
    if (file && line)
    {
        source = [NSString stringWithFormat:@"\nSource: %@:%@", file, line];
    }
    else
    {
        source = @"";
    }
    
    output = [NSString stringWithFormat:@"%@%@\n\n", source, message];
    
    NSLogv(output, args);
}

- (void)log:(YSWBLOG_MODE)mode file:(NSString *)file line:(NSNumber *)line format:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    [self log:mode file:file line:line format:format args:args];
    va_end(args);
}

- (void)logWithModesOverride:(YSWBLOG_MODE_MASK)overrideModes mode:(YSWBLOG_MODE)mode file:(NSString *)file line:(NSNumber *)line
                      format:(NSString *)format args:(va_list)args
{
    YSWBLOG_MODE_MASK previousMask = self.logModes;
    self.logModes = overrideModes;
    [self log:mode file:file line:line format:format args:args];
    self.logModes = previousMask;
}

@end
