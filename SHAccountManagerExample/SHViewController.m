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
@interface SHViewController ()
<UIAlertViewDelegate>
@property(nonatomic,strong) UIActivityIndicatorView * loader;
@end

@implementation SHViewController

-(void)viewDidLoad; {
  [super viewDidLoad];
  [SHAccountManager registerTwitterAppKey:kTwitterKey andAppSecret:kTwitterSecret];
  
  self.loader = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  self.loader.color = UIColor.redColor;
  [self.view addSubview:self.loader];

  
  
}
-(void)viewDidAppear:(BOOL)animated; {
  [super viewDidAppear:animated];
  [[[UIAlertView alloc] initWithTitle:@"Sample" message:@"Tap 'OK' login with twitter now" delegate:self
                    cancelButtonTitle:@"OK"
                    otherButtonTitles:nil, nil] show];
  [self.loader stopAnimating];
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
