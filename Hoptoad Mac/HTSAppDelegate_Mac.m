//
//  HTSAppDelegate_Mac.m
//  Hoptoad Mac
//
//  Created by Caleb Davenport on 5/10/11.
//  Copyright 2011 GUI Cocoa, LLC. All rights reserved.
//

#import "HTSAppDelegate_Mac.h"

// api key
static NSString * HTSHoptoadAPIKey = @"";

@implementation HTSAppDelegate_Mac

@synthesize window=_window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    // setup notifier
#ifdef DEBUG
	[HTNotifier startNotifierWithAPIKey:HTSHoptoadAPIKey
						environmentName:HTNotifierDevelopmentEnvironment];
#else
    [HTNotifier startNotifierWithAPIKey:HTSHoptoadAPIKey
						environmentName:HTNotifierAppStoreEnvironment];
#endif
	[[HTNotifier sharedNotifier] setDelegate:self];
	[[HTNotifier sharedNotifier] setUseSSL:YES]; // only if your account supports it
    [[HTNotifier sharedNotifier] setEnvironmentValue:@"test value" forKey:@"test key"];
	[[HTNotifier sharedNotifier] writeTestNotice];
    
}

#pragma mark - notifier delegate
- (void)notifierDidHandleException:(NSException *)exc {
	NSLog(@"%s %@", __PRETTY_FUNCTION__, exc);
}
- (void)notifierWillDisplayAlert {
	NSLog(@"%s", __PRETTY_FUNCTION__);
}
- (void)notifierDidDismissAlert {
	NSLog(@"%s", __PRETTY_FUNCTION__);
}
- (void)notifierWillPostNotices {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}
- (void)notifierDidPostNotices {
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

@end
