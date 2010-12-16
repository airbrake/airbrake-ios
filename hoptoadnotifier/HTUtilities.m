//
//  HTUtilities.m
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 10/13/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import "HTNotifier.h"



@implementation HTUtilities

+ (NSString *)noticePathWithName:(NSString *)name {
	NSString *path = [[self noticesDirectory] stringByAppendingPathComponent:name];
	return [path stringByAppendingPathExtension:HTNotifierPathExtension];
}
+ (NSString *)stringByReplacingHoptoadVariablesInString:(NSString *)string {
	NSMutableString *mutable = [string mutableCopy];
	
	[mutable replaceOccurrencesOfString:HTNotifierBundleName
							 withString:[self bundleDisplayName]
								options:0
								  range:NSMakeRange(0, [mutable length])];
	
	[mutable replaceOccurrencesOfString:HTNotifierBundleVersion
							 withString:[self applicationVersion]
								options:0
								  range:NSMakeRange(0, [mutable length])];
	
	[mutable replaceOccurrencesOfString:HTNotifierBuildDate
							 withString:[NSString stringWithFormat:@"%s", __DATE__]
								options:0
								  range:NSMakeRange(0, [mutable length])];
	
	[mutable replaceOccurrencesOfString:HTNotifierBuildTime
							 withString:[NSString stringWithFormat:@"%s", __TIME__]
								options:0
								  range:NSMakeRange(0, [mutable length])];
	
	NSString *toReturn = [NSString stringWithString:mutable];
	[mutable release];
	return toReturn;
}
#if TARGET_OS_IPHONE
+ (NSString *)currentViewController {
	// view controller to inspect
	UIViewController *rootController = nil;
	
	// try getting view controller from notifier delegate
	id<HTNotifierDelegate> notifierDelegate = [[HTNotifier sharedNotifier] delegate];
	if ([notifierDelegate respondsToSelector:@selector(rootViewControllerForNotice)]) {
		rootController = [notifierDelegate rootViewControllerForNotice];
	}
	
	// try getting view controller from window
	UIApplication *app = [UIApplication sharedApplication];
	UIWindow *keyWindow = [app keyWindow];
	if (rootController == nil && [keyWindow respondsToSelector:@selector(rootViewController)]) {
		rootController = [keyWindow rootViewController];
	}
	
	// if we don't have a controller yet, give up
	if (rootController == nil) {
		return nil;
	}
	
	// call method to get class name
	return [self visibleViewControllerWithViewController:rootController];
}
+ (NSString *)visibleViewControllerWithViewController:(UIViewController *)controller {
	// tab bar controller
	if ([controller isKindOfClass:[UITabBarController class]]) {
		UIViewController *visibleController = [(UITabBarController *)controller selectedViewController];
		return [self visibleViewControllerWithViewController:visibleController];
	}
	// navigation controller
	else if ([controller isKindOfClass:[UINavigationController class]]) {
		UIViewController *visibleController = [(UINavigationController *)controller visibleViewController];
		return [self visibleViewControllerWithViewController:visibleController];
	}
	// other type
	else {
		return NSStringFromClass([controller class]);
	}
}
#endif

@end
