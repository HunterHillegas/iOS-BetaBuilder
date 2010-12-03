//
//  DAVCredentials.h
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

/* Only Basic authentication is supported */

@interface DAVCredentials : NSObject {
  @private
	NSString *_username;
	NSString *_password;
}

@property (readonly) NSString *username;
@property (readonly) NSString *password;

+ (id)credentialsWithUsername:(NSString *)username password:(NSString *)password;
- (id)initWithUsername:(NSString *)username password:(NSString *)password;

@end
