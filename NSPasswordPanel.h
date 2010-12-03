//
//  NSPasswordPanel.h
//  BetaBuilder
//
//  Created by Samuel Toulouse on 03/12/10.
//  Copyright 2010 Pirate & Co. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSPasswordPanel : NSPanel {
	IBOutlet NSSecureTextField*	_passwordTextField;
}

- (NSString*)password;
- (IBAction)okButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;
- (NSInteger)runModal;

@end
