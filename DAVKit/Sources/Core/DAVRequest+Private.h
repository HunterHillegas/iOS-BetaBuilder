//
//  DAVRequest+Private.h
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

@class DAVSession;

@interface DAVRequest (Private)

- (void)setParentSession:(DAVSession *)parentSession;
- (NSMutableURLRequest *)newRequestWithPath:(NSString *)path method:(NSString *)method;

@end
