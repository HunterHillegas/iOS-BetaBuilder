//
//  DAVSession.m
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "DAVSession.h"

#import "DAVRequest.h"
#import "DAVRequest+Private.h"

@implementation DAVSession

@synthesize rootURL = _rootURL;
@synthesize credentials = _credentials;
@dynamic maxConcurrentRequests;

#define DEFAULT_CONCURRENT_REQS 2

- (id)initWithRootURL:(NSString *)url credentials:(DAVCredentials *)credentials {
	NSParameterAssert(url != nil);
	
	if (!credentials) {
		#ifdef DEBUG
			NSLog(@"Warning: No credentials were provided. Servers rarely grant anonymous access");	
		#endif
	}
	
	self = [super init];
	if (self) {
		_rootURL = [url copy];
		_credentials = [credentials retain];
		
		_queue = [[NSOperationQueue alloc] init];
		[_queue setMaxConcurrentOperationCount:DEFAULT_CONCURRENT_REQS];
	}
	return self;
}

- (NSInteger)maxConcurrentRequests {
	return [_queue maxConcurrentOperationCount];
}

- (void)setMaxConcurrentRequests:(NSInteger)aVal {
	[_queue setMaxConcurrentOperationCount:aVal];
}

- (void)enqueueRequest:(DAVRequest *)aRequest {
	NSParameterAssert(aRequest != nil);
	
	[aRequest setParentSession:self];
	[_queue addOperation:aRequest];
}

- (void)dealloc {
	[_queue release];
	[_rootURL release];
	[_credentials release];
	
	[super dealloc];
}

@end
