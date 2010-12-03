//
//  DAVResponseItem.h
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

@interface DAVResponseItem : NSObject {
  @private
	NSString *href;
	NSDate *modificationDate;
	NSInteger contentLength;
	NSString *contentType;
	NSDate *creationDate;
}

@property (copy) NSString *href;
@property (retain) NSDate *modificationDate;
@property (assign) NSInteger contentLength;
@property (retain) NSString *contentType;
@property (retain) NSDate *creationDate;

@end
