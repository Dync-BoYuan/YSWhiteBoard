//
//  RSA.h
//  DJEncryptorSample
//
//  Created by DJ on 2017/5/5.
//  Copyright © 2017年 DJ. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kBMRSAErrorDomain;

@interface NSError (BMRSA)

+ (NSError *)errorWithRSAOSStatus:(OSStatus)status;
+ (NSError *)errorWithRSADescription:(NSString *)description reason:(nullable NSString *)reason status:(OSStatus)status;
+ (NSError *)errorWithRSADescription:(NSString *)description;

@end

@interface BMRSA : NSObject

#pragma mark PEM加密
+ (nullable NSData *)encryptWithString:(NSString *)string publicPemKey:(NSString *)pubKey error:(NSError **)error;
+ (nullable NSData *)encryptWithData:(NSData *)data publicPemKey:(NSString *)pubKey error:(NSError **)error;

+ (nullable NSString *)encryptString:(NSString *)string publicPemKey:(NSString *)pubKey error:(NSError **)error;
+ (nullable NSString *)encryptData:(NSData *)data publicPemKey:(NSString *)pubKey error:(NSError **)error;

#pragma mark DER加密
+ (nullable NSData *)encryptWithString:(NSString *)string publicDer:(NSData *)derFileData error:(NSError **)error;
+ (nullable NSData *)encryptWithData:(NSData *)data publicDer:(NSData *)derFileData error:(NSError **)error;

+ (nullable NSString *)encryptString:(NSString *)string publicDer:(NSData *)derFileData error:(NSError **)error;
+ (nullable NSString *)encryptData:(NSData *)data publicDer:(NSData *)derFileData error:(NSError **)error;

#pragma mark PEM解密 publicPemKey
+ (nullable NSData *)decryptWithString:(NSString *)string publicPemKey:(NSString *)pubKey error:(NSError **)error;
+ (nullable NSData *)decryptWithData:(NSData *)data publicPemKey:(NSString *)pubKey error:(NSError **)error;

+ (nullable NSString *)decryptString:(NSString *)string publicPemKey:(NSString *)pubKey error:(NSError **)error;
+ (nullable NSString *)decryptData:(NSData *)data publicPemKey:(NSString *)pubKey error:(NSError **)error;

#pragma mark PEM解密 privatePemKey
+ (nullable NSData *)decryptWithString:(NSString *)string privatePemKey:(NSString *)privKey error:(NSError **)error;
+ (nullable NSData *)decryptWithData:(NSData *)data privatePemKey:(NSString *)privKey error:(NSError **)error;

+ (nullable NSString *)decryptString:(NSString *)string privatePemKey:(NSString *)privKey error:(NSError **)error;
+ (nullable NSString *)decryptData:(NSData *)data privatePemKey:(NSString *)privKey error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
