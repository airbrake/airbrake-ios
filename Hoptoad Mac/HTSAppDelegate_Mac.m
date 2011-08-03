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

@synthesize window = __window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    // setup notifier
    HTNotifier *notifier = [HTNotifier
                            startNotifierWithAPIKey:HTSHoptoadAPIKey
                            environmentName:HTNotifierAutomaticEnvironment];
    
	[notifier setDelegate:self];
	[notifier setUseSSL:YES]; // only if your account supports it
//    [notifier setEnvironmentValue:@"test value" forKey:@"test key"];
	[notifier writeTestNotice];
    
}

#pragma mark - notifier delegate
- (void)notifierDidLogException:(NSException *)exc {
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
