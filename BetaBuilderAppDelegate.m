//
//  BetaBuilderAppDelegate.m
//  BetaBuilder
//
//  Created by Hunter Hillegas on 8/7/10.
//  Copyright 2010 Hunter Hillegas. All rights reserved.
//

/* 
 iOS BetaBuilder - a tool for simpler iOS betas
 Version 1.6
 
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
    //Setup Drag Target for IPA Files
    [window registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    
    //Process Command Line Arguments, If Any
    NSArray *commandLineArgs = [[NSProcessInfo processInfo] arguments];
    if (commandLineArgs && [commandLineArgs count] > 0) {
        [self processCommandLineArguments:commandLineArgs];
    }
    
    //Copy HTML Template to App Support
    NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:[self htmlTemplatePath]]) {
		NSLog(@"Copying Index Template");
		
		if ([self defaultTemplatePath])
			[fileManager copyItemAtPath:[self defaultTemplatePath] toPath:[self htmlTemplatePath] error:nil];
	} else {
        if ([fileManager contentsEqualAtPath:[self defaultTemplatePath] andPath:[self htmlTemplatePath]]) {
            NSLog(@"Index Template Already Exists And They Are the Same - Not Copying From Bundle");
        } else {
            NSLog(@"Index Template Exists But Has Been Modified");
            
            NSString *infoText = [NSString stringWithFormat:@"The template index file used to create the HTML output has been updated to include new functionality. It appears you alread have a version of this file in place (%@). Would you like to replace this file? Any customizations will be lost - you may want to backup the file first.", [self htmlTemplatePath]];
            
            NSAlert *indexTemplateAlert = [[NSAlert alertWithMessageText:@"A Newer Index Template File Exists" defaultButton:@"Do Nothing" alternateButton:@"Replace File" otherButton:nil informativeTextWithFormat:infoText] autorelease];
            [indexTemplateAlert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        }
    }
}

- (NSString *)htmlTemplatePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportPath = [fileManager applicationSupportDirectory];
    NSString *templatePath = [applicationSupportPath stringByAppendingPathComponent:@"index_template.html"];    
    
    return templatePath;
}

- (NSString *)defaultTemplatePath {
    return [[NSBundle mainBundle] pathForResource:@"index_template" ofType:@"html"];
}

#pragma mark - Command Line

#define kArgumentSeperator @"="
#define kIPAPathArgument @"-ipaPath"
#define kWebserverArgument @"-webserver"
#define kOutputDirectoryArgument @"-outputDirectory"

- (void)processCommandLineArguments:(NSArray *)arguments {
    NSLog(@"Processing Command Line Arguments");
    
    NSString *ipaPath = nil;
    NSString *webserverAddress = nil;
    NSString *outputPath = nil;
    
    for (NSString *argument in arguments) {
        NSArray *splitArgument = [argument componentsSeparatedByString:kArgumentSeperator];
        
        if ([splitArgument count] == 2) {
            if ([[splitArgument objectAtIndex:0] isEqualToString:kIPAPathArgument]) {
                ipaPath = [splitArgument objectAtIndex:1];
            } else if ([[splitArgument objectAtIndex:0] isEqualToString:kWebserverArgument]) {
                webserverAddress = [splitArgument objectAtIndex:1];
            } else if ([[splitArgument objectAtIndex:0] isEqualToString:kOutputDirectoryArgument]) {
                outputPath = [splitArgument objectAtIndex:1];
            }
        }
    }
    
    if (ipaPath && webserverAddress && outputPath) {
        [self.builderController setupFromIPAFile:ipaPath];
        [self.builderController generateFilesWithWebserverAddress:webserverAddress andOutputDirectory:outputPath];
        [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
    }
}

#pragma mark - Alert

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {    
    if (returnCode == NSAlertAlternateReturn) {
        NSLog(@"Remove Existing Index File");
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:[self htmlTemplatePath] error:nil];
        [fileManager copyItemAtPath:[self defaultTemplatePath] toPath:[self htmlTemplatePath] error:nil];
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

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
