//
//  BuilderController.m
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

#import "NSFileManager+DirectoryLocations.h"

#import "BuilderController.h"
#import "ZipArchive.h"

@implementation BuilderController

@synthesize bundleIdentifierField;
@synthesize bundleVersionField;
@synthesize bundleNameField;
@synthesize webserverDirectoryField;
@synthesize archiveIPAFilenameField;
@synthesize generateFilesButton;
@synthesize mobileProvisionFilePath;
@synthesize appIconFilePath;
@synthesize bundleIdentifier, bundleVersion, bundleName, webserverDirectory, archiveIPAFilename;

- (IBAction)specifyIPAFile:(id)sender {
    NSArray *allowedFileTypes = [NSArray arrayWithObjects:@"ipa", @"IPA", nil]; //only allow IPAs
    
	NSOpenPanel *openDlg = [NSOpenPanel openPanel];
	[openDlg setCanChooseFiles:YES];
	[openDlg setCanChooseDirectories:NO];
	[openDlg setAllowsMultipleSelection:NO];
    [openDlg setAllowedFileTypes:allowedFileTypes];

    if ([openDlg runModal] == NSOKButton) {
        NSArray *files = [openDlg URLs];
        
		for (int i = 0; i < [files count]; i++ ) {
            NSURL *fileURL = [files objectAtIndex:i];
			[self setupFromIPAFile:[fileURL path]];
		}
	}
}

- (void)setupFromIPAFile:(NSString *)anIpaFilename {
	[self.archiveIPAFilenameField setStringValue:anIpaFilename];
    self.archiveIPAFilename = anIpaFilename;
	
	//Attempt to pull values
	NSError *fileCopyError;
	NSError *fileDeleteError;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *ipaSourceURL = [NSURL fileURLWithPath:self.archiveIPAFilename];
	NSURL *ipaDestinationURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [self.archiveIPAFilename lastPathComponent]]];
	[fileManager removeItemAtURL:ipaDestinationURL error:&fileDeleteError];
	BOOL copiedIPAFile = [fileManager copyItemAtURL:ipaSourceURL toURL:ipaDestinationURL error:&fileCopyError];

    if (!copiedIPAFile) {
		NSLog(@"Error Copying IPA File: %@", fileCopyError);
        NSAlert *theAlert = [NSAlert alertWithError:fileCopyError];
        NSInteger button = [theAlert runModal];
        if (button != NSAlertFirstButtonReturn) {
            //user hit the rightmost button
        }
	} else {
		//Remove Existing Trash in Temp Directory
		[fileManager removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"extracted_app"] error:nil];
		
		ZipArchive *za = [[ZipArchive alloc] init];
		if ([za UnzipOpenFile:[ipaDestinationURL path]]) {
			BOOL ret = [za UnzipFileTo:[NSTemporaryDirectory() stringByAppendingPathComponent:@"extracted_app"] overWrite:YES];
			if (NO == ret){} [za UnzipCloseFile];
		}
		[za release];
		
		//read the Info.plist file
		NSString *appDirectoryPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"extracted_app"] stringByAppendingPathComponent:@"Payload"];
		NSArray *payloadContents = [fileManager contentsOfDirectoryAtPath:appDirectoryPath error:nil];
		if ([payloadContents count] > 0) {
			NSString *plistPath = [[payloadContents objectAtIndex:0] stringByAppendingPathComponent:@"Info.plist"];
			NSDictionary *bundlePlistFile = [NSDictionary dictionaryWithContentsOfFile:[appDirectoryPath stringByAppendingPathComponent:plistPath]];
			
			if (bundlePlistFile) {
				[self.bundleVersionField setStringValue:[bundlePlistFile valueForKey:@"CFBundleVersion"]];
                self.bundleVersion = [bundlePlistFile valueForKey:@"CFBundleVersion"];
				[self.bundleIdentifierField setStringValue:[bundlePlistFile valueForKey:@"CFBundleIdentifier"]];
                self.bundleIdentifier = [bundlePlistFile valueForKey:@"CFBundleIdentifier"];
				[self.bundleNameField setStringValue:[bundlePlistFile valueForKey:@"CFBundleDisplayName"]];
                self.bundleName = [bundlePlistFile valueForKey:@"CFBundleDisplayName"];
                
                [self populateFieldsFromHistoryForBundleID:[bundlePlistFile valueForKey:@"CFBundleIdentifier"]];
			}
			
			//set mobile provision file
			self.mobileProvisionFilePath = [appDirectoryPath stringByAppendingPathComponent:[[payloadContents objectAtIndex:0] stringByAppendingPathComponent:@"embedded.mobileprovision"]];
            
            //set the app file icon path
            self.appIconFilePath = [appDirectoryPath stringByAppendingPathComponent:[[payloadContents objectAtIndex:0] stringByAppendingPathComponent:@"iTunesArtwork"]];
		}
	}

	[self.generateFilesButton setEnabled:YES];
}

- (void)populateFieldsFromHistoryForBundleID:(NSString *)bundleID {
    NSString *applicationSupportPath = [[NSFileManager defaultManager] applicationSupportDirectory];
    NSString *historyPath = [applicationSupportPath stringByAppendingPathComponent:@"history.plist"];
    
    NSDictionary *historyDictionary = [NSDictionary dictionaryWithContentsOfFile:historyPath];
    
    if (historyDictionary) {
        NSDictionary *historyItem = [historyDictionary valueForKey:bundleID];
        
        if (historyItem) {
            [self.webserverDirectoryField setStringValue:[historyItem valueForKey:@"webserverDirectory"]];
            self.webserverDirectory = [historyItem valueForKey:@"webserverDirectory"];
        } else {
            NSLog(@"No History Item Found for Bundle ID: %@", bundleID);
        }
    }
}

- (void)storeFieldsInHistoryForBundleID:(NSString *)bundleID {    
    NSString *applicationSupportPath = [[NSFileManager defaultManager] applicationSupportDirectory];
    NSString *historyPath = [applicationSupportPath stringByAppendingPathComponent:@"history.plist"];
    NSString *trimmedURLString = [self.webserverDirectory stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSMutableDictionary *historyDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:historyPath];
    if (!historyDictionary) {
        historyDictionary = [NSMutableDictionary dictionary];
    }
    
    NSDictionary *webserverDirectoryDictionary = [NSDictionary dictionaryWithObjectsAndKeys:trimmedURLString, @"webserverDirectory", nil];
    [historyDictionary setValue:webserverDirectoryDictionary forKey:bundleID];
    
    [historyDictionary writeToFile:historyPath atomically:YES];
}

- (IBAction)generateFiles:(id)sender {
    [self generateFilesWithWebserverAddress:self.webserverDirectory andOutputDirectory:nil];
}

- (void)generateFilesWithWebserverAddress:(NSString *)webserver andOutputDirectory:(NSString *)outputPath {
    //create plist
    NSString *trimmedURLString = [webserver stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSString *encodedIpaFilename = [[self.archiveIPAFilename lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; //this isn't the most robust way to do this
	NSString *ipaURLString = [NSString stringWithFormat:@"%@/%@", trimmedURLString, encodedIpaFilename];
	NSDictionary *assetsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"software-package", @"kind", ipaURLString, @"url", nil];
	NSDictionary *metadataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:self.bundleIdentifier, @"bundle-identifier", self.bundleVersion, @"bundle-version", @"software", @"kind", self.bundleName, @"title", nil];
	NSDictionary *innerManifestDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:assetsDictionary], @"assets", metadataDictionary, @"metadata", nil];
	NSDictionary *outerManifestDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:innerManifestDictionary], @"items", nil];
	NSLog(@"Manifest Created");
	
	//create html file    
    NSString *applicationSupportPath = [[NSFileManager defaultManager] applicationSupportDirectory];
    NSString *templatePath = [applicationSupportPath stringByAppendingPathComponent:@"index_template.html"];
	NSString *htmlTemplateString = [NSString stringWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:nil];
	htmlTemplateString = [htmlTemplateString stringByReplacingOccurrencesOfString:@"[BETA_NAME]" withString:self.bundleName];
    htmlTemplateString = [htmlTemplateString stringByReplacingOccurrencesOfString:@"[BETA_VERSION]" withString:self.bundleVersion];
	htmlTemplateString = [htmlTemplateString stringByReplacingOccurrencesOfString:@"[BETA_PLIST]" withString:[NSString stringWithFormat:@"%@/%@", trimmedURLString, @"manifest.plist"]];
	
    //add formatted date
    NSDateFormatter *shortDateFormatter = [[NSDateFormatter alloc] init];
    [shortDateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [shortDateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSString *formattedDateString = [shortDateFormatter stringFromDate:[NSDate date]];
    [shortDateFormatter release];
    htmlTemplateString = [htmlTemplateString stringByReplacingOccurrencesOfString:@"[BETA_DATE]" withString:formattedDateString];
    
    //store history
    if (trimmedURLString)
        [self storeFieldsInHistoryForBundleID:self.bundleIdentifier];
    
    if (!outputPath) {
    	//ask for save location	
        NSOpenPanel *directoryPanel = [NSOpenPanel openPanel];
        [directoryPanel setCanChooseFiles:NO];
        [directoryPanel setCanChooseDirectories:YES];
        [directoryPanel setAllowsMultipleSelection:NO];
        [directoryPanel setCanCreateDirectories:YES];
        [directoryPanel setPrompt:@"Choose Directory"];
        [directoryPanel setMessage:@"Choose the Directory for Beta Files - Probably Should Match Deployment Directory"];
        
        if ([directoryPanel runModal] == NSOKButton) {
            NSURL *saveDirectoryURL = [directoryPanel directoryURL];
            [self saveFilesToOutputDirectory:saveDirectoryURL forManifestDictionary:outerManifestDictionary withTemplateHTML:htmlTemplateString];
            
            //Play Done Sound / Display Alert
            NSSound *systemSound = [NSSound soundNamed:@"Glass"];
            [systemSound play];
        }    
    } else {
        NSURL *saveDirectoryURL = [NSURL fileURLWithPath:outputPath];
        [self saveFilesToOutputDirectory:saveDirectoryURL forManifestDictionary:outerManifestDictionary withTemplateHTML:htmlTemplateString];
    }
}

- (void)saveFilesToOutputDirectory:(NSURL *)saveDirectoryURL forManifestDictionary:(NSDictionary *)outerManifestDictionary withTemplateHTML:(NSString *)htmlTemplateString {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //Copy IPA
    NSError *fileCopyError;
    NSLog(@"%@",self.archiveIPAFilename);
    NSURL *ipaSourceURL = [NSURL fileURLWithPath:self.archiveIPAFilename];
    NSURL *ipaDestinationURL = [saveDirectoryURL URLByAppendingPathComponent:[self.archiveIPAFilename lastPathComponent]];
    BOOL copiedIPAFile = [fileManager copyItemAtURL:ipaSourceURL toURL:ipaDestinationURL error:&fileCopyError];
    if (!copiedIPAFile) {
        NSLog(@"Error Copying IPA File: %@", fileCopyError);
        NSAlert *theAlert = [NSAlert alertWithError:fileCopyError];
        NSInteger button = [theAlert runModal];
        if (button != NSAlertFirstButtonReturn) {
            //user hit the rightmost button
        }
    }
    
    //Copy README
    NSString *readmeContents = [[NSBundle mainBundle] pathForResource:@"README" ofType:@""];
    [readmeContents writeToURL:[saveDirectoryURL URLByAppendingPathComponent:@"README.txt"] atomically:YES encoding:NSASCIIStringEncoding error:nil];
    
    //If iTunesArtwork file exists, use it
    BOOL doesArtworkExist = [fileManager fileExistsAtPath:self.appIconFilePath];
    if (doesArtworkExist) {
        NSString *artworkDestinationFilename = [NSString stringWithFormat:@"%@.png", [self.appIconFilePath lastPathComponent]];
        
        NSURL *artworkSourceURL = [NSURL fileURLWithPath:self.appIconFilePath];
        NSURL *artworkDestinationURL = [saveDirectoryURL URLByAppendingPathComponent:artworkDestinationFilename];
        
        NSError *artworkCopyError;
        BOOL copiedArtworkFile = [fileManager copyItemAtURL:artworkSourceURL toURL:artworkDestinationURL error:&artworkCopyError];
        
        if (copiedArtworkFile) {
            htmlTemplateString = [htmlTemplateString stringByReplacingOccurrencesOfString:@"[BETA_ICON]" withString:[NSString stringWithFormat:@"<p><img src='%@' length='57' width='57' /></p>", artworkDestinationFilename]];
        } else {
            htmlTemplateString = [htmlTemplateString stringByReplacingOccurrencesOfString:@"[BETA_ICON]" withString:@""];
        }
    } else {
        NSLog(@"No iTunesArtwork File Exists in Bundle");
        
        htmlTemplateString = [htmlTemplateString stringByReplacingOccurrencesOfString:@"[BETA_ICON]" withString:@""];
    }
    
    //Write Files
    NSError *fileWriteError;
    [outerManifestDictionary writeToURL:[saveDirectoryURL URLByAppendingPathComponent:@"manifest.plist"] atomically:YES];
    BOOL wroteHTMLFileSuccessfully = [htmlTemplateString writeToURL:[saveDirectoryURL URLByAppendingPathComponent:@"index.html"] atomically:YES encoding:NSUTF8StringEncoding error:&fileWriteError];
    
    if (!wroteHTMLFileSuccessfully) {
        NSLog(@"Error Writing HTML File: %@ to %@", fileWriteError, saveDirectoryURL);
    }
    
    //Create Archived Version for 3.0 Apps
    ZipArchive* zip = [[ZipArchive alloc] init];
    [zip CreateZipFile2:[[saveDirectoryURL path] stringByAppendingPathComponent:@"beta_archive.zip"]];
    [zip addFileToZip:self.archiveIPAFilename newname:@"application.ipa"];
    [zip addFileToZip:self.mobileProvisionFilePath newname:@"beta_provision.mobileprovision"];
    if(![zip CloseZipFile2]) {
        NSLog(@"Error Creating 3.x Zip File");
    }
    [zip release];
}

#pragma mark - Memory management

- (void) dealloc
{
    [bundleIdentifier release];
    [bundleVersion release];
    [bundleName release];
    [webserverDirectory release];
    [archiveIPAFilename release];
    [super dealloc];
}

@end
