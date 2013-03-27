//
//  SHOmniAuthLinkedIn.m
//  SHAccountManagerExample
//
//  Created by Seivan Heidari on 3/23/13.
//  Copyright (c) 2013 Seivan Heidari. All rights reserved.
//

//Class dependency
#import "SHOmniAuthLinkedIn.h"
#import "SHOmniAuth.h"
#import "SHOmniAuthProviderPrivates.h"
#import "OAuthCore.h"
#import "OAuth+Additions.h"

#import "SHAccountStore.h"
#import "SHRequest.h"

//Login dependency
#import "AFLinkedInOAuth1Client.h"


@interface SHAccount ()
@property (readwrite, NS_NONATOMIC_IOSONLY) NSString      *identifier;
+(void)updateAccount:(SHAccount *)theAccount withCompleteBlock:(SHOmniAuthAccountResponseHandler)completeBlock;
+(void)performLoginForNewAccount:(SHOmniAuthAccountResponseHandler)completionBlock;
@end

@interface SHOmniAuthLinkedIn ()

@end

@implementation SHOmniAuthLinkedIn


+(void)performLoginWithListOfAccounts:(SHOmniAuthAccountsListHandler)accountPickerBlock
                           onComplete:(SHOmniAuthAccountResponseHandler)completionBlock; {
  SHAccountStore * store = [[SHAccountStore alloc] init];
  SHAccountType  * type = [store accountTypeWithAccountTypeIdentifier:self.accountTypeIdentifier];
  
  accountPickerBlock([store accountsWithAccountType:type], ^(id<account> theChosenAccount) {
    
    if(theChosenAccount == nil) [self performLoginForNewAccount:completionBlock];
    else [SHOmniAuthLinkedIn updateAccount:(SHAccount *)theChosenAccount withCompleteBlock:completionBlock];
    
  });
  
  
  
  
  
}


+(BOOL)hasLocalAccountOnDevice; {
  SHAccountStore * store = [[SHAccountStore alloc] init];
  SHAccountType  * type  = [store accountTypeWithAccountTypeIdentifier:self.accountTypeIdentifier];
  return [store accountsWithAccountType:type].count > 0;
}
+(NSString *)provider; {
  return self.description;
}

+(NSString *)accountTypeIdentifier; {
  return self.description;
}

+(NSString *)serviceType; {
  return self.description;
}

+(NSString *)description; {
  return NSStringFromClass(self.class);
}

+(void)performLoginForNewAccount:(SHOmniAuthAccountResponseHandler)completionBlock;{
  SHAccountStore * store    = [[SHAccountStore alloc] init];
  SHAccountType  * type     = [store accountTypeWithAccountTypeIdentifier:self.accountTypeIdentifier];
  SHAccount      * account  = [[SHAccount alloc] initWithAccountType:type];
  AFLinkedInOAuth1Client *  linkedInClient = [[AFLinkedInOAuth1Client alloc]
                                              initWithBaseURL:
                                              [NSURL URLWithString:@"https://api.linkedin.com/"]
                                              key:[SHOmniAuth providerValue:SHOmniAuthProviderValueKey forProvider:self.provider]
                                              secret:[SHOmniAuth providerValue:SHOmniAuthProviderValueSecret forProvider:self.provider]
                                              ];
  
  [linkedInClient authorizeUsingOAuthWithRequestTokenPath:@"uas/oauth/requestToken"
                                    userAuthorizationPath:@"uas/oauth/authorize"
                                              callbackURL:[NSURL URLWithString:
                                                           [SHOmniAuth providerValue:SHOmniAuthProviderValueCallbackUrl
                                                                         forProvider:self.provider]]
                                          accessTokenPath:@"uas/oauth/accessToken"
                                             accessMethod:@"POST" success:^(AFOAuth1Token *accessToken) {
                                               //Remove observer!
                                               SHAccountCredential * credential = [[SHAccountCredential alloc]
                                                                                   initWithOAuthToken:accessToken.key
                                                                                   tokenSecret:accessToken.secret];
                                               
                                               account.credential = credential;
                                               [SHOmniAuthLinkedIn updateAccount:account withCompleteBlock:completionBlock];
                                               
                                             } failure:^(NSError *error) {
                                               completionBlock(nil, nil, error, NO);
                                             }];
  
}


+(void)updateAccount:(SHAccount *)theAccount withCompleteBlock:(SHOmniAuthAccountResponseHandler)completeBlock; {
  SHAccountStore * accountStore = [[SHAccountStore alloc] init];
  SHAccountType  * accountType  = [accountStore accountTypeWithAccountTypeIdentifier:self.accountTypeIdentifier];
  [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
    if(granted) {
      SHRequest * request=  [SHRequest requestForServiceType:theAccount.accountType.identifier requestMethod:SHRequestMethodGET URL:[NSURL URLWithString:@"https://api.linkedin.com/v1/people/~:(id,first-name,last-name)?format=json"] parameters:nil];
      request.account = (id<account>)theAccount;
      [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        
        NSDictionary * response =  [NSJSONSerialization
                                    JSONObjectWithData:responseData options:0 error:nil];
        
        theAccount.username = [NSString stringWithFormat:@"%@_%@", response[@"firstName"], response[@"lastName"]];
        theAccount.identifier = response[@"id"];
        
        [accountStore saveAccount:theAccount withCompletionHandler:^(BOOL success, NSError *error) {
          NSMutableDictionary * fullResponse = response.mutableCopy;
          id<accountPrivate> privateAccount = (id<accountPrivate>)theAccount;
          fullResponse[@"oauth_token"] = privateAccount.credential.token;
          fullResponse[@"oauth_token_secret"] = privateAccount.credential.secret;
          dispatch_async(dispatch_get_main_queue(), ^{ completeBlock((id<account>)theAccount, fullResponse.copy, error, success); });
        }];
        
      }];
      
    }
    else
      dispatch_async(dispatch_get_main_queue(), ^{ completeBlock((id<account>)theAccount, nil, error, granted); });
    
  }];
  
}


@end
