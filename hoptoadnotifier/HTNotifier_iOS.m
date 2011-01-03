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
#pragma mark object methods
- (void)registerNotifications {
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(applicationDidBecomeActive:)
	 name:UIApplicationDidBecomeActiveNotification
	 object:nil];
}
- (void)unregisterNotifications {
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:UIApplicationDidBecomeActiveNotification
	 object:nil];
}
- (void)applicationDidBecomeActive:(NSNotification *)notif {
	[self performSelectorInBackground:@selector(checkForNoticesAndReportIfReachable) withObject:nil];
}
- (void)showNoticeAlert {
	if ([self.delegate respondsToSelector:@selector(notifierWillDisplayAlert)]) {
		[self.delegate notifierWillDisplayAlert];
	}
	
	NSString *title = HTLocalizedString(@"NOTICE_TITLE");
	if ([self.delegate respondsToSelector:@selector(titleForNoticeAlert)]) {
		NSString *tempString = [self.delegate titleForNoticeAlert];
		if (tempString != nil) {
			title = tempString;
		}
	}
	
	NSString *body = HTLocalizedString(@"NOTICE_BODY");
	if ([self.delegate respondsToSelector:@selector(bodyForNoticeAlert)]) {
		NSString *tempString = [self.delegate bodyForNoticeAlert];
		if (tempString != nil) {
			body = tempString;
		}
	}
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:HTStringByReplacingHoptoadVariablesInString(title)
													message:HTStringByReplacingHoptoadVariablesInString(body)
												   delegate:self
										  cancelButtonTitle:HTLocalizedString(@"DONT_SEND")
										  otherButtonTitles:HTLocalizedString(@"ALWAYS_SEND"), HTLocalizedString(@"SEND"), nil];
	[alert show];
	[alert release];
}

#pragma mark -
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if ([self.delegate respondsToSelector:@selector(notifierDidDismissAlert)]) {
		[self.delegate notifierDidDismissAlert];
	}
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *button = [alertView buttonTitleAtIndex:buttonIndex];
	
	if (buttonIndex == alertView.cancelButtonIndex) {
		NSArray *noticePaths = HTNotices();
		for (NSString *notice in noticePaths) {
			[[NSFileManager defaultManager]
			 removeItemAtPath:notice
			 error:nil];
		}
	}
	else if ([button isEqualToString:HTLocalizedString(@"ALWAYS_SEND")]) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:HTNotifierAlwaysSendKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[self performSelectorInBackground:@selector(postAllNoticesWithAutoreleasePool) withObject:nil];
	}
	else if ([button isEqualToString:HTLocalizedString(@"SEND")]) {
		[self performSelectorInBackground:@selector(postAllNoticesWithAutoreleasePool) withObject:nil];
	}
}

@end

#endif
