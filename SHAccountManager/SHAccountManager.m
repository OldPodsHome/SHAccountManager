//
//  SHAccountManager.m
//  Influnet
//
//  Created by Seivan Heidari on 2/25/13.
//  Copyright (c) 2013 Seivan Heidari. All rights reserved.
//

#import "SHAccountManager.h"
#import "AFOAuth1Client.h"
#import "TWAPIManager.h"
#import "TWAppCredentialStore.h"

@interface SHAccountManager ()
-(void)logErrorCode:(NSError *)theErrorCode;
-(void)requestAccessToTwitterAccounts:(ACAccountStoreRequestAccessCompletionHandler)onCompletionBlock;
-(void)saveTwitterAccountWithToken:(NSString *)theToken andSecret:(NSString *)theSecret
             withCompletionHandler:(void (^)(ACAccount * account, NSError * error))onCompletionBlock;
-(void)requestReverseOAuthWithAccount:(ACAccount *)theAccount
                            onSuccess:(void (^)(NSDictionary * parameters ))onSuccessBlock
                            onFailure:(SHAccountErrorHandler)onFailureBlock;
-(void)requestSignedOAuthToTwitterOnSuccess:(SHTwitterAccountPickerHandler)onSuccessBlock
                                  onFailure:(SHAccountErrorHandler)onFailureBlock;

@property(nonatomic, readonly) NSString * twitterConsumerKey;
@property(nonatomic, readonly) NSString * twitterConsumerSecret;
@property (nonatomic) NSString *twitterCallbackUrl;

@end

@implementation SHAccountManager
#pragma mark -
#pragma mark Initialize
-(id)init {
  self = [super init];
  if (self) {
    self.accountStore       = [[ACAccountStore alloc] init];
    self.accountTypeTwitter = [self.accountStore
                               accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
  }
  
  return self;
}

+(SHAccountManager *)sharedManager; {
  static dispatch_once_t once;
  static SHAccountManager * sharedManager;
  dispatch_once(&once, ^ { sharedManager = [[self alloc] init]; });
  return sharedManager;
}

+(void)registerTwitterAppKey:(NSString *)theAppKey andAppSecret:(NSString *)theAppSecret; {
  [TWAPIManager registerTwitterAppKey:theAppKey andAppSecret:theAppSecret];
}

+(void)registerTwitterCallbackUrl:(NSString *)urlString
{
  [[self class] sharedManager].twitterCallbackUrl = urlString;
}

#pragma mark -
#pragma mark Getters
-(NSArray *)accountsTwitter; {
  return [self.accountStore accountsWithAccountType:self.accountTypeTwitter];
}

-(void)requestAccessToTwitterAccounts:(ACAccountStoreRequestAccessCompletionHandler)onCompletionBlock; {
    [self.accountStore requestAccessToAccountsWithType:self.accountTypeTwitter options:nil completion:^(BOOL granted, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        onCompletionBlock(granted,error);
      });
    }];
}

-(void)saveTwitterAccountWithToken:(NSString *)theToken andSecret:(NSString *)theSecret
      withCompletionHandler:(void (^)(ACAccount * account, NSError * error))onCompletionBlock; {
  
  ACAccountCredential * credential = [[ACAccountCredential alloc]
                                      initWithOAuthToken:theToken tokenSecret:theSecret];
  
  __block ACAccount * account = [[ACAccount alloc]
                         initWithAccountType:self.accountTypeTwitter];
  
  account.credential = credential;
  [self.accountStore saveAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
    if(success || ( [error.domain isEqualToString:ACErrorDomain] && error.code ==ACErrorAccountAlreadyExists )) {
      
    }
    else {
      account = nil;
      [self logErrorCode:error];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      onCompletionBlock(account, error);
    });
  }];


}



-(void)requestReverseOAuthWithAccount:(ACAccount *)theAccount
                            onSuccess:(void (^)(NSDictionary * parameters ))onSuccessBlock
                            onFailure:(SHAccountErrorHandler)onFailureBlock; {
  
  [TWAPIManager performReverseAuthForAccount:theAccount
                                 withHandler:^(NSData *responseData, NSError *error) {
                                   
                                   if (error == nil) {
                                     NSString *responseStr = [[NSString alloc]
                                                              initWithData:responseData
                                                              encoding:NSUTF8StringEncoding];

                                     NSDictionary * params = [self paramsFromQueryString:responseStr];
                                     
                                     onSuccessBlock(params);
                                   }
                                   
                                   
                                   else onFailureBlock(error);
                                   
                                   
                                 }];
}

#pragma mark -
#pragma mark Authentication
-(void)authenticateWithTwitterForAccount:(SHTwitterAuthenticationHandler)theAccountRequirementBlock
                               onSuccess:(void (^)(NSDictionary * params))onSuccessBlock
                               onFailure:(SHAccountErrorHandler)onFailureBlock; {
  

  
//  if([TWAPIManager isLocalTwitterAccountAvailable]) {
//    
//    [self requestAccessToTwitterAccounts:^(BOOL granted, NSError *error) {
//      if(granted) theAccountRequirementBlock(self.accountsTwitter, ^(ACAccount * theChosenAccount){
//        [self requestReverseOAuthWithAccount:theChosenAccount onSuccess:^(NSDictionary *parameters) {
//          onSuccessBlock(parameters);
//        } onFailure:onFailureBlock];
//      });
//      
//      else onFailureBlock(error);
//      
//    }];
//  }
//  else {
    [self requestSignedOAuthToTwitterOnSuccess:^(ACAccount *theChosenAccount) {
      [self requestAccessToTwitterAccounts:^(BOOL granted, NSError *error) {
        if(granted) theAccountRequirementBlock(self.accountsTwitter, ^(ACAccount * theChosenAccount){
          [self requestReverseOAuthWithAccount:theChosenAccount onSuccess:^(NSDictionary *parameters) {
            onSuccessBlock(parameters);
          } onFailure:onFailureBlock];
        });
        
        else onFailureBlock(error);
        
      }];

//      [self authenticateWithTwitterForAccount:^(NSArray *accounts, SHTwitterAccountPickerHandler pickAccount) {
//        pickAccount(theChosenAccount);
//        
//      } onSuccess:onSuccessBlock onFailure:onFailureBlock ];
      
    } onFailure:onFailureBlock];
//  }
}

-(void)requestSignedOAuthToTwitterOnSuccess:(SHTwitterAccountPickerHandler)onSuccessBlock
                                  onFailure:(SHAccountErrorHandler)onFailureBlock; {
  AFOAuth1Client *  twitterClient = [[AFOAuth1Client alloc]
                                     initWithBaseURL:[NSURL URLWithString:@"https://api.twitter.com/"]
                                     key:self.twitterConsumerKey secret:self.twitterConsumerSecret];
  
  [twitterClient authorizeUsingOAuthWithRequestTokenPath:@"oauth/request_token"
                                   userAuthorizationPath:@"oauth/authorize"
                                             callbackURL:[NSURL URLWithString:self.twitterCallbackUrl]
                                         accessTokenPath:@"oauth/access_token"
                                            accessMethod:@"POST" success:^(AFOAuth1Token *accessToken) {

                                              [self
                                               saveTwitterAccountWithToken:accessToken.key andSecret:accessToken.secret
                                               withCompletionHandler:^(ACAccount * account, NSError *error) {
                                                 if(account) onSuccessBlock(account);
                                                 if(error) onFailureBlock(error);
                                               }];
                                              
                                            } failure:onFailureBlock];
  
}


-(NSDictionary *)paramsFromQueryString:(NSString *)theQueryString; {
  //Look for alternative already built solutions. HTTP library should have a better one.
  NSArray             * parts      = [theQueryString componentsSeparatedByString:@"&"];
  NSMutableDictionary * parameters = @{}.mutableCopy;
  
  [parts enumerateObjectsUsingBlock:^(NSString * component, NSUInteger idx, BOOL *stop) {
    NSArray * subcomponents = [component componentsSeparatedByString:@"="];
    
    [parameters setObject:[[subcomponents objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                   forKey:[[subcomponents objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
  }];

  return parameters;
  
}

// OBFUSCATE YOUR KEYS!
-(NSString *)twitterConsumerKey; {
  NSString * consumerKey = TWAppCredentialStore.twitterAppKey;
  NSAssert(consumerKey.length > 0,
           @"You must register your Twitter App Key with TWAPIManager");
  return consumerKey;
}

// OBFUSCATE YOUR KEYS!
-(NSString *)twitterConsumerSecret; {
  NSString * consumerSecret = TWAppCredentialStore.twitterAppSecret;
  NSAssert(consumerSecret.length > 0,
           @"You must register your Twitter App Secret with TWAPIManager");
  return consumerSecret;
}



-(void)logErrorCode:(NSError *)theErrorCode; {
  //something went wrong, check value of error
  NSLog(@"the account was NOT saved - %@", theErrorCode.localizedDescription);
  
  // see the note below regarding errors...
  //  this is only for demonstration purposes
  if ([theErrorCode.domain isEqualToString:ACErrorDomain]) {
    // The following error codes and descriptions are found in ACError.h
    switch (theErrorCode.code) {
      case ACErrorAccountMissingRequiredProperty:
        NSLog(@"Account wasn't saved because "
              "it is missing a required property.");
        break;
      case ACErrorAccountAuthenticationFailed:
        NSLog(@"Account wasn't saved because "
              "authentication of the supplied "
              "credential failed.");
        break;
      case ACErrorAccountTypeInvalid:
        NSLog(@"Account wasn't saved because "
              "the account type is invalid.");
        break;
      case ACErrorAccountAlreadyExists:
        NSLog(@"Account wasn't added because "
              "it already exists.");
        break;
      case ACErrorAccountNotFound:
        NSLog(@"Account wasn't deleted because"
              "it could not be found.");
        break;
      case ACErrorPermissionDenied:
        NSLog(@"Permission Denied");
        break;
      case ACErrorUnknown:
      default: // fall through for any unknown errors...
        NSLog(@"An unknown error occurred.");
        break;
    }
  }
  else {
    // handle other error domains and their associated response codes...
    NSLog(@"%@", theErrorCode.localizedDescription);
  }
  
}

@end
