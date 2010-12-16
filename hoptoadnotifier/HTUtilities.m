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
+ (NSString *)applicationVersion {
	NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
	NSString *bundleVersion = [infoPlist objectForKey:@"CFBundleVersion"];
	NSString *bundleShortVersionString = [infoPlist objectForKey:@"CFBundleShortVersionString"];
	if (bundleShortVersionString == nil) { return bundleVersion; }
	else { return [NSString stringWithFormat:@"%@ (%@)", bundleVersion, bundleShortVersionString]; }
}
+ (NSString *)bundleDisplayName {
	NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
	NSString *bundleDisplayName = [infoPlist objectForKey:@"CFBundleDisplayName"];
	NSString *bundleName = [infoPlist objectForKey:@"CFBundleName"];
	NSString *bundleIdentifier = [infoPlist objectForKey:@"CFBundleIdentifier"];
	if (bundleDisplayName != nil) { return bundleDisplayName; }
	else if (bundleName != nil) { return bundleName; }
	else if (bundleIdentifier != nil) { return bundleIdentifier; }
	else { return nil; }
}
+ (NSString *)platform {
#if TARGET_IPHONE_SIMULATOR
	return @"iPhone Simulator";
#elif TARGET_OS_IPHONE
	size_t size = 256;
	char *machine = malloc(sizeof(char) * size);
	sysctlbyname("hw.machine", machine, &size, NULL, 0);
	NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
	// iphone
	if ([platform isEqualToString:@"iPhone1,1"]) { return @"iPhone"; }
	else if ([platform isEqualToString:@"iPhone1,2"]) { return @"iPhone 3G"; }
	else if ([platform isEqualToString:@"iPhone2,1"]) { return @"iPhone 3GS"; }
	else if ([platform isEqualToString:@"iPhone3,1"]) { return @"iPhone 4"; }
	// ipad
	else if ([platform isEqualToString:@"iPad1,1"]) { return @"iPad"; }
	// ipod
	else if ([platform isEqualToString:@"iPod1,1"]) { return @"iPod Touch"; }
	else if ([platform isEqualToString:@"iPod2,1"]) { return @"iPod Touch 2nd Gen"; }
	else if ([platform isEqualToString:@"iPod3,1"]) { return @"iPod Touch 3rd Gen"; }
	else if ([platform isEqualToString:@"iPod4,1"]) { return @"iPod Touch 4th Gen"; }
	// unknown
	else { return platform; }
#else
	size_t size = 256;
	char *machine = malloc(sizeof(char) * size);
	sysctlbyname("hw.model", machine, &size, NULL, 0);
	return [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
#endif
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
