//
//  SHSampleViewController.m
//  SHAccountManagerExample
//
//  Created by Seivan Heidari on 3/20/13.
//  Copyright (c) 2013 Seivan Heidari. All rights reserved.
//

#import "SHSampleViewController.h"
#import "SHAccountStore.h"
#import "SHAccount.h"
#import "SHAccountCredential.h"
#import "SHAccountType.h"
#import "AFLinkedInOAuth1Client.h"
#import <Social/Social.h>
#import "OAuthCore.h"
#import "AFJSONRequestOperation.h"

@interface SHSampleViewController ()
@property(nonatomic,strong) SHAccount * account;
@property(nonatomic,strong) SHAccountType * accountType;
@property(nonatomic,strong) SHAccountStore * accountStore;
@end

@implementation SHSampleViewController


-(void)viewDidAppear:(BOOL)animated; {
  [super viewDidAppear:animated];
  self.accountStore = [[SHAccountStore alloc] init];
  self.accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:@"LinkedIn"];
  
  AFLinkedInOAuth1Client *  linkedInClient = [[AFLinkedInOAuth1Client alloc]
                                              initWithBaseURL:[NSURL URLWithString:@"https://api.linkedin.com/"]
                                              key:@"xNyRENCoCU14DzynxzPcQeoOyVGktxQSNh9ZIf-Bu_wBjxBJC7ZksXJVpMONbnt1"
                                              secret:@"fw7WYUDeEZM-_kk7lHL_4b3-ErAWOmOLoqsev9RvRh8iIc_mfuQ2ULizrv5KO6TL"];
  
  [linkedInClient authorizeUsingOAuthWithRequestTokenPath:@"uas/oauth/requestToken"
                                    userAuthorizationPath:@"uas/oauth/authorize"
                                              callbackURL:[NSURL URLWithString:@"af-twitter://success"]
                                          accessTokenPath:@"uas/oauth/accessToken"
                                             accessMethod:@"POST" success:^(AFOAuth1Token *accessToken) {
                                               
                                               NSLog(@"Success");
                                               [linkedInClient registerHTTPOperationClass:[AFJSONRequestOperation class]];

                                               [linkedInClient getPath:@"v1/people/~" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 NSLog(@"%@", responseObject);
                                               } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 NSLog(@"%@", error);
                                               }];
                                               
                                               [self.accountStore requestAccessToAccountsWithType:self.accountType options:nil completion:^(BOOL granted, NSError *error) {
                                                 NSLog(@"%@", accessToken);
                                                 SHAccountCredential * credential = [[SHAccountCredential alloc]
                                                                                     initWithOAuthToken:accessToken.key tokenSecret:accessToken.secret];
                                                 
                                                 self.account = [[SHAccount alloc]
                                                                 initWithAccountType:self.accountType];
                                                 self.account.credential = credential;

                                                 [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
                                                   NSURL * url = [NSURL URLWithString:@"https://api.linkedin.com/v1/people/~?scope=r_fullprofile&format=json"];
                                                   NSData *bodyData = [@"" dataUsingEncoding:NSUTF8StringEncoding];
                                                   NSString *authorizationHeader = OAuthorizationHeader(url,
                                                                                                        @"GET",
                                                                                                        bodyData,
                                                                                                        @"xNyRENCoCU14DzynxzPcQeoOyVGktxQSNh9ZIf-Bu_wBjxBJC7ZksXJVpMONbnt1",
                                                                                                        @"fw7WYUDeEZM-_kk7lHL_4b3-ErAWOmOLoqsev9RvRh8iIc_mfuQ2ULizrv5KO6TL",
                                                                                                        accessToken.key,
                                                                                                        accessToken.secret);
                                                   
                                                   NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                                                                   initWithURL:url];
                                                   [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                                                   [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

                                                   [request setHTTPMethod:@"GET"];
                                                   [request setValue:authorizationHeader
                                                  forHTTPHeaderField:@"Authorization"];
                                                   [request setHTTPBody:bodyData];
                                                   NSURLResponse *response;
                                                   NSError *errorTwo;
                                                   NSData *data = [NSURLConnection
                                                                   sendSynchronousRequest: request returningResponse:&response error:&errorTwo];
                                                   NSString * dataResponse = [[NSString alloc ] initWithData:data encoding:NSUTF8StringEncoding];
                                                   NSLog(@"Response %@", dataResponse);
                                                   

                                                   
                                                 }];
                                                 

                                                 [self.accountStore saveAccount:self.account withCompletionHandler:^(BOOL success, NSError *error) {
                                                   if(success || ( [error.domain isEqualToString:SHErrorDomain] && error.code ==SHErrorAccountAlreadyExists )) {
                                                     NSLog(@"%@", self.account);
                                                   }
                                                   else {
                                                     self.account = nil;
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                       [self showError:error];
                                                     });
                                                     
                                                     
                                                   }
                                                 }];
                                                 
                                               }];
                                               
                                               
                                               
                                             } failure:^(NSError *error) {
                                               [self showError:error];
                                             }];

  
}

-(void)showError:(NSError *)theError; {

  NSString * title   = theError.localizedDescription;
  NSString * message = theError.localizedRecoverySuggestion;
  NSLog(@"ERROR %@", theError.userInfo);
  NSLog(@"ERROR %@", theError.localizedDescription);
  NSLog(@"ERROR %@", theError.localizedFailureReason);
  NSLog(@"ERROR %@", theError.localizedRecoveryOptions);
  NSLog(@"ERROR %@", theError.localizedRecoverySuggestion);
  
  if(title == nil)   title   = @"Error";
  if(message == nil) message = @"Somethin' ain't right, son.";
  
  [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil
                    cancelButtonTitle:@"OK"
                    otherButtonTitles:nil, nil] show];
}


@end
