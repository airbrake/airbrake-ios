//
//  HTSAppDelegate_Mac.m
//  Hoptoad Mac
//
//  Created by Caleb Davenport on 5/10/11.
//  Copyright 2011 GUI Cocoa, LLC. All rights reserved.
//

#import "HTSAppDelegate_Mac.h"

@implementation HTSAppDelegate_Mac

@synthesize window = __window;

#pragma mark - app delegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    // setup notifier
    [ABNotifier startNotifierWithAPIKey:@""
                        environmentName:ABNotifierAutomaticEnvironment
                                 useSSL:YES // only if your account supports it
                               delegate:self];
    [ABNotifier setEnvironmentValue:@"test value" forKey:@"test key"];
    
    // test notice on main thread
    [ABNotifier writeTestNotice];
    
    // test notice on another thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [ABNotifier writeTestNotice];
    });
    
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
