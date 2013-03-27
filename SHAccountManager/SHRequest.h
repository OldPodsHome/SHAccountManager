//
//  SHRequest.h
//  SHAccountManagerExample
//
//  Created by Seivan Heidari on 3/23/13.
//  Copyright (c) 2013 Seivan Heidari. All rights reserved.
//




#import "SHOmniAuthProvider.h"

typedef NS_ENUM(NSInteger, SHRequestMethod)  {
  SHRequestMethodGET,
  SHRequestMethodPOST,
  SHRequestMethodDELETE,
  SHRequestMethodUPDATE
};


// Completion block for performRequestWithHandler.
typedef void(^SHRequestHandler)(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error);


@interface SHRequest : NSObject


+ (SHRequest *)requestForServiceType:(NSString *)serviceType requestMethod:(SHRequestMethod)requestMethod URL:(NSURL *)url parameters:(NSDictionary *)parameters;

// Optional account information used to authenticate the request. Defaults to nil.
@property(NS_NONATOMIC_IOSONLY, retain) id<account>  account;

// The request method
@property(NS_NONATOMIC_IOSONLY,readonly) SHRequestMethod requestMethod;

// The request URL
@property(NS_NONATOMIC_IOSONLY,readonly) NSURL * URL;

// The parameters
@property(NS_NONATOMIC_IOSONLY,readonly) NSDictionary * parameters;

//#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
//// Specify a named MIME multi-part value. As of iOS 6.0, if you set parameters,
//// the parameters will automatically be added as form data in the multi-part data.
//- (void)addMultipartData:(NSData *)data
//withName:(NSString *)name
//type:(NSString *)type
//filename:(NSString *)filename NS_AVAILABLE_IOS(6_0);
//#else
//- (void)addMultipartData:(NSData *)data
//withName:(NSString *)name
//type:(NSString*)type NS_AVAILABLE_MAC(10_8);
//#endif

// Returns a NSURLRequest for use with NSURLConnection.
// If an account has been set the returned request is either signed (OAuth1),
// or has the appropriate token set (OAuth2)
-(NSURLRequest *)preparedURLRequest;

// Issue the request. This block is not guaranteed to be called on any particular thread.
-(void)performRequestWithHandler:(SHRequestHandler)handler;
@end
