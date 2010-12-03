//
//  DAVRequest.m
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "DAVRequest.h"

#import "DAVCredentials.h"
#import "DAVSession.h"

@interface DAVRequest ()

- (void)_didFail:(NSError *)error;
- (void)_didFinish;

@end


@implementation DAVRequest

NSString *const DAVClientErrorDomain = @"com.MattRajca.DAVKit.error";

#define DEFAULT_TIMEOUT 60

@synthesize path = _path;
@synthesize delegate = _delegate;

- (id)initWithPath:(NSString *)aPath {
	NSParameterAssert(aPath != nil);
	
	self = [super init];
	if (self) {
		_path = [aPath copy];
	}
	return self;
}

- (NSString *)concatenatedURLWithPath:(NSString *)aPath {
	NSParameterAssert(aPath != nil);
	
	return [NSString stringWithFormat:@"%@/%@", _parentSession.rootURL, aPath];
}

- (BOOL)isConcurrent {
	return YES;
}

- (BOOL)isExecuting {
	return _executing;
}

- (BOOL)isFinished {
	return _done;
}

- (void)start {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(start) 
							   withObject:nil waitUntilDone:NO];
		
		return;
	}
	
	[self willChangeValueForKey:@"isExecuting"];
	
	_executing = YES;
	_connection = [[NSURLConnection connectionWithRequest:[self request]
												 delegate:self] retain];
	
	[self didChangeValueForKey:@"isExecuting"];
}

- (NSURLRequest *)request {
	@throw [NSException exceptionWithName:NSInternalInconsistencyException
								   reason:@"Subclasses of DAVRequest must override 'request'"
								 userInfo:nil];
	
	return nil;
}

- (id)resultForData:(NSData *)data {
	return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if (!_data) {
		_data = [[NSMutableData alloc] init];
	}
	
	[_data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self _didFail:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
	NSInteger code = [resp statusCode];
	
	if (code >= 400) {
		NSError *error = [NSError errorWithDomain:DAVClientErrorDomain
											 code:code
										 userInfo:nil];
		
		[self _didFail:error];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	
	DAVCredentials *cred = _parentSession.credentials;
	
	NSURLCredential *credential = [NSURLCredential credentialWithUser:cred.username
															 password:cred.password
														  persistence:NSURLCredentialPersistenceForSession];
	
	[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
}

- (void)_didFail:(NSError *)error {
	if ([_delegate respondsToSelector:@selector(request:didFailWithError:)]) {
		[_delegate request:self didFailWithError:[[error retain] autorelease]];
	}
	
	[self _didFinish];
}

- (void)_didFinish {
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isFinished"];
	
	_done = YES;
	_executing = YES;
	
	[self didChangeValueForKey:@"isExecuting"];
	[self didChangeValueForKey:@"isFinished"];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if ([_delegate respondsToSelector:@selector(request:didSucceedWithResult:)]) {
		id result = [self resultForData:_data];
		
		[_delegate request:self didSucceedWithResult:[[result retain] autorelease]];
	}
	
	[self _didFinish];
}

- (void)dealloc {
	[_path release];
	[_connection release];
	[_data release];
	
	[super dealloc];
}

@end


@implementation DAVRequest (Private)

- (NSMutableURLRequest *)newRequestWithPath:(NSString *)path method:(NSString *)method {
	NSURL *url = [NSURL URLWithString:[self concatenatedURLWithPath:path]];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
	[request setHTTPMethod:method];
	[request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval:DEFAULT_TIMEOUT];
	
	return request;
}

- (void)setParentSession:(DAVSession *)parentSession {
	_parentSession = parentSession;
}

@end
