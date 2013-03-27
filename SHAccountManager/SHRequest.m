//
//  SHRequest.m
//  SHAccountManagerExample
//
//  Created by Seivan Heidari on 3/23/13.
//  Copyright (c) 2013 Seivan Heidari. All rights reserved.
//

#import "SHRequest.h"
#import "OAuthCore.h"
#import "SHOmniAuth.h"
#import "SHOmniAuthProviderPrivates.h"


@interface SHRequest ()
-(NSString *)toStringForRequestMethod:(SHRequestMethod)theRequestMethod;
@property(nonatomic,strong) NSMutableURLRequest * currentRequest;
@property(nonatomic,strong) NSString * serviceType;
@property(nonatomic,strong) NSDictionary * parameters;
@property(nonatomic,strong) NSData * bodyData;

@end

@implementation SHRequest
+(SHRequest *)requestForServiceType:(NSString *)serviceType requestMethod:(SHRequestMethod)requestMethod URL:(NSURL *)url parameters:(NSDictionary *)parameters; {
  NSAssert(serviceType, @"Must pass a serviceType");
  SHRequest * request = [[SHRequest alloc] init];
  request.serviceType = serviceType;
  request.currentRequest = [NSMutableURLRequest requestWithURL:url];
  [request.currentRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  [request.currentRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  [request.currentRequest setHTTPMethod:[request toStringForRequestMethod:requestMethod]];
  request.parameters = parameters;
  NSMutableString *paramsAsString = [[NSMutableString alloc] init];
  [parameters enumerateKeysAndObjectsUsingBlock:
   ^(id key, id obj, BOOL *stop) {
     [paramsAsString appendFormat:@"%@=%@&", key, obj];
   }];
  
  request.bodyData = [paramsAsString dataUsingEncoding:NSUTF8StringEncoding];
  [request.currentRequest setHTTPBody:request.bodyData];

  
  return request;
}

-(NSURLRequest *)preparedURLRequest; {
  return self.currentRequest.copy;
}

-(void)setAccount:(id<accountPrivate>)account; {
//  NSAssert(account, @"Must pass an account");
//  NSAssert(account.credential, @"account must have credential");
//  NSAssert(account.credential.token, @"credential must have token");
//  NSAssert(account.credential.secret, @"credential must have secret");
  _account = account;
  NSString *authorizationHeader = OAuthorizationHeader(self.currentRequest.URL,
                                                       [self toStringForRequestMethod:self.requestMethod],
                                                       self.bodyData,
                                                       [SHOmniAuth providerValue:SHOmniAuthProviderValueKey
                                                                     forProvider:account.accountType.identifier],
                                                       [SHOmniAuth providerValue:SHOmniAuthProviderValueSecret
                                                                     forProvider:account.accountType.identifier],
                                                       account.credential.token,
                                                       account.credential.secret);
  [self.currentRequest setValue:authorizationHeader forHTTPHeaderField:@"Authorization"];


}



-(void)performRequestWithHandler:(SHRequestHandler)handler; {
//  NSAssert(self.account, @"Must have an account");
  [NSURLConnection sendAsynchronousRequest:self.currentRequest queue:[NSOperationQueue mainQueue]
                         completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
                           handler(data, (NSHTTPURLResponse*)response, error.copy);
  }];
}

-(NSString *)toStringForRequestMethod:(SHRequestMethod)theRequestMethod; {
  NSAssert(theRequestMethod >= 0 && theRequestMethod <= 3, @"Must the request method");
  NSString * toStringForRequestMethod = nil;
  switch (theRequestMethod) {
    case SHRequestMethodGET:
      toStringForRequestMethod = @"GET";
      break;
    case SHRequestMethodPOST:
      toStringForRequestMethod = @"POST";
      break;
    case SHRequestMethodDELETE:
      toStringForRequestMethod = @"DELETE";
      break;
    case SHRequestMethodUPDATE:
      toStringForRequestMethod = @"UPDATE";
      break;
    default:
      break;
  }
  return toStringForRequestMethod;
}

-(NSDictionary *)parameters; {
  return _parameters;
}

@end

