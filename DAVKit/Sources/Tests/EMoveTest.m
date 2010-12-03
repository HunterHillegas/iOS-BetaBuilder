//
//  EMoveTest.m
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "EMoveTest.h"

@implementation EMoveTest

- (void)testRequest {
	DAVCopyRequest *req = [[DAVCopyRequest alloc] initWithPath:@"davkittest/filetest22.txt"];
	req.destinationPath = @"davkittest/filetest24.txt";
	req.delegate = self;
	
	STAssertNotNil(req, @"Couldn't create the request");
	
	[self.session enqueueRequest:req];
	[req release];
	
	[self waitUntilWeAreDone];
}

- (void)request:(DAVRequest *)aRequest didSucceedWithResult:(id)result {
	STAssertNil(result, @"No result expected for MOVE");
	
	[self notifyDone];
}

@end
