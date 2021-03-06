//
//  CryptoUtils.m
//  iclous
//
//  Created by Klaus Rodewig on 10.10.12.
//  Copyright (c) 2012 Foobar Ltd. All rights reserved.
//

#import "CryptoUtils.h"
#import <CommonCrypto/CommonKeyDerivation.h>
#import <CommonCrypto/CommonCryptor.h>

NSUInteger const PBKDFRounds = 10000;

@implementation CryptoUtils

- (id)initWithPassword:(NSString *)thePassword
{
    self = [super init];
    if (self) {
        NSMutableData *theData = [NSMutableData dataWithLength:kCCBlockSizeAES128];
        SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, theData.mutableBytes);
        self.iv = theData;
        theData = nil;
        
        theData = [NSMutableData dataWithLength:kCCBlockSizeAES128];
        SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, theData.mutableBytes);
        self.salt = theData;
        theData = nil;
        
        self.password = thePassword;
    }
    return self;
}

-(NSData *)encryptData:(NSData *)clearText {
    NSLog(@"[+] %@", NSStringFromSelector(_cmd));
    
    [self createKey:[self.password dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Puffer für Ciphertext
    NSMutableData *cipherData = [NSMutableData dataWithLength:clearText.length + kCCBlockSizeAES128];

    // Länge des Ciphertextes
    size_t ciperLength;
    
    // Durchführen der Verschlüsselung
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          self.cryptKey.bytes,
                                          self.cryptKey.length,
                                          self.iv.bytes,
                                          clearText.bytes,
                                          clearText.length,
                                          cipherData.mutableBytes,
                                          cipherData.length,
                                          &ciperLength);
        
    if(cryptStatus){
        NSLog(@"Something terrible during encryption happened!");
    } else {
        NSLog(@"Ciphertext length: %i", [cipherData length]);
    }
       
    return cipherData;
}

-(BOOL)createKey:(NSData *)key{
    NSLog(@"[+] %@", NSStringFromSelector(_cmd));
    
    NSMutableData *localKey = [NSMutableData dataWithLength:kCCKeySizeAES128];
    
    int result = CCKeyDerivationPBKDF(kCCPBKDF2,
                                      self.password.UTF8String,
                                      self.password.length,
                                      self.salt.bytes,
                                      self.salt.length,
                                      kCCPRFHmacAlgSHA1,
                                      PBKDFRounds,
                                      localKey.mutableBytes,
                                      localKey.length);
    if(kCCSuccess){
        NSLog(@"Fehler beim Erstellen des Schlüssels: %d", result);
    }
    
    self.cryptKey = localKey;
    
    return YES;
}

@end
