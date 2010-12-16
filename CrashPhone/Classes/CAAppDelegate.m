//
//  CrashAppAppDelegate.m
//  CrashApp
//
//  Created by Caleb Davenport on 5/26/10.
//  Copyright GUI Cocoa, LLC. 2010. All rights reserved.
//

#import "CAAppDelegate.h"

@implementation CAAppDelegate

@synthesize window;

#pragma mark -
#pragma mark notifier delegate
- (UIViewController *)rootViewControllerForNotice {
	NSLog(@"%s", __PRETTY_FUNCTION__);
	return nil;
}
- (void)notifierDidHandleException:(NSException *)exc {
	NSLog(@"%s %@", __PRETTY_FUNCTION__, exc);
}
- (void)notifierWillDisplayAlert {
	NSLog(@"%s", __PRETTY_FUNCTION__);
}
- (void)notifierDidDismissAlert {
	NSLog(@"%s", __PRETTY_FUNCTION__);
}
- (NSString *)titleForNoticeAlert {
	NSLog(@"%s", __PRETTY_FUNCTION__);
	return nil;
}
- (NSString *)bodyForNoticeAlert {
	NSLog(@"%s", __PRETTY_FUNCTION__);
	return nil;
}

#pragma mark -
#pragma mark application delegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[HTNotifier startNotifierWithAPIKey:@"efafdebc912d6a0ec83d8ef4867af1ec"
						environmentName:HTNotifierAppStoreEnvironment];
	[[HTNotifier sharedNotifier] setDelegate:self];
	[[HTNotifier sharedNotifier] setUseSSL:YES];
	//[[HTNotifier sharedNotifier] writeTestNotice];
	
    [window makeKeyAndVisible];
	return YES;
}

#pragma mark -
#pragma mark button actions
- (IBAction)crash:(id)sender {
	[NSException raise:NSInvalidArgumentException format:@"test exception"];
}
- (IBAction)signal:(id)sender {
	raise(SIGSEGV);
}

#pragma mark -
#pragma mark memory management
- (void)dealloc {
	self.window = nil;
	
    [super dealloc];
}

@end
