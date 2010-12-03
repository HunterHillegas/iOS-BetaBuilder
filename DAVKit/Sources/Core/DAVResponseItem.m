//
//  DAVResponseItem.m
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "DAVResponseItem.h"

@implementation DAVResponseItem

@synthesize href, modificationDate, contentLength, contentType;
@synthesize creationDate;

- (NSString *)description {
	return [NSString stringWithFormat:@"href = %@; modificationDate = %@; contentLength = %d; "
									  @"contentType = %@; creationDate = %@;",
									  href, modificationDate, contentLength, contentType,
									  creationDate];
}

- (void)dealloc {
	[href release];
	[modificationDate release];
	[contentType release];
	[creationDate release];
	
	[super dealloc];
}

@end
