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

@interface BetaBuilderAppDelegate ()

@property (nonatomic) BOOL runningInCommandLineSession;
@property (nonatomic, strong) NSDictionary *indexTemplateAlertPaths;

@end

@implementation BetaBuilderAppDelegate

@synthesize window = _window;
@synthesize deploymentHelpPanel = _deploymentHelpPanel;
@synthesize archiveIPAHelpPanel = _archiveIPAHelpPanel;
@synthesize builderController = _builderController;
@synthesize preferencesPanel = _preferencesPanel;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //Setup Drag Target for IPA Files
    [self.window registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    
    //Process Command Line Arguments, If Any
    self.runningInCommandLineSession = NO;
    NSArray *commandLineArgs = [[NSProcessInfo processInfo] arguments];
    if (commandLineArgs && [commandLineArgs count] > 0) {
        self.runningInCommandLineSession = [self processCommandLineArguments:commandLineArgs];
    }

    if (![[NSUserDefaults standardUserDefaults] valueForKey:kSupressTemplateWarning]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kSupressTemplateWarning];
    }

    //Copy HTML Template to App Support
    [self copyTemplatesIfNeededCommandLineArgs:commandLineArgs];
}

#pragma mark - Setup Templates

- (void)copyTemplatesIfNeededCommandLineArgs:(NSArray *)commandLineArgs {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    for (NSString *templatePath in [self htmlTemplatePaths]) {
        NSString *filename = [templatePath lastPathComponent];
        NSString *fileType = [filename pathExtension];

        NSString *templatePathInBundle = [[NSBundle mainBundle] pathForResource:[filename stringByDeletingPathExtension] ofType:fileType];

        if (![fileManager fileExistsAtPath:templatePath]) {
            NSLog(@"Copying Template: %@", templatePath);
            
            if (templatePathInBundle)
                [fileManager copyItemAtPath:templatePathInBundle toPath:templatePath error:nil];
        } else {
            if ([fileManager contentsEqualAtPath:templatePathInBundle andPath:templatePath]) {
                NSLog(@"Index Template Already Exists And They Are the Same - Not Copying From Bundle");
            } else {
                NSLog(@"Index Template Exists But Has Been Modified");

                if (!self.runningInCommandLineSession) { //only present this if we have no command line args
                    BOOL shouldSuppressAlert = [[NSUserDefaults standardUserDefaults] boolForKey:kSupressTemplateWarning];
                    if (!shouldSuppressAlert) {
                        self.indexTemplateAlertPaths = @{@"fromPath" : templatePathInBundle, @"toPath" : templatePath};

                        NSAlert *indexTemplateAlert = [NSAlert alertWithMessageText:@"A Newer Index Template File Exists" defaultButton:@"Do Nothing" alternateButton:@"Replace File" otherButton:nil informativeTextWithFormat:@"The template index file used to create the HTML output has been updated to include new functionality. It appears you alread have a version of this file in place (%@). Would you like to replace this file? Any customizations will be lost - you may want to backup the file first.", templatePath];
                        [indexTemplateAlert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:&_indexTemplateAlertPaths];
                    }
                }
            }
        }
    }
}

- (NSArray *)htmlTemplatePaths {
    NSMutableArray *templatePaths = [NSMutableArray array];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportPath = [fileManager applicationSupportDirectory];

    NSArray *templateNames = @[@"index_template.html", @"index_template_no_tether.html"];
    
    for (NSString *templateName in templateNames) {
        NSString *templatePath = [applicationSupportPath stringByAppendingPathComponent:templateName];
        [templatePaths addObject:templatePath];
    }

    return templatePaths;
}

#pragma mark - Command Line

#define kArgumentSeperator @"="
#define kIPAPathArgument @"-ipaPath"
#define kWebserverArgument @"-webserver"
#define kOutputDirectoryArgument @"-outputDirectory"
#define kTemplateArgument @"-template"

- (BOOL)processCommandLineArguments:(NSArray *)arguments {
    NSLog(@"Processing Command Line Arguments");

    BOOL processedArgs = NO;
    
    NSString *ipaPath = nil;
    NSString *webserverAddress = nil;
    NSString *outputPath = nil;
    NSString *templateFile = nil;
    
    for (NSString *argument in arguments) {
        NSArray *splitArgument = [argument componentsSeparatedByString:kArgumentSeperator];
        
        if ([splitArgument count] == 2) {
            if ([[splitArgument objectAtIndex:0] isEqualToString:kIPAPathArgument]) {
                ipaPath = [splitArgument objectAtIndex:1];
            } else if ([[splitArgument objectAtIndex:0] isEqualToString:kWebserverArgument]) {
                webserverAddress = [splitArgument objectAtIndex:1];
            } else if ([[splitArgument objectAtIndex:0] isEqualToString:kOutputDirectoryArgument]) {
                outputPath = [splitArgument objectAtIndex:1];
            } else if ([[splitArgument objectAtIndex:0] isEqualToString:kTemplateArgument]) {
                templateFile = [splitArgument objectAtIndex:1];
            }
        }
    }
    
    if (ipaPath && webserverAddress && outputPath) {
        if (templateFile) {
            self.builderController.templateFile = templateFile;
        }
        
        [self.builderController setupFromIPAFile:ipaPath];
        [self.builderController generateFilesWithWebserverAddress:webserverAddress andOutputDirectory:outputPath];
        
        [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];

        processedArgs = YES;
    }

    return processedArgs;
}

#pragma mark - Alert

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {    
    if (returnCode == NSAlertAlternateReturn) {
        if (contextInfo) {
            NSLog(@"Remove Existing Index File %@", self.indexTemplateAlertPaths[@"toPath"]);

            NSFileManager *fileManager = [NSFileManager defaultManager];

            [fileManager removeItemAtPath:self.indexTemplateAlertPaths[@"toPath"] error:nil];
            
            [fileManager copyItemAtPath:self.indexTemplateAlertPaths[@"fromPath"] toPath:self.indexTemplateAlertPaths[@"toPath"] error:nil];
        }
    } else if (returnCode == NSAlertDefaultReturn) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSupressTemplateWarning];
    }
}

- (IBAction)showDeploymentHelpPanel:(id)sender {
	[self.deploymentHelpPanel setIsVisible:YES];
}

- (IBAction)showArchiveHelpPanel:(id)sender {
	[self.archiveIPAHelpPanel setIsVisible:YES];
}

- (IBAction)showPreferencesPanel:(id)sender {
    [self.preferencesPanel setIsVisible:YES];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	[self.builderController setupFromIPAFile:filename];
	
	return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
