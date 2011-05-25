//
//  BetaBuilderWindow.m
//  BetaBuilder
//
//  Created by Hunter Hillegas on 5/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BetaBuilderWindow.h"

#import "BetaBuilderAppDelegate.h"
#import "BuilderController.h"

@implementation BetaBuilderWindow

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return NSDragOperationGeneric;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender {
    NSArray *draggedFilenames = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    
    if ([[[draggedFilenames objectAtIndex:0] pathExtension] isEqual:@"ipa"]) {
        BetaBuilderAppDelegate *appDelegate = (BetaBuilderAppDelegate *)[[NSApplication sharedApplication] delegate];
        [appDelegate.builderController setupFromIPAFile:[draggedFilenames objectAtIndex:0]];

        return YES; 
    } else {
        return NO;
    }
}

@end
