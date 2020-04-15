//
//  NSURLRequest+YSWhiteBoard.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2019/12/17.
//  Copyright © 2019 YS. All rights reserved.
//

#import "NSURLRequest+YSWhiteBoard.h"

@implementation NSURLRequest (YSWhiteBoard)

- (NSURLRequest *)yshttpdns_getPostRequestIncludeBody
{
    return [[self yshttpdns_getMutablePostRequestIncludeBody] copy];
}

- (NSMutableURLRequest *)yshttpdns_getMutablePostRequestIncludeBody
{
    NSMutableURLRequest * req = [self mutableCopy];
    if ([self.HTTPMethod isEqualToString:@"POST"])
    {
        if (!self.HTTPBody)
        {
            NSInteger maxLength = 1024;
            uint8_t d[maxLength];
            NSInputStream *stream = self.HTTPBodyStream;
            NSMutableData *data = [[NSMutableData alloc] init];
            [stream open];
            BOOL endOfStreamReached = NO;
            //不能用 [stream hasBytesAvailable]) 判断，处理图片文件的时候这里的[stream hasBytesAvailable]会始终返回YES，导致在while里面死循环。
            while (!endOfStreamReached)
            {
                NSInteger bytesRead = [stream read:d maxLength:maxLength];
                if (bytesRead == 0)
                { //文件读取到最后
                    endOfStreamReached = YES;
                }
                else if (bytesRead == -1)
                { //文件读取错误
                    endOfStreamReached = YES;
                }
                else if (stream.streamError == nil)
                {
                    [data appendBytes:(void *)d length:bytesRead];
                }
            }
            req.HTTPBody = [data copy];
            [stream close];
        }
    }
    return req;
}
@end
