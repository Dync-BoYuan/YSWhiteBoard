//
//  NSURLRequest+YSWhiteBoard.h
//  YSWhiteBoard
//
//  Created by jiang deng on 2019/12/17.
//  Copyright © 2019 YS. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLRequest (YSWhiteBoard)

- (NSURLRequest *)yshttpdns_getPostRequestIncludeBody;
- (NSMutableURLRequest *)yshttpdns_getMutablePostRequestIncludeBody;

@end

NS_ASSUME_NONNULL_END
