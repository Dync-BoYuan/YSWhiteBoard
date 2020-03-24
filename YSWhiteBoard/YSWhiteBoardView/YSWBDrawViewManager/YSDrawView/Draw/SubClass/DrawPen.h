//
//  DrawPen.h
//  WhiteBoard
//
//  Created by macmini on 14/11/7.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "DrawBase.h"
#ifdef __cplusplus
#include <list>
#endif
@interface DrawPen : DrawBase
#ifdef __cplusplus
@property (nonatomic) std::list<CGPoint> pointList;
@property (nonatomic, assign) BOOL isErase;
#endif
+ (DrawPen *)deserializeData:(NSDictionary *)data;
- (NSDictionary *)serializedData;

@end
