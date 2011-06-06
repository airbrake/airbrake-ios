//
//  HTSAppDelegate_iOS.m
//  Hoptoad iOS
//
//  Created by Caleb Davenport on 5/10/11.
//  Copyright 2011 GUI Cocoa, LLC. All rights reserved.
//

#import "HTSAppDelegate_iOS.h"

// api key
static NSString * HTSHoptoadAPIKey = @"";

@implementation HTSAppDelegate_iOS

@synthesize window=_window;

#pragma mark - application delegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
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
    
    // show ui
    [self.window makeKeyAndVisible];
    
    // return
    return YES;
    
}

#pragma mark - memory management
- (void)dealloc {
    self.window = nil;
    [super dealloc];
}

#pragma mark - button actions
- (IBAction)exception {
	NSArray *array = [NSArray array];
    [array objectAtIndex:NSUIntegerMax];
}
- (IBAction)signal {
	raise(SIGSEGV);
}

#pragma mark - notifier delegate
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
