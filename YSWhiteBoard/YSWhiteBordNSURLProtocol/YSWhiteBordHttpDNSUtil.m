//
//  YSWhiteBordHttpDNSUtil.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2019/12/11.
//  Copyright © 2019 YS. All rights reserved.
//

#import "YSWhiteBordHttpDNSUtil.h"
#import <YSRoomSDK/YSRoomSDK.h>
#import "YSWhiteBoardDefines.h"
#if YSWHITEBOARD_USEHTTPDNS_ADDALI
#import <AlicloudHttpDNS/AlicloudHttpDNS.h>
#endif



#define WsHttpDNSIP_KEY     @"ysWhiteBoard_wsHttpDNSIP"

@interface YSWhiteBordHttpDNSUtil ()
// <
//    HttpDNSDegradationDelegate
//>

@end

@implementation YSWhiteBordHttpDNSUtil

static YSWhiteBordHttpDNSUtil *httpDNSUtilsharedInstance = nil;

+ (instancetype)sharedInstance
{
    if (httpDNSUtilsharedInstance)
    {
        return httpDNSUtilsharedInstance;
    }
    else
    {
        httpDNSUtilsharedInstance = [[YSWhiteBordHttpDNSUtil alloc] init];
    }
    
    return httpDNSUtilsharedInstance;
}

+ (void)destroy
{
    if (httpDNSUtilsharedInstance)
    {
        [httpDNSUtilsharedInstance cancelGetHttpDNSIp];
    }
    
    httpDNSUtilsharedInstance = nil;
}

+ (NSDictionary *)convertWithData:(id)data
{
    NSDictionary *dataDic = nil;
    
    if ([data isKindOfClass:[NSString class]])
    {
        NSString *tDataString = [NSString stringWithFormat:@"%@", data];
        NSData *tJsData = [tDataString dataUsingEncoding:NSUTF8StringEncoding];
        if (tJsData)
        {
            dataDic = [NSJSONSerialization JSONObjectWithData:tJsData
                                                      options:NSJSONReadingMutableContainers
                                                        error:nil];
        }
    }
    else if ([data isKindOfClass:[NSDictionary class]])
    {
        dataDic = (NSDictionary *)data;
    }
    else if ([data isKindOfClass:[NSData class]])
    {
        NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dataDic = [YSWhiteBordHttpDNSUtil convertWithData:dataStr];
    }
    
    return dataDic;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
#if YSWHITEBOARD_USEHTTPDNS_ADDALI
        [self setupAliHttpDNS];
#endif
        
        [self clearwsip];

        [self setupWsHttpDNSWS];
        [self setupWsHttpDNSDemoWS];
    }
    
    return self;
}

#if YSWHITEBOARD_USEHTTPDNS_ADDALI
// 初始化阿里HttpDNS
- (void)setupAliHttpDNS
{
    // 初始化HTTPDNS 设置AccoutID
    HttpDnsService *httpdns = [[HttpDnsService alloc] initWithAccountID:YSWhiteBoard_HttpDnsService_AccountID];
    
    // 为HTTPDNS服务设置降级机制
    //[httpdns setDelegateForDegradationFilter:self];
    // 允许返回过期的IP
    //[httpdns setExpiredIPEnabled:YES];
    // 打开HTTPDNS Log，线上建议关闭
    //[httpdns setLogEnabled:YES];
    
    // 设置HTTPDNS域名解析请求类型(HTTP/HTTPS)，若不调用该接口，默认为HTTP请求 SDK内部HTTP请求基于CFNetwork实现，不受ATS限制。
    [httpdns setHTTPSRequestEnabled:YES];
    
    // 设置预解析域名列表
    NSArray *preResolveHosts = @[ YSWhiteBoard_domain_ali, YSWhiteBoard_domain_demoali];
    [httpdns setPreResolveHosts:preResolveHosts];
    
    // IP 优选功能，设置后会自动对IP进行测速排序，可以在调用 `-getIpByHost` 等接口时返回最优IP。
    NSDictionary *IPRankingDatasource = @{
                                          YSWhiteBoard_domain_ali : @80,
                                          YSWhiteBoard_domain_demoali : @80
                                          };
    [httpdns setIPRankingDatasource:IPRankingDatasource];
}
#endif

- (void)setupWsHttpDNSWS
{
    [self setupWsHttpDNSWithHost:YSWhiteBoard_domain_ws];
}

- (void)setupWsHttpDNSDemoWS
{
    [self setupWsHttpDNSWithHost:YSWhiteBoard_domain_demows];
}

// 初始化网宿HttpDNS
- (void)setupWsHttpDNSWithHost:(NSString *)host
{
// post请求有问题
//    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
//
//    [parameters setObject:host forKey:@"ws_domain"];
//    [parameters setObject:@"json" forKey:@"ws_ret_type"];
//        
//    [YSHttpClientRequest post:YSWhiteBoard_wshttpdnsurl parameters:parameters success:^(id  _Nonnull response, NSInteger statusCode) {
    
    NSString *urlstr = [NSString stringWithFormat:@"%@?ws_domain=%@&ws_ret_type=json", YSWhiteBoard_wshttpdnsurl, host];
    [YSHttpClientRequest get:urlstr success:^(id  _Nonnull response, NSInteger statusCode) {
    
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSDictionary *responseDic = [YSWhiteBordHttpDNSUtil convertWithData:response];
            if ([responseDic isKindOfClass:[NSDictionary class]])
            {
                NSString *msg = [responseDic objectForKey:@"msg"];
                if ([msg isEqualToString:@"Success"])
                {
                    NSDictionary *data = [responseDic objectForKey:@"data"];
                    NSDictionary *domain = [data objectForKey:host];
                    NSArray *ips = [domain objectForKey:@"ips"];
                    if (ips.count > 0)
                    {
                        NSString *ip = ips.firstObject;
                        if (ip.length > 0)
                        {
                            NSString *key = [NSString stringWithFormat:@"%@_%@", WsHttpDNSIP_KEY, host];
                            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                            [defaults setObject:ip forKey:key];
                            [defaults synchronize];
                            
                            NSNumber *countNumber = [domain objectForKey:@"ttl"];
                            NSTimeInterval expireCount = ceil(countNumber.doubleValue * 0.75f);
                            
                            if ([host isEqualToString:YSWhiteBoard_domain_ws])
                            {
                                [self performSelector:@selector(setupWsHttpDNSWS) withObject:nil afterDelay:expireCount];
                            }
                            else if ([host isEqualToString:YSWhiteBoard_domain_demows])
                            {
                                [self performSelector:@selector(setupWsHttpDNSDemoWS) withObject:nil afterDelay:expireCount];
                            }
                            
                            return;
                        }
                    }
                }
            }
            
            NSString *key = [NSString stringWithFormat:@"%@_%@", WsHttpDNSIP_KEY, host];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults removeObjectForKey:key];
            [defaults synchronize];

        });
        
    } failure:^(NSError * _Nonnull error, NSInteger statusCode) {
        
        NSString *key = [NSString stringWithFormat:@"%@_%@", WsHttpDNSIP_KEY, host];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:key];
        [defaults synchronize];
    }];
}

/// 获取host的ip地址
- (NSString *)getHttpDNSIpWithHost:(NSString *)host;
{
    NSString *ip = nil;
    if ([host isEqualToString:YSWhiteBoard_domain_ws] || [host isEqualToString:YSWhiteBoard_domain_demows])
    {
        // 网宿ip
        NSString *key = [NSString stringWithFormat:@"%@_%@", WsHttpDNSIP_KEY, host];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        ip = [defaults objectForKey:key];
        
        if (!ip)
        {
            // ip为nil是需要重新获取
            if ([host isEqualToString:YSWhiteBoard_domain_ws])
            {
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setupWsHttpDNSWS) object:nil];
                [self setupWsHttpDNSWS];
            }
            else if ([host isEqualToString:YSWhiteBoard_domain_demows])
            {
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setupWsHttpDNSDemoWS) object:nil];
                [self setupWsHttpDNSDemoWS];
            }
        }
    }
#if YSWHITEBOARD_USEHTTPDNS_ADDALI
    else
    if ([host isEqualToString:YSWhiteBoard_domain_ali] || [host isEqualToString:YSWhiteBoard_domain_demoali])
    {
        // 阿里ip
        HttpDnsService *httpdns = [HttpDnsService sharedInstance];
        ip = [httpdns getIpByHostAsync:host];
    }
#endif

    return ip;
}

- (void)cancelGetHttpDNSIp
{
    // 停止过期循环获取网宿ip
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setupWsHttpDNSWS) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setupWsHttpDNSDemoWS) object:nil];

    [self clearwsip];
    
    httpDNSUtilsharedInstance = nil;
}

// 清除网宿ip
- (void)clearwsip
{
    NSString *key = [NSString stringWithFormat:@"%@_%@", WsHttpDNSIP_KEY, YSWhiteBoard_domain_ws];
    NSString *demokey = [NSString stringWithFormat:@"%@_%@", WsHttpDNSIP_KEY, YSWhiteBoard_domain_demows];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:key];
    [defaults removeObjectForKey:demokey];
    [defaults synchronize];
}

#pragma mark - HttpDNSDegradationDelegate

#if 0
/// 降级过滤器，您可以自己定义HTTPDNS降级机制
- (BOOL)shouldDegradeHTTPDNS:(NSString *)hostName
{
    NSLog(@"Enters Degradation filter.");
    // 根据HTTPDNS使用说明，存在网络代理情况下需降级为Local DNS
    if ([NetworkManager configureProxies])
    {
        NSLog(@"Proxy was set. Degrade!");
        return YES;
    }
    
    // 假设您禁止"www.taobao.com"域名通过HTTPDNS进行解析
    if ([hostName isEqualToString:@"www.taobao.com"])
    {
        NSLog(@"The host is in blacklist. Degrade!");
        return YES;
    }
    
    return NO;
}
#endif

+ (NSString *)getIpUrlPathWithPath:(NSString *)path fileId:(NSString *)fileId currentPage:(NSUInteger)currentPage
{
    NSString *realPath = path;
#if YSWHITEBOARD_NORMALUSEHTTPDNS
    NSURL *url = [NSURL URLWithString:path];
    NSString *host = url.host;
//    NSString *hostHeader = [host stringByDeletingPathExtension];
//    NSString *newHost = [hostHeader stringByAppendingPathExtension:@"com"];

    YSWhiteBordHttpDNSUtil *httpDNSUtil = [YSWhiteBordHttpDNSUtil sharedInstance];
    NSString *ip = [httpDNSUtil getHttpDNSIpWithHost:host];
    if (ip)
    {
        // 替换host为ip
        NSString *originalUrl = url.absoluteString;
        NSRange hostFirstRange = [originalUrl rangeOfString: host];
        if (NSNotFound != hostFirstRange.location)
        {
            realPath = [originalUrl stringByReplacingCharactersInRange:hostFirstRange withString:ip];
        }
    }

//    NSDictionary *queryDictionary = [url bm_queryDictionary];
//    if ([queryDictionary bm_containsObjectForKey:@"fileid"])
    {
        NSLog(@"=================fileId: %@  ip: %@  host: %@  currentPage: %@", fileId, ip, host, @(currentPage));
        NSString *log = [NSString stringWithFormat:@"普通课件替换ip fileId_%@  ip_%@  path_%@  currentPage_%@", fileId, ip, path, @(currentPage)];
        [[YSRoomInterface instance] serverLog:log];
    }
#endif

    return realPath;
}


@end
