//
//  DAVSession.h
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

@class DAVCredentials;
@class DAVRequest;

/* All paths are relative to the root of the server */

@interface DAVSession : NSObject {
  @private
	NSString *_rootURL;
	DAVCredentials *_credentials;
	NSOperationQueue *_queue;
}

@property (readonly) NSString *rootURL;
@property (readonly) DAVCredentials *credentials;

@property (assign) NSInteger maxConcurrentRequests; /* default is 2 */

/*
 The root URL should include a scheme and host, followed by any root paths
 **NOTE: omit the trailing slash (/)**
 Example: http://idisk.me.com/steve
*/
- (id)initWithRootURL:(NSString *)url credentials:(DAVCredentials *)credentials;

- (void)enqueueRequest:(DAVRequest *)aRequest;

@end
