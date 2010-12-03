//
//  DAVListingParser.m
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "DAVListingParser.h"

#import "DAVResponseItem.h"
#import "ISO8601DateFormatter.h"

@interface DAVListingParser ()

- (NSDate *)_ISO8601DateWithString:(NSString *)aString;

@end


@implementation DAVListingParser

- (id)initWithData:(NSData *)data {
	NSParameterAssert(data != nil);
	
	self = [super init];
	if (self) {
		_items = [[NSMutableArray alloc] init];
		
		_parser = [[NSXMLParser alloc] initWithData:data];
		[_parser setDelegate:self];
		[_parser setShouldProcessNamespaces:YES];
	}
	return self;
}

- (NSArray *)parse:(NSError **)error {
	if (![_parser parse]) {
		if (error) {
			*error = [_parser parserError];
		}
		
		return nil;
	}
	
	return [[_items copy] autorelease];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	[_currentString appendString:string];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
	attributes:(NSDictionary *)attributeDict {
	
	if (_currentString) {
		[_currentString release];
		_currentString = nil;
	}
	
	_currentString = [[NSMutableString alloc] init];
	
	if ([elementName isEqualToString:@"response"]) {
		_currentItem = [[DAVResponseItem alloc] init];
	}
}

- (NSDate *)_ISO8601DateWithString:(NSString *)aString {
	ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
	
	NSDate *date = [formatter dateFromString:aString];
	[formatter release];
	
	return date;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
	if ([elementName isEqualToString:@"href"]) {
		_currentItem.href = _currentString;
	}
	else if ([elementName isEqualToString:@"getcontentlength"]) {
		_currentItem.contentLength = [_currentString integerValue];
	}
	else if ([elementName isEqualToString:@"getcontenttype"]) {
		_currentItem.contentType = _currentString;
	}
	else if ([elementName isEqualToString:@"modificationdate"]) {
		_currentItem.modificationDate = [self _ISO8601DateWithString:_currentString];
	}
	else if ([elementName isEqualToString:@"creationdate"]) {
		_currentItem.creationDate = [self _ISO8601DateWithString:_currentString];
	}
	else if ([elementName isEqualToString:@"response"]) {
		[_items addObject:_currentItem];
		
		[_currentItem release];
		_currentItem = nil;
	}
	
	[_currentString release];
    _currentString = nil;
}

- (void)dealloc {
	[_parser release];
	[_currentString release];
	[_items release];
	[_currentItem release];
	
	[super dealloc];
}

@end
