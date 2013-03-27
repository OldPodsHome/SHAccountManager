//
//  SHOmniAuthViewController.m
//  SHAccountManagerExample
//
//  Created by Seivan Heidari on 3/23/13.
//  Copyright (c) 2013 Seivan Heidari. All rights reserved.
//

#import "SHOmniAuthViewController.h"
#import "SHAccountStore.h"
#import "SHOmniAuth.h"
#import "SHOmniAuthLinkedIn.h"
#import "SHOmniAuthTwitter.h"
#import "SHRequest.h"

#import "UIActionSheet+BlocksKit.h"






@interface SHOmniAuthViewController ()

@end

@implementation SHOmniAuthViewController

-(void)viewDidAppear:(BOOL)animated; {
    dispatch_semaphore_t semaphore =  dispatch_semaphore_create(0);
  [super viewDidAppear:animated];
  [SHOmniAuthTwitter performLoginWithListOfAccounts:^(NSArray *accounts, SHOmniAuthAccountPickerHandler pickAccountBlock) {
    pickAccountBlock(accounts.lastObject); // If nil, will issue an oAuth request (login basically)
  } onComplete:^(id<account> account, id response, NSError *error, BOOL isSuccess) {
    NSLog(@"%@ - %@", response, error);
    dispatch_semaphore_signal(semaphore);
  }];
  
  __block SHAccount * linkedInAccount = nil;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    dispatch_async(dispatch_get_main_queue(), ^{

      [SHOmniAuthLinkedIn performLoginWithListOfAccounts:^(NSArray *accounts, SHOmniAuthAccountPickerHandler pickAccountBlock) {
        pickAccountBlock(accounts.lastObject); // If nil, will issue an oAuth request (login basically)
      } onComplete:^(id<account> account, id response, NSError *error, BOOL isSuccess) {
        NSLog(@"%@ - %@",response, error);
        linkedInAccount = (SHAccount *)account;
        dispatch_semaphore_signal(semaphore);
      }];
      
    });
    
    

      dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
      dispatch_async(dispatch_get_main_queue(), ^{
        SHRequest * request = [SHRequest requestForServiceType:SHOmniAuthLinkedIn.serviceType requestMethod:SHRequestMethodGET URL:[NSURL URLWithString:@"https://api.linkedin.com/v1/people/~?format=json"] parameters:nil];
        request.account = (id<account>)linkedInAccount;
        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
          NSDictionary * response =  [NSJSONSerialization
                                      JSONObjectWithData:responseData options:0 error:nil];
          NSLog(@"%@, %@", response, error);
        }];

      });
    
    });
    


  

  

}


@end
