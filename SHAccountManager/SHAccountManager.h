//
//  SHAccountManager.h
//  Influnet
//
//  Created by Seivan Heidari on 2/25/13.
//  Copyright (c) 2013 Seivan Heidari. All rights reserved.
//


#import <Accounts/Accounts.h>


@interface SHAccountManager : NSObject
typedef void(^SHTwitterAccountPickerHandler)(ACAccount * chosenAccount);
typedef void(^SHTwitterAuthenticationHandler)(NSArray * accounts, SHTwitterAccountPickerHandler pickAccount);
typedef void(^SHAccountErrorHandler)(NSError * error);

+(SHAccountManager *)sharedManager;
@property(nonatomic,strong) ACAccountStore * accountStore;
@property(nonatomic,strong) ACAccountType  * accountTypeTwitter;

@property(nonatomic,readonly) NSArray  * accountsTwitter;

+(void)registerTwitterAppKey:(NSString *)theAppKey andAppSecret:(NSString *)theAppSecret;
-(void)authenticateWithTwitterForAccount:(SHTwitterAuthenticationHandler)theAccountRequirementBlock
                               onSuccess:(void (^)(NSDictionary * params))onSuccessBlock
                               onFailure:(SHAccountErrorHandler)onFailureBlock;
@end
