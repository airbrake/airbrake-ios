//
//  HTNotifier_iOS.m
//  CrashPhone
//
//  Created by Caleb Davenport on 1/3/11.
//  Copyright 2011 GUI Cocoa, LLC. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "HTNotifier_iOS.h"

@implementation HTNotifier_iOS

#pragma mark -
#pragma mark init
- (id)initWithAPIKey:(NSString *)key environmentName:(NSString *)name {
	self = [super initWithAPIKey:key environmentName:name];
	if (self) {
		[[NSNotificationCenter defaultCenter]
		 addObserver:self
		 selector:@selector(applicationDidBecomeActive:)
		 name:UIApplicationDidBecomeActiveNotification
		 object:nil];
	}
	return self;
}

#pragma mark -
#pragma mark application notifications
- (void)applicationDidBecomeActive:(NSNotification *)notif {
	//[self performSelectorInBackground:@selector(checkForNoticesAndReportIfReachable) withObject:nil];
}

@end

#endif
