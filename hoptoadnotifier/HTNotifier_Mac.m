//
//  HTNotifier_Mac.m
//  CrashPhone
//
//  Created by Caleb Davenport on 1/3/11.
//  Copyright 2011 GUI Cocoa, LLC. All rights reserved.
//

#if !TARGET_OS_IPHONE

#import "HTNotifier_Mac.h"

@implementation HTNotifier_Mac

#pragma mark -
#pragma mark object methods
- (void)registerNotifications {
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(applicationDidBecomeActive:)
	 name:NSApplicationDidBecomeActiveNotification
	 object:nil];
}
- (void)unregisterNotifications {
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:NSApplicationDidBecomeActiveNotification
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
	
	NSAlert *alert = [NSAlert alertWithMessageText:HTStringByReplacingHoptoadVariablesInString(title)
									 defaultButton:HTLocalizedString(@"ALWAYS_SEND")
								   alternateButton:HTLocalizedString(@"DONT_SEND")
									   otherButton:HTLocalizedString(@"SEND")
						 informativeTextWithFormat:HTStringByReplacingHoptoadVariablesInString(body)];
	NSInteger code = [alert runModal];
	if (code == NSAlertDefaultReturn) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:HTNotifierAlwaysSendKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[self performSelectorInBackground:@selector(postAllNoticesWithAutoreleasePool) withObject:nil];
	}
	else if (code == NSAlertAlternateReturn) {
		NSArray *noticePaths = HTNotices();
		for (NSString *notice in noticePaths) {
			[[NSFileManager defaultManager] removeItemAtPath:notice error:nil];
		}
	}
	else if (code == NSAlertOtherReturn) {
		[self performSelectorInBackground:@selector(postAllNoticesWithAutoreleasePool) withObject:nil];
	}
	
	if ([self.delegate respondsToSelector:@selector(notifierDidDismissAlert)]) {
		[self.delegate notifierDidDismissAlert];
	}
}

@end

#endif
