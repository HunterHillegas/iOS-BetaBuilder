//
//  BuilderController.m
//  BetaBuilder
//
//  Created by Hunter Hillegas on 8/7/10.
//  Copyright 2010 Hunter Hillegas. All rights reserved.
//

/* 
 iOS BetaBuilder - a tool for simpler iOS betas
 Version 1.0, August 2010
 
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

#import "BuilderController.h"
#import "ZipArchive.h"
#import "DAVKit.h"
#include <unistd.h>
#include "fixpng.h"

@implementation BuilderController

@synthesize bundleIdentifierField;
@synthesize bundleVersionField, bundleShortVersionField;
@synthesize bundleNameField;
@synthesize webserverDirectoryField;
@synthesize archiveIPAFilenameField;
@synthesize generateFilesButton;
@synthesize mobileProvisionFilePath;
@synthesize progressIndicator;
@synthesize passwordPanel;
@synthesize generateAndDeployButton;
@synthesize _oldiOSSupport;
@synthesize localDirectoryField;

- (id) init {
	self = [super init];
	if (self != nil) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webserverDirectoryFieldDidChange:)
													 name:NSControlTextDidChangeNotification object:webserverDirectoryField];
	}
	return self;
}

- (void)checkWebserverDirectoryField {
	if ([[webserverDirectoryField stringValue] rangeOfString:@"web.me.com"].length != 0) {
		[generateAndDeployButton setEnabled:YES];
	} else {
		[generateAndDeployButton setEnabled:NO];
	}

}

- (void)webserverDirectoryFieldDidChange:(NSNotification *)notification {
	[self checkWebserverDirectoryField];
}

- (IBAction)specifyIPAFile:(id)sender {
	NSOpenPanel *openDlg = [NSOpenPanel openPanel];
	[openDlg setCanChooseFiles:YES];
	[openDlg setCanChooseDirectories:NO];
	[openDlg setAllowsMultipleSelection:NO];

	if ([openDlg runModalForDirectory:nil file:nil] == NSOKButton) {
		NSArray *files = [openDlg filenames];

		for (int i = 0; i < [files count]; i++ ) {
			[self setupFromIPAFile:[files objectAtIndex:i]];
		}
	}
}

- (void)setupFromIPAFile:(NSString *)ipaFilename {
	[archiveIPAFilenameField setStringValue:ipaFilename];
	
	//Attempt to pull values
	NSError *fileCopyError;
	NSError *fileDeleteError;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *ipaSourceURL = [NSURL fileURLWithPath:[archiveIPAFilenameField stringValue]];
	NSURL *ipaDestinationURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [[archiveIPAFilenameField stringValue] lastPathComponent]]];
	[fileManager removeItemAtURL:ipaDestinationURL error:&fileDeleteError];
	BOOL copiedIPAFile = [fileManager copyItemAtURL:ipaSourceURL toURL:ipaDestinationURL error:&fileCopyError];
	if (!copiedIPAFile) {
		NSLog(@"Error Copying IPA File: %@", fileCopyError);
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
				[bundleVersionField setStringValue:[bundlePlistFile valueForKey:@"CFBundleVersion"]];
				[bundleShortVersionField setStringValue:[bundlePlistFile valueForKey:@"CFBundleShortVersionString"]];
				[bundleIdentifierField setStringValue:[bundlePlistFile valueForKey:@"CFBundleIdentifier"]];
				[bundleNameField setStringValue:[bundlePlistFile valueForKey:@"CFBundleDisplayName"]];
				NSString* iconFile = [bundlePlistFile valueForKey:@"CFBundleIconFile"];
				if ([iconFile length] == 0) {
					NSArray* iconFiles = [bundlePlistFile valueForKey:@"CFBundleIconFiles"];
					if ([iconFiles count] > 0) {
						iconFile = [iconFiles objectAtIndex:0];
					} else {
						NSDictionary* icons = [bundlePlistFile valueForKey:@"CFBundleIcons"];
						if ([icons count] > 0) {
							NSDictionary* primaryIcon = [icons valueForKey:@"CFBundlePrimaryIcon"];
							if ([primaryIcon count] > 0) {
								NSArray* iconFiles = [primaryIcon valueForKey:@"CFBundleIconFiles"];
								if ([iconFiles count] > 0) {
									iconFile = [iconFiles objectAtIndex:0];
								}
							}
						}
					}
				}
				if (iconFile) {
					[iconFilePath release];
					iconFilePath = nil;
					iconFilePath = [appDirectoryPath stringByAppendingPathComponent:[[payloadContents objectAtIndex:0] stringByAppendingPathComponent:iconFile]];
				}
			}
			
			//set mobile provision file
			[mobileProvisionFilePath release];
			mobileProvisionFilePath = nil;
			mobileProvisionFilePath = [appDirectoryPath stringByAppendingPathComponent:[[payloadContents objectAtIndex:0] stringByAppendingPathComponent:@"embedded.mobileprovision"]];
		}
	}
	
	{
		NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
		{
			NSString* value = [defaults valueForKey:[archiveIPAFilenameField stringValue]];
			if (value) {
				[webserverDirectoryField setStringValue: value];
			}
		}
		{
			NSNumber* value = [defaults valueForKey:[NSString stringWithFormat:@"%@OldiOSSupport", [archiveIPAFilenameField stringValue]]];
			if (value) {
				[_oldiOSSupport setState: [value boolValue]];
			}
		}
		{
			NSURL* value = [defaults URLForKey:[NSString stringWithFormat:@"%@saveDirectoryURL", [archiveIPAFilenameField stringValue]]];
			if (value) {
				[localDirectoryField setStringValue: [value path]];
			}
		}
	}

	[generateFilesButton setEnabled:YES];
	[self checkWebserverDirectoryField];
	
}

- (IBAction)chooseOutputDirectory:(id)sender {
	//ask for save location
	NSOpenPanel *directoryPanel = [NSOpenPanel openPanel];
	
	[directoryPanel setCanChooseFiles:NO];
	[directoryPanel setCanChooseDirectories:YES];
	[directoryPanel setAllowsMultipleSelection:NO];
	[directoryPanel setCanCreateDirectories:YES];
	[directoryPanel setPrompt:@"Choose Directory"];
	[directoryPanel setMessage:@"Choose the Directory for Beta Files - Probably Should Match Deployment Directory"];
	
	if ([directoryPanel runModalForDirectory:[localDirectoryField stringValue] file:nil] == NSOKButton) {
		[localDirectoryField setStringValue: [[directoryPanel directoryURL] path]];
	}
}

- (void)generateFilesWithOutputDirectory:(NSString*)outputPath {
	[saveDirectoryURL release];
	saveDirectoryURL = nil;

	if (outputPath == nil) {
		//ask for save location
		NSOpenPanel *directoryPanel = [NSOpenPanel openPanel];

		[directoryPanel setCanChooseFiles:NO];
		[directoryPanel setCanChooseDirectories:YES];
		[directoryPanel setAllowsMultipleSelection:NO];
		[directoryPanel setCanCreateDirectories:YES];
		[directoryPanel setPrompt:@"Choose Directory"];
		[directoryPanel setMessage:@"Choose the Directory for Beta Files - Probably Should Match Deployment Directory"];
		
		if ([directoryPanel runModalForDirectory:[localDirectoryField stringValue] file:nil] == NSOKButton) {
			saveDirectoryURL = [[directoryPanel directoryURL] copy];
		}
	} else {
		saveDirectoryURL = [[NSURL fileURLWithPath: outputPath] copy];
	}

	if (saveDirectoryURL) {
		{
			NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
			[defaults setValue:[webserverDirectoryField stringValue] forKey:[archiveIPAFilenameField stringValue]];
			[defaults setValue:[NSNumber numberWithBool:[_oldiOSSupport state]] forKey:[NSString stringWithFormat:@"%@OldiOSSupport", [archiveIPAFilenameField stringValue]]];
			[defaults setURL:saveDirectoryURL forKey:[NSString stringWithFormat:@"%@saveDirectoryURL", [archiveIPAFilenameField stringValue]]];
			[defaults synchronize];
		}
		
		//create plist
		NSString *encodedIpaFilename = [[[archiveIPAFilenameField stringValue] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; //this isn't the most robust way to do this
		NSString *ipaURLString = [NSString stringWithFormat:@"%@/%@", [webserverDirectoryField stringValue], encodedIpaFilename];
		NSDictionary *assetsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"software-package", @"kind", ipaURLString, @"url", nil];
		NSDictionary *metadataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[bundleIdentifierField stringValue], @"bundle-identifier", [bundleVersionField stringValue], @"bundle-version", @"software", @"kind", [bundleNameField stringValue], @"title", nil];
		NSDictionary *innerManifestDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:assetsDictionary], @"assets", metadataDictionary, @"metadata", nil];
		NSDictionary *outerManifestDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:innerManifestDictionary], @"items", nil];
		NSLog(@"Manifest Created");
		
		//create html file
		NSString *templatePath = @"";
		if (![_oldiOSSupport state]) {
			templatePath = [[NSBundle mainBundle] pathForResource:@"index_template" ofType:@"html"];
		} else {
			templatePath = [[NSBundle mainBundle] pathForResource:@"index_template_old" ofType:@"html"];
		}

		NSString *htmlTemplateString = [NSString stringWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:nil];
		htmlTemplateString = [htmlTemplateString stringByReplacingOccurrencesOfString:@"[BETA_NAME]" withString:[bundleNameField stringValue]];
		
		NSString* niceBuildNumberName;
		if (![[bundleShortVersionField stringValue] isEqualToString:[bundleVersionField stringValue]])
			niceBuildNumberName = [NSString stringWithFormat:@"%@-%@", [bundleShortVersionField stringValue], [bundleVersionField stringValue]];
		else
			niceBuildNumberName = [NSString stringWithFormat:@"%@", [bundleVersionField stringValue]];
		
		htmlTemplateString = [htmlTemplateString stringByReplacingOccurrencesOfString:@"[BETA_VERSION]" withString:niceBuildNumberName];
		htmlTemplateString = [htmlTemplateString stringByReplacingOccurrencesOfString:@"[BETA_PLIST]" withString:[NSString stringWithFormat:@"%@/%@", [webserverDirectoryField stringValue], @"manifest.plist"]];
		htmlTemplateString = [htmlTemplateString stringByReplacingOccurrencesOfString:@"[BETA_IPA]" withString:ipaURLString];
		
		
		{
			[[NSFileManager defaultManager] removeItemAtURL: [saveDirectoryURL URLByAppendingPathComponent:@"manifest.plist"] error:nil];
			[[NSFileManager defaultManager] removeItemAtURL: [saveDirectoryURL URLByAppendingPathComponent:@"index.html"] error:nil];

			//Write Files
			[outerManifestDictionary writeToURL:[saveDirectoryURL URLByAppendingPathComponent:@"manifest.plist"] atomically:YES];
			[htmlTemplateString writeToURL:[saveDirectoryURL URLByAppendingPathComponent:@"index.html"] atomically:YES encoding:NSUTF8StringEncoding error:nil];			
			
			//Copy IPA
			NSError *fileCopyError;
			NSFileManager *fileManager = [NSFileManager defaultManager];
			NSURL *ipaSourceURL = [NSURL fileURLWithPath:[archiveIPAFilenameField stringValue]];
			NSURL *ipaDestinationURL = [saveDirectoryURL URLByAppendingPathComponent:[[archiveIPAFilenameField stringValue] lastPathComponent]];
			[[NSFileManager defaultManager] removeItemAtURL: ipaDestinationURL error:nil];
			BOOL copiedIPAFile = [fileManager copyItemAtURL:ipaSourceURL toURL:ipaDestinationURL error:&fileCopyError];
			if (!copiedIPAFile) {
				NSLog(@"Error Copying IPA File: %@", fileCopyError);
			}
			
			NSURL *iconDestinationURL = [saveDirectoryURL URLByAppendingPathComponent:@"icon.png"];
			[[NSFileManager defaultManager] removeItemAtURL: iconDestinationURL error:nil];
			fixpng([iconFilePath UTF8String], [[iconDestinationURL path] UTF8String]);
			

			//Copy README
			NSString *readmeContents = [[NSBundle mainBundle] pathForResource:@"README" ofType:@""];
			[[NSFileManager defaultManager] removeItemAtURL: [saveDirectoryURL URLByAppendingPathComponent:@"README.txt"] error:nil];
			[readmeContents writeToURL:[saveDirectoryURL URLByAppendingPathComponent:@"README.txt"] atomically:YES encoding:NSASCIIStringEncoding error:nil];
			
			//Create Archived Version for 3.0 Apps
			if ([_oldiOSSupport state]) {
				[[NSFileManager defaultManager] removeItemAtURL: [saveDirectoryURL URLByAppendingPathComponent:@"beta_archive.zip"] error:nil];
				ZipArchive* zip = [[ZipArchive alloc] init];
				BOOL ret = [zip CreateZipFile2:[[saveDirectoryURL path] stringByAppendingPathComponent:@"beta_archive.zip"]];
				ret = [zip addFileToZip:[archiveIPAFilenameField stringValue] newname:@"application.ipa"];
				ret = [zip addFileToZip:mobileProvisionFilePath newname:@"beta_provision.mobileprovision"];
				if(![zip CloseZipFile2]) {
					NSLog(@"Error Creating 3.x Zip File");
				}
				[zip release];
			}
		}
	}
}

- (IBAction)generateFiles:(id)sender {
	[self generateFilesWithOutputDirectory:[localDirectoryField stringValue]];
	
	//Play Done Sound / Display Alert
	NSSound *systemSound = [NSSound soundNamed:@"Glass"];
	[systemSound play];
}

- (void)generateAndDeploy:(id)sender {
	NSString* tmpName = [NSString stringWithFormat:@"/tmp/BetaBuilder_%@.XXXXXX", [bundleNameField stringValue]];
	char* tmpOutdir = mkdtemp((char*)[tmpName UTF8String]);
	if (tmpOutdir) {		
		[self generateFilesWithOutputDirectory: [NSString stringWithFormat:@"%s", tmpOutdir]];
		
		NSString* serverPath = [[webserverDirectoryField stringValue] substringFromIndex:18];
		NSArray* comp = [serverPath componentsSeparatedByString:@"/"];
		
		if ([comp count] > 0) {
			NSString* username = [comp objectAtIndex:0];
			NSString* password = @"";
			
			if (username)
			{
				SecKeychainItemRef item = nil;
				OSStatus theStatus = noErr;
				char *buffer;
				UInt32 passwordLen;
				
				char *utf8 = (char *)[username UTF8String];
				theStatus = SecKeychainFindGenericPassword(NULL,
														   6,
														   "iTools",
														   strlen(utf8),
														   utf8,
														   &passwordLen,
														   (void *)&buffer,
														   &item);
				
				if (noErr == theStatus)
				{
					if (passwordLen > 0)
					{
						password = [[[NSString alloc] initWithBytes:buffer length:passwordLen encoding:[NSString defaultCStringEncoding]] autorelease];
					}
					
					// release buffer allocated by SecKeychainFindGenericPassword
					theStatus = SecKeychainItemFreeContent(NULL, buffer);
				}
			}
			if ([password length] == 0) {
				if ([passwordPanel runModal] == NSOKButton) {
					password = [passwordPanel password];
				}				
			}
			
			if ([password length] > 0) {
				serverPath = [NSString stringWithFormat:@"Web/Sites/%@", [serverPath substringFromIndex:[username length] + 1]];
				
				DAVCredentials* creds = [DAVCredentials credentialsWithUsername:username
																	   password:password];
				NSString* root = [NSString stringWithFormat: @"http://idisk.mac.com/%@", username];
				DAVSession* session = [[DAVSession alloc] initWithRootURL:root credentials:creds];
				session.maxConcurrentRequests = 1;
				
				{
					DAVMakeCollectionRequest* request = [[DAVMakeCollectionRequest alloc] initWithPath:serverPath];
					request.delegate = self;
					[session enqueueRequest:request];
					[request release];
				}
				{
					DAVMakeCollectionRequest* request = [[DAVMakeCollectionRequest alloc] initWithPath:serverPath ];
					request.delegate = self;
					[session enqueueRequest:request];
					[request release];
				}
				
				NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:saveDirectoryURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
				for (NSURL* file in files) {
					NSString* remoteFile = [NSString stringWithFormat:@"%@/%@", serverPath, [file lastPathComponent]];
					DAVPutRequest *req = [[DAVPutRequest alloc] initWithPath:remoteFile];
					req.data = [NSData dataWithContentsOfURL:file];
					req.delegate = self;
					[session enqueueRequest:req];
					[req release];
				}
				
				const int max = 2 + [files count];
				_done = max;
				[progressIndicator setMaxValue:max];
				[progressIndicator setMinValue:0];
				[progressIndicator setDoubleValue:0];
				while (_done > 0) {
					[progressIndicator setDoubleValue:(max - _done)];
					[NSThread sleepForTimeInterval: 0.1f];
				}
				[progressIndicator setDoubleValue:(max - _done)];
				
				//Play Done Sound / Display Alert
				NSSound *systemSound = [NSSound soundNamed:@"Glass"];
				[systemSound play];
			}
		}
		
		rmdir(tmpOutdir);
	}
}

- (IBAction)generateAndDeployButtonClicked:(id)sender {
	[self performSelectorInBackground:@selector(generateAndDeploy:) withObject:sender];
}

- (void)request:(DAVRequest *)aRequest didSucceedWithResult:(id)result {
	NSLog(@"request done: %@", aRequest.path);
	--_done;
}

- (void)request:(DAVRequest *)aRequest didFailWithError:(NSError *)error {
	NSLog(@"request error: %@ - %@", aRequest.path, [error localizedDescription]);
}

- (void)request:(DAVRequest *)aRequest didReceiveData:(NSData *)data {
	NSLog(@"%d", [data length]);
}

@end
