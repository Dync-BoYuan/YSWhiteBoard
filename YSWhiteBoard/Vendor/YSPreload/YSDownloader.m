//
//  YSDownloader.m
//  Download
//
//  Created by ys on 2019/4/25.
//  Copyright © 2019 ys. All rights reserved.
//

#import "YSDownloader.h"

#import "SSZipArchive.h"

//sandbox/Documents                 :Documents目录
#define YSDocumentPath      NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject

//sandbox/tmp                       :tmp目录
#define YSTmpPath           NSTemporaryDirectory()

//sandbox/tmp/YSFile                :YSFile目录
#define YSFileDirectory     [YSTmpPath stringByAppendingPathComponent:@"YSFile"]

//sandbox/Documents/predownload     :下载完成保存路径
#define YSPreloadPath       [NSString stringWithFormat:@"%@/predownload",YSDocumentPath]

//sandbox/Documents/tmpdownload     :储存临时下载文件
#define YSPreloadTmpPath    [NSString stringWithFormat:@"%@/tmpdownload",YSDocumentPath]

#define YSHttpDNSIP         @"122.191.168.34"
#define YSDomain            @"ws.roadofcloud.com"

#define YSHttpDNSAvailable  NO

@implementation YSDownloader
{
    NSOutputStream *_stream;
    ysProgressBlock _block;
}

+ (instancetype)sharedInstance
{
    static YSDownloader *d;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        d = [[self alloc] init];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:YSFileDirectory isDirectory:nil]) {
            [[NSFileManager defaultManager] createFileAtPath:YSFileDirectory contents:nil attributes:nil];
        }
    });
    
    return d;
}

//清理文档
- (void)removeLastPreloadFile
{
    NSArray *preloadDirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:YSFileDirectory error:nil];
    [preloadDirs enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isEqualToString:self->_fileID]) {
            [[NSFileManager defaultManager] removeItemAtPath:[YSFileDirectory stringByAppendingPathComponent:obj] error:nil];
        }
    }];
    
    NSArray *preloadFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:YSPreloadPath error:nil];
    [preloadFiles enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isEqualToString:self->_fileID]) {
            [[NSFileManager defaultManager] removeItemAtPath:[YSPreloadPath stringByAppendingPathComponent:obj] error:nil];
        }
    }];
}

//判断预加载文档路径是否存在
- (BOOL)preloadFileExist
{
    NSLog(@"%@",YSPreloadPath);
    //判断是否已经解压到tmp
    BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:[YSFileDirectory stringByAppendingPathComponent:_fileID]];
    
    if (!result) {
        //判断是否已经下载好
        result = [[NSFileManager defaultManager] fileExistsAtPath:[YSPreloadPath stringByAppendingPathComponent:_fileID]];
        if (result) {
            //下载好则解压
            [self unzipFile];
        }
    } else {
        NSNumber *unzipSuccess = [[NSUserDefaults standardUserDefaults] objectForKey:_fileID];
        if (unzipSuccess.boolValue) {
            if (_block) {
                _block(1.0f, 1.0f, [YSFileDirectory stringByAppendingPathComponent:_fileID], nil);
            }
        } else {
            //解压失败移除已经解压的文件
            [[NSFileManager defaultManager] removeItemAtPath:[YSFileDirectory stringByAppendingPathComponent:_fileID] error:nil];
            //下载好则解压
            [self unzipFile];
        }
    }
    
    return result;
}

//判断预加载文档临时文件是否存在
- (BOOL)preloadTmpFileExist
{
    BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:[YSPreloadTmpPath stringByAppendingPathComponent:_fileID]];
    return result;
}

//下载中途文件大小
- (long long)sizeOfDownloadTmpFile
{
    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[YSPreloadTmpPath stringByAppendingPathComponent:_fileID] error:&error];
    if (!error) {
        return ((NSNumber *)[attributes objectForKey:NSFileSize]).longLongValue;
    } else {
        return 0;
    }
}

- (void)downloadWithURL:(NSURL *)url
                 fileID:(NSString *)fileID
          progressBlock:(ysProgressBlock)block
{
    if ([_fileID isEqualToString:fileID]) {
        if (_task.state == NSURLSessionTaskStateRunning) {
            return;
        }
    }
    
    _block = block;
    _fileID = fileID;
    
    //清理预加载文档
    [self removeLastPreloadFile];
    
    //已经存在预加载文档
    if ([self preloadFileExist]) {
        return;
    }
    if ([self preloadTmpFileExist]) {
        //存在已经下载途中的临时文件
        [self downloadWithURL:url dataOffset:[self sizeOfDownloadTmpFile]];
    } else {
        //不存在临时文件从0开始下载
        [self downloadWithURL:url dataOffset:0];
    }
}

//根据数据偏移启动下载
- (void)downloadWithURL:(NSURL *)url dataOffset:(long long)offset
{
    if (YSHttpDNSAvailable && [url.host hasSuffix:YSDomain]) {
        //获取网宿CDN节点
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        NSString *urlString = [NSString stringWithFormat:@"http://%@/v1/httpdns/clouddns?ws_domain=%@&ws_ret_type=json", YSHttpDNSIP, url.host];
        urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"#%^{}\"[]|\\<> "].invertedSet];
        NSURLSessionDataTask *cdnTask = [session dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            NSMutableURLRequest *req = nil;
            if (!error) {
                NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                NSString *msg = [result objectForKey:@"msg"];
                if ([msg isEqualToString:@"Success"]) {
                    NSDictionary *data = [result objectForKey:@"data"];
                    NSDictionary *domain = [data objectForKey:url.host];
                    NSArray *ips = [domain objectForKey:@"ips"];
                    if (ips.count > 0) {
                        
                        NSString* originalUrl = [url absoluteString];
                        NSRange hostFirstRange = [originalUrl rangeOfString: url.host];
                        NSString* newUrl = [originalUrl stringByReplacingCharactersInRange:hostFirstRange withString:ips.firstObject];
                        req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:newUrl]];
                        [req setValue:url.host forHTTPHeaderField:@"host"];
                    }
                }
            }
            
            if (!req){
                req = [NSMutableURLRequest requestWithURL:url];
            }
            [req setValue:[NSString stringWithFormat:@"bytes=%lld-",offset] forHTTPHeaderField:@"Range"];
            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
            NSURLSessionDataTask *downloadTask = [session dataTaskWithRequest:req];
            [downloadTask resume];
        }];
        [cdnTask resume];
    }
    else {
        
        ///////////////////////////////
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
        [req setValue:[NSString stringWithFormat:@"bytes=%lld-",offset] forHTTPHeaderField:@"Range"];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        _task = [session dataTaskWithRequest:req];
        [_task resume];
    }
}

//鉴权
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential , credential);
    }
}

//收到响应，判断下载状态
- (void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSHTTPURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler
{
    long long contentLength = ((NSNumber *)[response.allHeaderFields objectForKey:@"Content-Length"]).longLongValue;
    NSString *contentRange = response.allHeaderFields[@"Content-Range"];
    if (contentRange.length != 0) {
        contentLength = [contentRange componentsSeparatedByString:@"/"].lastObject.longLongValue;
    }
    
    //本地大小 == contentLength
    if ([self sizeOfDownloadTmpFile] == contentLength) {
        //将临时文件转移到预加载文件路径
        if ([[NSFileManager defaultManager] moveItemAtURL:[NSURL fileURLWithPath:[YSPreloadTmpPath stringByAppendingPathComponent:_fileID]] toURL:[NSURL fileURLWithPath:[YSPreloadPath stringByAppendingPathComponent:_fileID]] error:nil]) {
            [self unzipFile];
        }
        //取消本次下载
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    
    //本地大小 > contentLength
    if ([self sizeOfDownloadTmpFile] > contentLength) {
        //文件大小错误删除本地文件
        [[NSFileManager defaultManager] removeItemAtPath:[YSPreloadTmpPath stringByAppendingPathComponent:_fileID] error:nil];
        //从0开始下载
        [self downloadWithURL:dataTask.currentRequest.URL dataOffset:0];
        //取消本次请求
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:YSPreloadTmpPath]) {
        //不存在临时下载文件夹则创建该文件夹
        [[NSFileManager defaultManager] createDirectoryAtPath:YSPreloadTmpPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *tmpFilePath = [YSPreloadTmpPath stringByAppendingPathComponent:_fileID];
    if (![[NSFileManager defaultManager] fileExistsAtPath:tmpFilePath]) {
        //不存在临时下载文件则创建该临时下载文件
        [[NSFileManager defaultManager] createFileAtPath:tmpFilePath contents:nil attributes:nil];
    }
    
    //创建输出流，并继续本次下载
    _stream = [NSOutputStream outputStreamToFileAtPath:tmpFilePath append:YES];
    [_stream open];
    
    completionHandler(NSURLSessionResponseAllow);
}

//接收数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [_stream write:data.bytes maxLength:data.length];
    if (_block) {
        _block((dataTask.countOfBytesReceived + [self sizeOfDownloadTmpFile])  * 1.0f / (dataTask.countOfBytesExpectedToReceive  + [self sizeOfDownloadTmpFile]), 0, nil, nil);
    }
}

//数据接收完成，转移到预加载文件目录
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [_stream close];
    [session finishTasksAndInvalidate];
    
    if (!error) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:YSPreloadPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:YSPreloadPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:[YSPreloadTmpPath stringByAppendingPathComponent:_fileID]]) {
            if ([[NSFileManager defaultManager] moveItemAtURL:[NSURL fileURLWithPath:[YSPreloadTmpPath stringByAppendingPathComponent:_fileID]] toURL:[NSURL fileURLWithPath:[YSPreloadPath stringByAppendingPathComponent:_fileID]] error:nil]) {
                //转移完成开始解压
                [self unzipFile];
            }
        }
    } else {
        if (_block) {
            _block(0, 0, nil, error);
        }
    }
}

- (void)unzipFile
{
    [SSZipArchive unzipFileAtPath:[YSPreloadPath stringByAppendingPathComponent:_fileID] toDestination:[YSFileDirectory stringByAppendingPathComponent:_fileID] progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
        if (self->_block) {
            self->_block(1.0f, entryNumber * 1.0f / total, nil, nil);
        }
    } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nullable error) {
        if (self->_block) {
            if (succeeded) {
                self->_block(1.0f, 1.0f, [YSFileDirectory stringByAppendingPathComponent:self->_fileID], nil);
                [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:self->_fileID];
                // 移除已解压的文件
                if([[NSFileManager defaultManager] fileExistsAtPath:YSPreloadPath])
                    [[NSFileManager defaultManager] removeItemAtPath: YSPreloadPath  error:nil];
                // 移除下载路径
                if([[NSFileManager defaultManager] fileExistsAtPath:YSPreloadTmpPath])
                    [[NSFileManager defaultManager] removeItemAtPath: YSPreloadTmpPath error:nil];
                
            }
            
            if (error) {
                //解压失败移除已经解压的文件
                [[NSFileManager defaultManager] removeItemAtPath:[YSFileDirectory stringByAppendingPathComponent:self->_fileID] error:nil];
                self->_block(1.0f, 0, nil, error);
            }
        }
    }];
}

- (void)cancelDownload
{
    [_task cancel];
    [[NSURLSession sharedSession] invalidateAndCancel];
}

@end
