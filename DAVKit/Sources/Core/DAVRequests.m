//
//  DAVRequests.m
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "DAVRequests.h"

#import "DAVListingParser.h"
#import "DAVRequest+Private.h"

@implementation DAVCopyRequest

@synthesize destinationPath = _destinationPath;
@synthesize overwrite = _overwrite;

- (NSString *)method {
	return @"COPY";
}

- (NSURLRequest *)request {
	NSParameterAssert(_destinationPath != nil);
	
	NSString *dp = [self concatenatedURLWithPath:_destinationPath];
	
	NSMutableURLRequest *req = [self newRequestWithPath:self.path
												 method:[self method]];
	
	[req setValue:dp forHTTPHeaderField:@"Destination"];
	
	if (_overwrite)
		[req setValue:@"T" forHTTPHeaderField:@"Overwrite"];
	else
		[req setValue:@"F" forHTTPHeaderField:@"Overwrite"];
	
	return [req autorelease];
}

- (void)dealloc {
	[_destinationPath release];
	[super dealloc];
}

@end


@implementation DAVDeleteRequest

- (NSURLRequest *)request {
	return [[self newRequestWithPath:self.path method:@"DELETE"] autorelease];
}

@end


@implementation DAVGetRequest

- (NSURLRequest *)request {
	return [[self newRequestWithPath:self.path method:@"GET"] autorelease];
}

- (id)resultForData:(NSData *)data {
	return data;
}

@end


@implementation DAVListingRequest

@synthesize depth = _depth;

- (id)initWithPath:(NSString *)aPath {
	self = [super initWithPath:aPath];
	if (self) {
		_depth = 1;
	}
	return self;
}

- (NSURLRequest *)request {
	NSMutableURLRequest *req = [self newRequestWithPath:self.path method:@"PROPFIND"];
	
	if (_depth > 1) {
		[req setValue:@"infinity" forHTTPHeaderField:@"Depth"];
	}
	else {
		[req setValue:[NSString stringWithFormat:@"%d", _depth] forHTTPHeaderField:@"Depth"];
	}
	
	[req setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
	
	NSString *xml = @"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
					@"<D:propfind xmlns:D=\"DAV:\"><D:allprop/></D:propfind>";
	
	[req setHTTPBody:[xml dataUsingEncoding:NSUTF8StringEncoding]];
	
	return [req autorelease];
}

- (id)resultForData:(NSData *)data {
	DAVListingParser *p = [[DAVListingParser alloc] initWithData:data];
	
	NSError *error = nil;
	NSArray *items = [p parse:&error];
	
	#ifdef DEBUG
		NSLog(@"XML Parse error: %@", error);
	#endif
	
	[p release];
	
	return items;
}

@end


@implementation DAVMakeCollectionRequest

- (NSURLRequest *)request {
	return [[self newRequestWithPath:self.path method:@"MKCOL"] autorelease];
}

@end


@implementation DAVMoveRequest

- (NSString *)method {
	return @"MOVE";
}

@end


@implementation DAVPutRequest

@synthesize data = _pdata;

- (NSURLRequest *)request {
	NSParameterAssert(_pdata != nil);
	
	NSString *len = [NSString stringWithFormat:@"%d", [_pdata length]];
	
	NSMutableURLRequest *req = [self newRequestWithPath:self.path method:@"PUT"];
	[req setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
	[req setValue:len forHTTPHeaderField:@"Content-Length"];
    [req setHTTPBody:_pdata];
	
	return [req autorelease];
}

- (void)dealloc {
	[_pdata release];
	[super dealloc];
}

@end
