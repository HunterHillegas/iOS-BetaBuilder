//
//  BetaBuilderAppDelegate.m
//  BetaBuilder
//
//  Created by Hunter Hillegas on 8/7/10.
//  Copyright 2010 Hunter Hillegas. All rights reserved.
//

/* 
 iOS BetaBuilder - a tool for simpler iOS betas
 Version 1.5, January 2011
 
 Condition of use and distribution:
 
 This software is provided 'as-is', without any express or implied
 warranty.  In no event will the authors be held liable for any damages
 arising from the use of this software.
 
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it
 freely, subject to the following restrictions:
 
 1. The origin of this software must not be misrepresented; you must not
 claim that you wrote the original software. If you use this software
 in a product, an acknowledgment in the product documentation would be
 appreciated but is not required.
 2. Altered source versions must be plainly marked as such, and must not be
 misrepresented as being the original software.
 3. This notice may not be removed or altered from any source distribution.
 */

#import "BetaBuilderAppDelegate.h"
#import "BuilderController.h"

#import "NSFileManager+DirectoryLocations.h"

@implementation BetaBuilderAppDelegate

@synthesize window;
@synthesize deploymentHelpPanel;
@synthesize archiveIPAHelpPanel;
@synthesize builderController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //Copy HTML Template to App Support
	NSString *applicationSupportPath = [[NSFileManager defaultManager] applicationSupportDirectory];
    NSString *htmlTemplatePath = [applicationSupportPath stringByAppendingPathComponent:@"index_template.html"];
    
	NSString *defaultTemplatePath = [[NSBundle mainBundle] pathForResource:@"index_template" ofType:@"html"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if (![fileManager fileExistsAtPath:htmlTemplatePath]) {
		NSLog(@"Copying Index Template");
		
		if (defaultTemplatePath) {
			[fileManager copyItemAtPath:defaultTemplatePath toPath:htmlTemplatePath error:nil];
		}
	} else {
        NSLog(@"Index Template Already Exists - Not Copying From Bundle");
    }
}

- (IBAction)showDeploymentHelpPanel:(id)sender {
	[deploymentHelpPanel setIsVisible:YES];
}

- (IBAction)showArchiveHelpPanel:(id)sender {
	[archiveIPAHelpPanel setIsVisible:YES];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	[self.builderController setupFromIPAFile:filename];
	
	return YES;
}

@end
