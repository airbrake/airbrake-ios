//
//  HTSAppDelegate_iOS.m
//  Hoptoad iOS
//
//  Created by Caleb Davenport on 5/10/11.
//  Copyright 2011 GUI Cocoa, LLC. All rights reserved.
//

#import "HTSAppDelegate_iOS.h"

@implementation HTSAppDelegate_iOS

@synthesize window = __window;

#pragma mark - application delegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // setup notifier
    [ABNotifier startNotifierWithAPIKey:@"YOUR API KEY"
                        environmentName:ABNotifierAutomaticEnvironment
                        userName:@"user001"
                                 useSSL:YES // only if your account supports it
                               delegate:self];
    // show ui
    [self.window makeKeyAndVisible];
    
    // return
    return YES;
    
}

#pragma mark - memory management

#pragma mark - button actions
- (IBAction)exception {
	NSArray *array = [NSArray array];
    [array objectAtIndex:NSUIntegerMax];
}
- (IBAction)signal {
	raise(SIGSEGV);
}

- (IBAction)customLog:(id)sender {
    @try {
        [NSException raise:@"custom method name" format:@"custom method error!"];
    } @catch (NSException *exception) {
        [ABNotifier logException:exception parameters: @{@"version": @"4.1", @"status":@"testing"}];
    }
}

#pragma mark - notifier delegate
- (UIViewController *)rootViewControllerForNotice {
	NSLog(@"%s", __PRETTY_FUNCTION__);
	return nil;
}
- (void)notifierDidLogException:(NSException *)exception {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, exception);
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
