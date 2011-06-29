//
//  main.m
//  BetaBuilder
//
//  Created by Hunter Hillegas on 8/7/10.
//  Copyright 2010 Hunter Hillegas. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "BuilderController.h"
#import "BetaBuilderAppDelegate.h"

int main(int argc, char *argv[])
{
    if (argc > 1 && sizeof(argv) > 1)
    {
        NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
        
        NSMutableArray *arguments = [NSMutableArray array];
        for (int i = 0; i < argc; ++i)
        {
            [arguments insertObject:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding] atIndex:(NSUInteger)i];
        }
        
        BuilderController *builderController = [[BuilderController alloc] init];
        
        /*
         Duplicating code here.
         */
        #define kArgumentSeperator @"="
        #define kIPAPathArgument @"-ipaPath"
        #define kWebserverArgument @"-webserver"
        #define kOutputDirectoryArgument @"-outputDirectory"
        
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
            [builderController setupFromIPAFile:ipaPath];
            [builderController generateFilesWithWebserverAddress:webserverAddress andOutputDirectory:outputPath];
        }
        /*
         End this code duplication.
         */

        [pool drain];
        return 0;

    }
    else
    {
        return NSApplicationMain(argc,  (const char **) argv);
    }
}
