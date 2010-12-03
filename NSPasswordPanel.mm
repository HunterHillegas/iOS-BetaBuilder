//
//  NSPasswordPanel.mm
//  BetaBuilder
//
//  Created by Samuel Toulouse on 03/12/10.
//  Copyright 2010 Pirate & Co. All rights reserved.
//

#import "NSPasswordPanel.h"


@implementation NSPasswordPanel

- (NSInteger)runModal {
	NSInteger result = [[NSApplication sharedApplication] runModalForWindow:self];
	[self close];
	return result;
}

- (NSString*)password {
	return [_passwordTextField stringValue];
}

- (IBAction)okButtonPressed:(id)sender {
	[[NSApplication sharedApplication] stopModalWithCode:NSOKButton];
}
- (IBAction)cancelButtonPressed:(id)sender {
	[[NSApplication sharedApplication] stopModalWithCode:NSCancelButton];
}

@end
