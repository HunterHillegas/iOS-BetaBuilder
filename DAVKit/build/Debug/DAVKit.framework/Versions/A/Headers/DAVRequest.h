//
//  DAVRequest.h
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

@class DAVSession;
@protocol DAVRequestDelegate;

/* codes returned are HTTP status codes */
extern NSString *const DAVClientErrorDomain;

@interface DAVRequest : NSOperation {
  @private
	NSString *_path;
	NSURLConnection *_connection;
	NSMutableData *_data;
	BOOL _done;
	BOOL _executing;
	
	__weak DAVSession *_parentSession;
	__weak id < DAVRequestDelegate > _delegate;
}

@property (readonly) NSString *path;

@property (assign) __weak id < DAVRequestDelegate > delegate;

- (id)initWithPath:(NSString *)aPath;

- (NSString *)concatenatedURLWithPath:(NSString *)aPath;

/* must be overriden by subclasses */
- (NSURLRequest *)request;

/* optional override */
- (id)resultForData:(NSData *)data;

@end


@protocol DAVRequestDelegate < NSObject >

@optional

// The error can be a NSURLConnection error or a WebDAV error
- (void)request:(DAVRequest *)aRequest didFailWithError:(NSError *)error;

// The resulting object varies depending on the request type
- (void)request:(DAVRequest *)aRequest didSucceedWithResult:(id)result;

@end
