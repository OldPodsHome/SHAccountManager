//
//  SHViewController.m
//  SHAccountManagerExample
//
//  Created by Seivan Heidari on 3/13/13.
//  Copyright (c) 2013 Seivan Heidari. All rights reserved.
//

#import "SHViewController.h"
#import "SHAccountManager.h"
#import "UIActionSheet+BlocksKit.h"
#import "NSArray+BlocksKit.h"
#import "AFLinkedInOAuth1Client.h"
#import <Accounts/AccountsDefines.h>


ACCOUNTS_EXTERN NSString * const ACAccountTypeIdentifierLinkedIn; // = @"ACAccountTypeIdentifierLinkedIn";

@interface SHViewController ()
<UIAlertViewDelegate>
@property(nonatomic,strong) UIActivityIndicatorView * loader;

@property(nonatomic,strong) ACAccountType  * accountType;
@property(nonatomic,strong) ACAccountStore * accountStore;
@property(nonatomic,strong) ACAccount      * account;
@end

@implementation SHViewController

-(void)viewDidLoad; {
  [super viewDidLoad];
  [SHAccountManager registerTwitterAppKey:kTwitterKey andAppSecret:kTwitterSecret];
  
  self.loader = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  self.loader.color = UIColor.redColor;
  [self.view addSubview:self.loader];
  self.accountStore = [[ACAccountStore alloc] init];
  self.accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierLinkedIn];
  

  
  
}
-(void)viewDidAppear:(BOOL)animated; {
  [super viewDidAppear:animated];
//  [[[UIAlertView alloc] initWithTitle:@"Sample" message:@"Tap 'OK' login with twitter now" delegate:self
//                    cancelButtonTitle:@"OK"
//                    otherButtonTitles:nil, nil] show];
  [self.loader stopAnimating];
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
                                              
                                              
                                              [self.accountStore requestAccessToAccountsWithType:self.accountType options:nil completion:^(BOOL granted, NSError *error) {
                                                ACAccountCredential * credential = [[ACAccountCredential alloc]
                                                                                    initWithOAuthToken:accessToken.key tokenSecret:accessToken.secret];
                                                
                                                self.account = [[ACAccount alloc]
                                                                initWithAccountType:self.accountType];
                                              self.account.credential = credential;  
                                                [self.accountStore saveAccount:self.account withCompletionHandler:^(BOOL success, NSError *error) {
                                                  if(success || ( [error.domain isEqualToString:ACErrorDomain] && error.code ==ACErrorAccountAlreadyExists )) {
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

-(void)didReceiveMemoryWarning; {
  [super didReceiveMemoryWarning];
  
}

#pragma mark -
#pragma <UIAlertViewDelegate>
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex; {
  [self.loader startAnimating];
  [SHAccountManager.sharedManager authenticateWithTwitterForAccount:^(NSArray *accounts, SHTwitterAccountPickerHandler pickAccount) {
      [self.loader stopAnimating];
    UIActionSheet * actionSheet = [UIActionSheet actionSheetWithTitle:@"Please select your twitter account."];
    [accounts each:^(ACAccount * account) {
      [actionSheet addButtonWithTitle:account.username handler:^{
        pickAccount(account);
        [self.loader startAnimating];
      }];
    }];
    
    [actionSheet setCancelButtonWithTitle:nil handler:nil];
    [actionSheet showInView:self.view];

  } onSuccess:^(NSDictionary *params) {
   [self.loader stopAnimating];
    NSLog(@"%@", params);
    [[[UIAlertView alloc] initWithTitle:@"Sample" message:params.description delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil, nil] show];

  } onFailure:^(NSError *error) {
    [self showError:error];
    
  }];

}
-(void)showError:(NSError *)theError; {
  [self.loader stopAnimating];
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
