//
//  SHAccountType.h
//  SHAccountManagerExample
//
//  Created by Seivan Heidari on 3/20/13.
//  Copyright (c) 2013 Seivan Heidari. All rights reserved.
//

//#import <Accounts/Accounts.h>

// The identifiers for supported system account types are listed here:
//ACCOUNTS_EXTERN NSString * const ACAccountTypeIdentifierTwitter NS_AVAILABLE(NA, 5_0);
//ACCOUNTS_EXTERN NSString * const ACAccountTypeIdentifierFacebook NS_AVAILABLE(NA, 6_0);
//ACCOUNTS_EXTERN NSString * const ACAccountTypeIdentifierSinaWeibo NS_AVAILABLE(NA, 6_0);

// Each account has an associated account type, containing information relevant to all the accounts of that type.
// SHAccountType objects are obtained by using the [SHAccountStore accountTypeWithIdentifier:] method
// or accessing the accountType property for a particular account object. They may also be used to find
// all the accounts of a particular type using [SHAccountStore accountsWithAccountType:]


@interface SHAccountType :  NSObject//ACAccountType
<NSCoding>
// A human readable description of the account type.
@property(NS_NONATOMIC_IOSONLY,readonly) NSString * accountTypeDescription;

// A unique identifier for the account type. Well known system account type identifiers are listed above.
@property(NS_NONATOMIC_IOSONLY,readonly) NSString * identifier;

// A boolean indicating whether the user has granted access to accounts of this type for your application.
@property(NS_NONATOMIC_IOSONLY,readonly) BOOL      accessGranted;

@end
