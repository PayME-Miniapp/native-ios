//
//  KLPCrypto.h
//  KalapaSDK
//
//  Created by Quan Tran on 26/12/2023.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>


NS_ASSUME_NONNULL_BEGIN

@interface KLPCrypto : NSObject

@property (nonatomic, strong) NSData *key;
@property (nonatomic, strong) NSData *iv;

- (instancetype)initWithDefaultKeyAndIV;
- (NSData *)encryptAESWithString:(NSString *)string;
- (NSString *)decryptAESWithData:(NSData *)data;

- (NSString *)SHA256:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
