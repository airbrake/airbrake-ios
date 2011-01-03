//
//  CrashMacAppDelegate.m
//  CrashMac
//
//  Created by Caleb Davenport on 10/21/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import "CrashMacAppDelegate.h"

@implementation CrashMacAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[HTNotifier startNotifierWithAPIKey:@""
						environmentName:HTNotifierDevelopmentEnvironment];
}

- (IBAction)crash:(id)sender {
	raise(SIGSEGV);
}

@end
