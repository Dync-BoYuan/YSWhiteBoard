//
//  RSA.m
//  DJEncryptorSample
//
//  Created by DJ on 2017/5/5.
//  Copyright © 2017年 DJ. All rights reserved.
//

#import "BMRSA.h"
#import "NSString+BMEncrypt.h"

NSString *const kBMRSAErrorDomain = @"BMRSAErrorDomain";

NSString *const kBMRSAPubKeyTag = @"BMRSA_PublicKey";
NSString *const kBMRSAPrivKeyTag = @"BMRSA_PrivateKey";

@implementation NSError(BMRSA)

//    errSecUnimplemented                         = -4,      /* Function or operation not implemented. */
//    errSecIO                                    = -36,     /*I/O error (bummers)*/
//    errSecOpWr                                  = -49,     /*file already open with write permission*/
//    errSecParam                                 = -50,     /* One or more parameters passed to a function where not valid. */
//    errSecAllocate                              = -108,    /* Failed to allocate memory. */
//    errSecUserCanceled                          = -128,    /* User canceled the operation. */
//    errSecBadReq                                = -909,    /* Bad parameter or invalid state for operation. */
//    errSecInternalComponent                     = -2070,
//    errSecNotAvailable                          = -25291,  /* No keychain is available. You may need to restart your computer. */
//    errSecDuplicateItem                         = -25299,  /* The specified item already exists in the keychain. */
//    errSecItemNotFound                          = -25300,  /* The specified item could not be found in the keychain. */
//    errSecInteractionNotAllowed                 = -25308,  /* User interaction is not allowed. */
//    errSecDecode                                = -26275,  /* Unable to decode the provided data. */
//    errSecAuthFailed                            = -25293,  /* The user name or passphrase you entered is not correct. */

+ (NSError *)errorWithRSAOSStatus:(OSStatus)status
{
    NSString *description = nil, *reason = nil;

    switch (status)
    {
        case errSecSuccess:
            description = NSLocalizedString(@"Success", @"Error description");
            break;
            
        case errSecUnimplemented:
            description = NSLocalizedString(@"Unimplemented Error", @"Error description");
            reason = NSLocalizedString(@"Function or operation not implemented.", @"Error reason");
            break;
            
        case errSecIO:
            description = NSLocalizedString(@"I/O Error", @"Error description");
            reason = NSLocalizedString(@"I/O error (bummers)", @"Error reason");
            break;
            
        case errSecOpWr:
            description = NSLocalizedString(@"File Error", @"Error description");
            reason = NSLocalizedString(@"File already open with write permission", @"Error reason");
            break;
            
        case errSecParam:
            description = NSLocalizedString(@"Parameters Error", @"Error description");
            reason = NSLocalizedString(@"One or more parameters passed to a function where not valid.", @"Error reason");
            break;
            
        case errSecAllocate:
            description = NSLocalizedString(@"Memory Failure", @"Error description");
            reason = NSLocalizedString(@"Failed to allocate memory.", @"Error reason");
            break;
            
        case errSecUserCanceled:
            description = NSLocalizedString(@"User Canceled", @"Error description");
            reason = NSLocalizedString(@"User canceled the operation.", @"Error reason");
            break;
            
        case errSecBadReq:
            description = NSLocalizedString(@"Parameters Error", @"Error description");
            reason = NSLocalizedString(@"Bad parameter or invalid state for operation.", @"Error reason");
            break;
            
        case errSecInternalComponent:
            description = NSLocalizedString(@"Internal Component Error", @"Error description");
            reason = NSLocalizedString(@"Internal component Error", @"Error reason");
            break;
            
        case errSecNotAvailable:
            description = NSLocalizedString(@"Keychain Error", @"Error description");
            reason = NSLocalizedString(@"No keychain is available. You may need to restart your computer.", @"Error reason");
            break;
            
        case errSecDuplicateItem:
            description = NSLocalizedString(@"Keychain Error", @"Error description");
            reason = NSLocalizedString(@"The specified item already exists in the keychain.", @"Error reason");
            break;
            
        case errSecItemNotFound:
            description = NSLocalizedString(@"Keychain Error", @"Error description");
            reason = NSLocalizedString(@"The specified item could not be found in the keychain.", @"Error reason");
            break;
            
        case errSecInteractionNotAllowed:
            description = NSLocalizedString(@"Interaction Error", @"Error description");
            reason = NSLocalizedString(@"User interaction is not allowed.", @"Error reason");
            break;
            
        case errSecDecode:
            description = NSLocalizedString(@"Decode Error", @"Error description");
            reason = NSLocalizedString(@"Unable to decode the provided data.", @"Error reason");
            break;
            
        case errSecAuthFailed:
            description = NSLocalizedString(@"Auth Failed", @"Error description");
            reason = NSLocalizedString(@"The user name or passphrase you entered is not correct.", @"Error reason");
            break;
            
        default:
            description = NSLocalizedString(@"Unknown Error", @"Error description");
            break;
    }
    
    NSError *result = [NSError errorWithRSADescription:description reason:reason status:status];
    
    return result;
}

+ (NSError *)errorWithRSADescription:(NSString *)description reason:(NSString *)reason status:(OSStatus)status
{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:description forKey:NSLocalizedDescriptionKey];
    
    if (reason != nil)
    {
        [userInfo setObject:reason forKey:NSLocalizedFailureReasonErrorKey];
    }
    
    NSError *result = [NSError errorWithDomain:kBMRSAErrorDomain code:status userInfo:userInfo];
    
    return result;
}

+ (NSError *)errorWithRSADescription:(NSString *)description
{
    return [NSError errorWithRSADescription:description reason:nil status:0];
}

@end


@implementation BMRSA

#pragma mark - Public RSAHeader 数据处理

+ (NSData *)stripPublicKeyHeader:(NSData *)d_key
{
    // Skip ASN.1 public key header
    if (d_key == nil) return(nil);
    
    unsigned long len = [d_key length];
    if (!len) return(nil);
    
    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx	 = 0;
    
    if (c_key[idx++] != 0x30) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] =
    { 0x30,   0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) return(nil);
    
    idx += 15;
    
    if (c_key[idx++] != 0x03) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    if (c_key[idx++] != '\0') return(nil);
    
    // Now make a new NSData from this buffer
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}

+ (NSData *)dataTrimFromPublicPemKey:(NSString *)key
{
    NSRange spos = [key rangeOfString:@"-----BEGIN PUBLIC KEY-----"];
    NSRange epos = [key rangeOfString:@"-----END PUBLIC KEY-----"];
    if (spos.location != NSNotFound && epos.location != NSNotFound)
    {
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];
    
    // This will be base64 encoded, decode it.
    NSData *data = [NSString bm_base64DecodeString:key];
    data = [BMRSA stripPublicKeyHeader:data];

    if (!data)
    {
        return nil;
    }
    return data;
}


#pragma mark - Public SecKeyRef 生成

+ (SecKeyRef)publicKeyFromData:(NSData *)data withTag:(NSString *)tag error:(NSError **)error
{
    if (!tag)
    {
        tag = kBMRSAPubKeyTag;
    }
    NSData *tagData = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];
    
    // 删除KeyChainItem，必须指定两项 kSecAttrApplicationTag 和 kSecClass
    // Delete any old lingering key with the same tag
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [publicKey setObject:tagData forKey:(__bridge id)kSecAttrApplicationTag];
    OSStatus deleteStatus = SecItemDelete((__bridge CFDictionaryRef)publicKey);
    if (deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound)
    {
        *error = [NSError errorWithRSAOSStatus:deleteStatus];
        return nil;
    }

    // Add persistent version of the key to system keychain
    // 添加KeyChainItem
    // 密钥数据
    [publicKey setObject:data forKey:(__bridge id)kSecValueData];
    [publicKey setObject:(__bridge id) kSecAttrKeyClassPublic forKey:(__bridge id)
     kSecAttrKeyClass];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)
     kSecReturnPersistentRef];
    
    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)publicKey, &persistKey);
    if (persistKey != nil)
    {
        CFRelease(persistKey);
    }
    if ((status != errSecSuccess) && (status != errSecDuplicateItem))
    {
        *error = [NSError errorWithRSAOSStatus:status];
        return nil;
    }

    [publicKey removeObjectForKey:(__bridge id)kSecValueData];
    [publicKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    // 密钥种类为RSA密钥
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)publicKey, (CFTypeRef *)&keyRef);
    if (status != errSecSuccess)
    {
        *error = [NSError errorWithRSAOSStatus:status];
        return nil;
    }
    
    return keyRef;
}

#pragma makr - DER格式
+ (SecKeyRef)publickeyFromDer:(NSData *)data error:(NSError **)error
{
    if (data == nil)
    {
        *error = [NSError errorWithRSADescription:@"der data is nil"];
        return nil;
    }
    
    // 创建证书对象
    SecCertificateRef certificate = SecCertificateCreateWithData(kCFAllocatorDefault, ( __bridge CFDataRef)data);
    if (certificate == nil)
    {
        *error = [NSError errorWithRSADescription:@"Can not read certificate"];
        CFRelease(certificate);
        return nil;
    }
    
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust;
    OSStatus trustStatus = SecTrustCreateWithCertificates(certificate, policy, &trust);
    if (trustStatus != errSecSuccess)
    {
        *error = [NSError errorWithRSAOSStatus:trustStatus];
        CFRelease(certificate);
        CFRelease(policy);
        return nil;
    }
    
    SecTrustResultType trustResultType;
    trustStatus = SecTrustEvaluate(trust, &trustResultType);
    if (trustStatus != errSecSuccess)
    {
        *error = [NSError errorWithRSAOSStatus:trustStatus];
        CFRelease(certificate);
        CFRelease(policy);
        return nil;
    }
    
    SecKeyRef publicKey = SecTrustCopyPublicKey(trust);
    if (publicKey == nil)
    {
        *error = [NSError errorWithRSADescription:@"SecTrustCopyPublicKey fail"];
        CFRelease(certificate);
        CFRelease(policy);
        return nil;
    }
    
    // 释放
    CFRelease(certificate);
    CFRelease(policy);
    
    return publicKey;
}


#pragma mark - encrypt 加密

+ (NSData *)encryptData:(NSData *)data withKeyRef:(SecKeyRef)keyRef error:(NSError **)error
{
    /**
     OSStatus SecKeyEncrypt(
         SecKeyRef           key,
         SecPadding          padding,
         const uint8_t		*plainText,
         size_t              plainTextLen,
         uint8_t             *cipherText,
         size_t              *cipherTextLen)
     **/
    
    // 第一步 准备数据源，参看 SecKeyEncrypt API的 3、4参数
    const uint8_t *srcbuf = (const uint8_t *)[data bytes];
    size_t srclen = (size_t)data.length;
    
    // 第二步 准备密文，参看 SecKeyEncrypt API的 5、6参数
    // blockSize是指 SecKeyRef 中存储的block大小
    size_t block_size = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    void *outbuf = malloc(block_size);
    size_t src_block_size = block_size - 11;
    
    // 第三步 逐个block进行加密
    NSMutableData *ret = [[NSMutableData alloc] init];
    for (int idx=0; idx<srclen; idx+=src_block_size)
    {
        // NSLog(@"%d/%d block_size: %d", idx, (int)srclen, (int)block_size);
        size_t data_len = srclen - idx;
        // 每次加密不能超过 blockSize 大小
        if (data_len > src_block_size)
        {
            data_len = src_block_size;
        }
        
        // 加密
        size_t outlen = block_size;
        OSStatus status = noErr;
        status = SecKeyEncrypt(keyRef,
                               kSecPaddingPKCS1,
                               srcbuf + idx,
                               data_len,
                               outbuf,
                               &outlen
                               );
        if (status != 0)
        {
            NSLog(@"SecKeyEncrypt fail. Error Code: %d", (int)status);
            *error = [NSError errorWithRSAOSStatus:status];
            ret = nil;
            break;
        }
        else
        {
            [ret appendBytes:outbuf length:outlen];
        }
    }
    
    free(outbuf);
    CFRelease(keyRef);
    return ret;
}


#pragma mark - Private RSAHeader 数据处理

//credit: http://hg.mozilla.org/services/fx-home/file/tip/Sources/NetworkAndStorage/CryptoUtils.m#l1036
+ (NSData *)stripPrivateKeyHeader:(NSData *)d_key
{
    // Skip ASN.1 private key header
    if (d_key == nil) return(nil);
    
    unsigned long len = [d_key length];
    if (!len) return(nil);
    
    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx	 = 22; //magic byte at offset 22
    
    if (0x04 != c_key[idx++]) return nil;
    
    //calculate length of the key
    unsigned int c_len = c_key[idx++];
    int det = c_len & 0x80;
    if (!det)
    {
        c_len = c_len & 0x7f;
    }
    else
    {
        int byteCount = c_len & 0x7f;
        if (byteCount + idx > len)
        {
            //rsa length field longer than buffer
            return nil;
        }
        unsigned int accum = 0;
        unsigned char *ptr = &c_key[idx];
        idx += byteCount;
        while (byteCount)
        {
            accum = (accum << 8) + *ptr;
            ptr++;
            byteCount--;
        }
        c_len = accum;
    }
    
    // Now make a new NSData from this buffer
    return [d_key subdataWithRange:NSMakeRange(idx, c_len)];
}

+ (NSData *)dataTrimFromPrivatePemKey:(NSString*)key
{
    NSRange spos;
    NSRange epos;
    
    spos = [key rangeOfString:@"-----BEGIN RSA PRIVATE KEY-----"];
    if (spos.length > 0)
    {
        epos = [key rangeOfString:@"-----END RSA PRIVATE KEY-----"];
    }
    else
    {
        spos = [key rangeOfString:@"-----BEGIN PRIVATE KEY-----"];
        epos = [key rangeOfString:@"-----END PRIVATE KEY-----"];
    }
    if (spos.location != NSNotFound && epos.location != NSNotFound)
    {
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];
    
    // This will be base64 encoded, decode it.
    NSData *data = [NSString bm_base64DecodeString:key];
    data = [BMRSA stripPrivateKeyHeader:data];
    if (!data)
    {
        return nil;
    }
    return data;
}


#pragma mark - Private SecKeyRef 生成

+ (SecKeyRef)privateKeyFromData:(NSData *)data withTag:(NSString *)tag error:(NSError **)error
{
    if (!tag)
    {
        tag = kBMRSAPrivKeyTag;
    }
    NSData *tagData = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];
    
    // Delete any old lingering key with the same tag
    NSMutableDictionary *privateKey = [[NSMutableDictionary alloc] init];
    [privateKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
    [privateKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [privateKey setObject:tagData forKey:(__bridge id)kSecAttrApplicationTag];
    OSStatus deleteStatus = SecItemDelete((__bridge CFDictionaryRef)privateKey);
    if (deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound)
    {
        *error = [NSError errorWithRSAOSStatus:deleteStatus];
        return nil;
    }
    
    // Add persistent version of the key to system keychain
    [privateKey setObject:data forKey:(__bridge id)kSecValueData];
    [privateKey setObject:(__bridge id) kSecAttrKeyClassPrivate forKey:(__bridge id)
     kSecAttrKeyClass];
    [privateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)
     kSecReturnPersistentRef];
    
    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)privateKey, &persistKey);
    if (persistKey != nil)
    {
        CFRelease(persistKey);
    }
    if ((status != errSecSuccess) && (status != errSecDuplicateItem))
    {
        *error = [NSError errorWithRSAOSStatus:status];
        return nil;
    }
    
    [privateKey removeObjectForKey:(__bridge id)kSecValueData];
    [privateKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [privateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [privateKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)privateKey, (CFTypeRef *)&keyRef);
    if(status != errSecSuccess)
    {
        *error = [NSError errorWithRSAOSStatus:status];
        return nil;
    }
    return keyRef;
}


#pragma mark - decrypt 解密

+ (NSData *)decryptData:(NSData *)data withKeyRef:(SecKeyRef)keyRef error:(NSError **)error
{
//OSStatus SecKeyDecrypt(
//                       SecKeyRef           key,               /* Private key */
//                       SecPadding          padding,           /* kSecPaddingNone,
//                                                                 kSecPaddingPKCS1,
//                                                                 kSecPaddingOAEP */
//                       const uint8_t       *cipherText,
//                       size_t              cipherTextLen,		/* length of cipherText */
//                       uint8_t             *plainText,
//                       size_t              *plainTextLen)		/* IN/OUT */

    const uint8_t *srcbuf = (const uint8_t *)[data bytes];
    size_t srclen = (size_t)data.length;
    
    size_t block_size = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    UInt8 *outbuf = malloc(block_size);
    size_t src_block_size = block_size;
    
    NSMutableData *ret = [[NSMutableData alloc] init];
    for (int idx=0; idx<srclen; idx+=src_block_size)
    {
        //NSLog(@"%d/%d block_size: %d", idx, (int)srclen, (int)block_size);
        size_t data_len = srclen - idx;
        if(data_len > src_block_size)
        {
            data_len = src_block_size;
        }
        
        size_t outlen = block_size;
        OSStatus status = noErr;
        status = SecKeyDecrypt(keyRef,
                               kSecPaddingNone,
                               srcbuf + idx,
                               data_len,
                               outbuf,
                               &outlen
                               );
        if (status != 0)
        {
            NSLog(@"SecKeyEncrypt fail. Error Code: %d", (int)status);
            *error = [NSError errorWithRSAOSStatus:status];
            ret = nil;
            break;
        }
        else
        {
            //the actual decrypted data is in the middle, locate it!
            int idxFirstZero = -1;
            int idxNextZero = (int)outlen;
            for ( int i = 0; i < outlen; i++ )
            {
                if ( outbuf[i] == 0 )
                {
                    if ( idxFirstZero < 0 )
                    {
                        idxFirstZero = i;
                    }
                    else
                    {
                        idxNextZero = i;
                        break;
                    }
                }
            }
            
            [ret appendBytes:&outbuf[idxFirstZero+1] length:idxNextZero-idxFirstZero-1];
        }
    }
    
    free(outbuf);
    CFRelease(keyRef);
    return ret;
}


#pragma mark - Public func 对外接口

#pragma mark PEM加密
+ (NSData *)encryptWithString:(NSString *)string publicPemKey:(NSString *)pubKey error:(NSError **)error
{
    if (string == nil)
    {
        *error = [NSError errorWithRSADescription:@"invalid origin string " reason:nil status:0];
        return nil;
    }
    
    NSData *utfData = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    return [BMRSA encryptWithData:utfData publicPemKey:pubKey error:error];
}

+ (NSData *)encryptWithData:(NSData *)data publicPemKey:(NSString *)pubKey error:(NSError **)error
{
    if (data == nil)
    {
        *error = [NSError errorWithRSADescription:@"invalid origin data " reason:nil status:0];
        return nil;
    }
    
    NSData *publicKeyData = [BMRSA dataTrimFromPublicPemKey:pubKey];
    if (publicKeyData == nil)
    {
        *error = [NSError errorWithRSADescription:@"invalid publicKey " reason:nil status:0];
        return nil;
    }
    
    SecKeyRef publicKey = [BMRSA publicKeyFromData:publicKeyData withTag:nil error:error];
    if (publicKey == nil)
    {
        return nil;
    }
    
    NSData *result = [BMRSA encryptData:data withKeyRef:publicKey error:error];
    
    return result;
}

+ (NSString *)encryptString:(NSString *)string publicPemKey:(NSString *)pubKey error:(NSError **)error
{
    NSData *encryptData = [BMRSA encryptWithString:string publicPemKey:pubKey error:error];
    if (encryptData)
    {
        return [NSString bm_base64EncodeData:encryptData];
    }
    
    return nil;
}

+ (NSString *)encryptData:(NSData *)data publicPemKey:(NSString *)pubKey error:(NSError **)error
{
    NSData *encryptData = [BMRSA encryptWithData:data publicPemKey:pubKey error:error];
    if (encryptData)
    {
        return [NSString bm_base64EncodeData:encryptData];
    }
    
    return nil;
}

#pragma mark DER加密
+ (NSData *)encryptWithString:(NSString *)string publicDer:(NSData *)derFileData error:(NSError **)error
{
    if (string == nil)
    {
        *error = [NSError errorWithRSADescription:@"invalid origin string " reason:nil status:0];
        return nil;
    }
    
    NSData *utfData = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    return [BMRSA encryptWithData:utfData publicDer:derFileData error:error];
}

+ (NSData *)encryptWithData:(NSData *)data publicDer:(NSData *)derFileData error:(NSError **)error
{
    if (data == nil)
    {
        *error = [NSError errorWithRSADescription:@"invalid origin data " reason:nil status:0];
        return nil;
    }
    
    SecKeyRef publicKey = [BMRSA publickeyFromDer:derFileData error:error];
    if (publicKey == nil)
    {
        return nil;
    }
    
    NSData *result = [BMRSA encryptData:data withKeyRef:publicKey error:error];
    
    return result;
}

+ (NSString *)encryptString:(NSString *)string publicDer:(NSData *)derFileData error:(NSError **)error
{
    NSData *encryptData = [BMRSA encryptWithString:string publicDer:derFileData error:error];
    if (encryptData)
    {
        return [NSString bm_base64EncodeData:encryptData];
    }
    
    return nil;
}

+ (NSString *)encryptData:(NSData *)data publicDer:(NSData *)derFileData error:(NSError **)error
{
    NSData *encryptData = [BMRSA encryptWithData:data publicDer:derFileData error:error];
    if (encryptData)
    {
        return [NSString bm_base64EncodeData:encryptData];
    }
    
    return nil;
}

#pragma mark PEM解密 publicPemKey
+ (NSData *)decryptWithString:(NSString *)string publicPemKey:(NSString *)pubKey error:(NSError **)error
{
    if (string == nil)
    {
        *error = [NSError errorWithRSADescription:@"invalid encrypt string " reason:nil status:0];
        return nil;
    }
    
    NSData *utfData = [NSString bm_base64DecodeString:string];
    
    return [BMRSA decryptWithData:utfData publicPemKey:pubKey error:error];
}

+ (NSData *)decryptWithData:(NSData *)data publicPemKey:(NSString *)pubKey error:(NSError **)error
{
    if (data == nil)
    {
        *error = [NSError errorWithRSADescription:@"invalid encrypt data " reason:nil status:0];
        return nil;
    }
    
    NSData *publicKeyData = [BMRSA dataTrimFromPublicPemKey:pubKey];
    if (publicKeyData == nil)
    {
        *error = [NSError errorWithRSADescription:@"invalid publicKey " reason:nil status:0];
        return nil;
    }
    
    SecKeyRef publicKey = [BMRSA publicKeyFromData:publicKeyData withTag:nil error:error];
    if (publicKey == nil)
    {
        return nil;
    }
    
    NSData *result = [BMRSA decryptData:data withKeyRef:publicKey error:error];
    
    return result;
}

+ (NSString *)decryptString:(NSString *)string publicPemKey:(NSString *)pubKey error:(NSError **)error
{
    NSData *encryptData = [BMRSA decryptWithString:string publicPemKey:pubKey error:error];
    if (encryptData)
    {
        return [[NSString alloc] initWithData:encryptData encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

+ (NSString *)decryptData:(NSData *)data publicPemKey:(NSString *)pubKey error:(NSError **)error
{
    NSData *encryptData = [BMRSA decryptWithData:data publicPemKey:pubKey error:error];
    if (encryptData)
    {
        return [[NSString alloc] initWithData:encryptData encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

#pragma mark PEM解密 privatePemKey
+ (NSData *)decryptWithString:(NSString *)string privatePemKey:(NSString *)privKey error:(NSError **)error
{
    if (string == nil)
    {
        *error = [NSError errorWithRSADescription:@"invalid encrypt string " reason:nil status:0];
        return nil;
    }
    
    NSData *utfData = [NSString bm_base64DecodeString:string];
    
    return [BMRSA decryptWithData:utfData privatePemKey:privKey error:error];
}

+ (NSData *)decryptWithData:(NSData *)data privatePemKey:(NSString *)privKey error:(NSError **)error
{
    if (data == nil)
    {
        *error = [NSError errorWithRSADescription:@"invalid encrypt data " reason:nil status:0];
        return nil;
    }
    
    NSData *privateKeyData = [BMRSA dataTrimFromPrivatePemKey:privKey];
    if (privateKeyData == nil)
    {
        *error = [NSError errorWithRSADescription:@"invalid privateKey " reason:nil status:0];
        return nil;
    }
    
    SecKeyRef privateKey = [BMRSA privateKeyFromData:privateKeyData withTag:nil error:error];
    if (privateKey == nil)
    {
        return nil;
    }
    
    NSData *result = [BMRSA decryptData:data withKeyRef:privateKey error:error];
    
    return result;
}

+ (NSString *)decryptString:(NSString *)string privatePemKey:(NSString *)privKey error:(NSError **)error
{
    NSData *encryptData = [BMRSA decryptWithString:string privatePemKey:privKey error:error];
    if (encryptData)
    {
        return [[NSString alloc] initWithData:encryptData encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

+ (NSString *)decryptData:(NSData *)data privatePemKey:(NSString *)privKey error:(NSError **)error
{
    NSData *encryptData = [BMRSA decryptWithData:data privatePemKey:privKey error:error];
    if (encryptData)
    {
        return [[NSString alloc] initWithData:encryptData encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

@end
