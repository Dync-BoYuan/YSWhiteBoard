//
//  YSWhiteBordNSURLProtocol.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2019/12/9.
//  Copyright © 2019 YS. All rights reserved.
//

#import "YSWhiteBordNSURLProtocol.h"
#import "YSWhiteBordHttpDNSUtil.h"
#import "NSURLRequest+YSWhiteBoard.h"

#import "YSWhiteBoardDefines.h"
#import <YSRoomSDK/YSRoomSDK.h>

static NSString * const YSWhiteBordNSURLProtocolKey = @"yswhitebord_protocol_key";

@interface YSWhiteBordNSURLProtocol()<NSURLSessionDataDelegate>

@property (nonatomic, strong, readwrite) NSString *hostIp;

@property (atomic, strong, readwrite) NSURLSessionDataTask *task;

@end

@implementation YSWhiteBordNSURLProtocol

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task
{
    NSURLRequest *request = task.currentRequest;
    return request == nil ? NO : [self canInitWithRequest:request];
}

+ (BOOL)isMedia:(NSString *)filetype
{
    filetype = [filetype lowercaseString];
    BOOL tIsMedia = NO;
    if ([filetype isEqualToString:@"mp3"]
        || [filetype isEqualToString:@"mp4"]
        || [filetype isEqualToString:@"webm"]
        || [filetype isEqualToString:@"ogg"]
        || [filetype isEqualToString:@"wav"])
    {
        tIsMedia = YES;
    }
    
    return tIsMedia;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([NSURLProtocol propertyForKey:YSWhiteBordNSURLProtocolKey inRequest:request])
    {
        return NO;
    }
    
    // 只处理http和https请求
    if (![request.URL.scheme isEqualToString:@"http"] &&
        ![request.URL.scheme isEqualToString:@"https"])
    {
        return NO;
    }
    
    NSURL *url = request.URL;
    NSString *host = url.host;
    NSString *hostHeader = [host stringByDeletingPathExtension];
    // 只处理白名单host
    if (
        [hostHeader isEqualToString:YSWhiteBoard_domain_ws_header] || [hostHeader isEqualToString:YSWhiteBoard_domain_demows_header]
#if YSWHITEBOARD_USEHTTPDNS_ADDALI
        || [hostHeader isEqualToString:YSWhiteBoard_domain_ali_header] || [hostHeader isEqualToString:YSWhiteBoard_domain_demoali_header]
#endif
        )
    {
        NSString *extension = request.URL.pathExtension;
        BOOL isMedia = [YSWhiteBordNSURLProtocol isMedia:extension];
        
        if (isMedia)
        {
            return NO;
        }
        
        return YES;
//        YSWhiteBordHttpDNSUtil *httpDNSUtil = [YSWhiteBordHttpDNSUtil sharedInstance];
//        NSString *ip = [httpDNSUtil getHttpDNSIpWithHost:host];
//        if (ip)
//        {
//            return YES;
//        }
//
//        return NO;
    }

    // 文件类型不作处理
//    NSString *contentType = [request valueForHTTPHeaderField:@"Content-Type"];
//    if (contentType && [contentType containsString:@"multipart/form-data"])
//    {
//        return NO;
//    }
    
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return [request mutableCopy];
}

- (NSMutableURLRequest *)replaceHost
{
    if ([self.request.URL host].length == 0)
    {
        return [self.request mutableCopy];
    }
    
    NSMutableURLRequest *mutableReqeust = [self.request yshttpdns_getMutablePostRequestIncludeBody];
    
    NSURL *url = mutableReqeust.URL;
    NSString *host = url.host;
    //NSString *hostHeader = [host stringByDeletingPathExtension];
    //NSString *newHost = [hostHeader stringByAppendingPathExtension:@"com"];

    YSWhiteBordHttpDNSUtil *httpDNSUtil = [YSWhiteBordHttpDNSUtil sharedInstance];
    NSString *ip = [httpDNSUtil getHttpDNSIpWithHost:host];
    if (ip)
    {
        // 替换host为ip
        NSString *originalUrl = url.absoluteString;
        NSRange hostFirstRange = [originalUrl rangeOfString: host];
        if (NSNotFound != hostFirstRange.location)
        {
            NSString* newUrl = [originalUrl stringByReplacingCharactersInRange:hostFirstRange withString:ip];
            mutableReqeust.URL = [NSURL URLWithString:newUrl];
            // 设置请求HOST字段
            [mutableReqeust setValue:url.host forHTTPHeaderField:@"host"];
            [mutableReqeust setValue:ip forHTTPHeaderField:@"hostip"];
        }
    }

    NSDictionary *queryDictionary = [url bm_queryDictionary];
    if ([queryDictionary bm_containsObjectForKey:@"fileid"])
    {
        NSString *fileId = [queryDictionary bm_stringForKey:@"fileid"];
        NSLog(@"=================fileId: %@  ip: %@  host: %@", fileId, ip, host);
        NSString *log = [NSString stringWithFormat:@"网页课件替换ip fileId_%@  ip_%@  host_%@", fileId, ip, host];
        [[YSRoomInterface instance] serverLog:log];
    }

    return mutableReqeust;
}

- (void)startLoading
{
    [NSURLProtocol setProperty:@YES forKey:YSWhiteBordNSURLProtocolKey inRequest:(NSMutableURLRequest *)(self.request)];

    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    operationQueue.maxConcurrentOperationCount = 1;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:operationQueue];

    NSMutableURLRequest *mutableReqeust = [self replaceHost];
    //NSMutableURLRequest *mutableReqeust = [self.request mutableCopy];
    self.task = [session dataTaskWithRequest:mutableReqeust];

    [self.task resume];
}

- (void)stopLoading
{
    if (self.task != nil)
    {
        [self.task cancel];
        self.task = nil;
    }
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error)
    {
//        NSLog(@"=======================================");
//        NSLog(@"%@", error);
//        NSLog(@"=======================================");
//        NSLog(@"%@", self.request.allHTTPHeaderFields);

        NSURL *url = self.request.URL;
        NSString *host = [[self.request allHTTPHeaderFields] objectForKey:@"host"];
        NSDictionary *queryDictionary = [url bm_queryDictionary];
        if ([queryDictionary bm_containsObjectForKey:@"fileid"])
        {
            NSString *fileId = [queryDictionary bm_stringForKey:@"fileid"];
            NSLog(@"=================fileId: %@  host: %@", fileId, host);
            NSString *log = [NSString stringWithFormat:@"网页课件获取失败 fileId_%@  host_%@", fileId, host];
            [[YSRoomInterface instance] serverLog:log];
        }

        [self.client URLProtocol:self didFailWithError:error];
    }
    else
    {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
#if 1
    if (!challenge)
    {
        return;
    }

    NSString* host = [[task.originalRequest allHTTPHeaderFields] objectForKey:@"host"];

    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;

    // 证书验证前置处理
//    NSString *domain = challenge.protectionSpace.host; // 获取当前请求的 host（域名或者 IP），假设此时为：123.206.23.22
//    NSString *testHostIP = [[self.request allHTTPHeaderFields] objectForKey:@"hostip"];;
    // 此时服务端返回的证书里的 CN 字段（即证书颁发的域名）与上述 host 可能不一致，
    // 因为上述 host 在发请求前已经被我们替换为 IP，所以校验证书时会发现域名不一致而无法通过，导致请求被取消掉，
    // 所以，这里在校验证书前做一下替换处理。
//    if ([domain isEqualToString:testHostIP])
//    {
//        domain = host; // 替换为对应域名：kangzubin.com
//    }

    if (!host)
    {
        host = self.request.URL.host;
    }

    // 以下逻辑与 AFNetworking -> AFURLSessionManager.m 里的代码一致
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        if ([self evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:host])
        {
            // 上述 `evaluateServerTrust:forDomain:` 方法用于验证 SSL 握手过程中服务端返回的证书是否可信任，
            // 以及请求的 URL 中的域名与证书里声明的的 CN 字段是否一致。
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            if (credential)
            {
                disposition = NSURLSessionAuthChallengeUseCredential;
            }
            else
            {
                disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
        }
        else
        {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }
    else
    {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }

    if (completionHandler)
    {
//        disposition = NSURLSessionAuthChallengeUseCredential;
//        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];

        if (disposition != NSURLSessionAuthChallengeUseCredential)
        {
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
            {
                SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
                CFDataRef exceptions    = SecTrustCopyExceptions(serverTrust);
                SecTrustSetExceptions(serverTrust, exceptions);
                CFRelease(exceptions);
                completionHandler(NSURLSessionAuthChallengeUseCredential,
                                  [NSURLCredential credentialForTrust:serverTrust]);
            }
        }
        else
        {
            completionHandler(disposition, credential);
        }
    }
#else
    //判断服务器返回的证书类型, 是否是服务器信任
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        //强制信任
        NSURLCredential *credential = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
#endif
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                  forDomain:(NSString *)domain
{
    /*
     * 创建证书校验策略
     */
    NSMutableArray *policies = [NSMutableArray array];
    if (domain)
    {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
    }
    else
    {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateBasicX509()];
    }
    /*
     * 绑定校验策略到服务端的证书上
     */
    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);
    /*
     * 评估当前serverTrust是否可信任，
     * 官方建议在result = kSecTrustResultUnspecified 或 kSecTrustResultProceed
     * 的情况下serverTrust可以被验证通过，https://developer.apple.com/library/ios/technotes/tn2232/_index.html
     * 关于SecTrustResultType的详细信息请参考SecTrust.h
     */
    SecTrustResultType result;
    SecTrustEvaluate(serverTrust, &result);
    return (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
}

@end
