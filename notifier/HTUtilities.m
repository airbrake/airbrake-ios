//
//  HTUtilities.m
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 10/13/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import <execinfo.h>
#import <sys/sysctl.h>
#import <UIKit/UIKit.h>

#import "HTUtilities.h"
#import "HTNotifier.h"

@implementation HTUtilities

+ (NSArray *)backtraceWithException:(NSException *)exc {
	NSArray *addresses = [exc callStackReturnAddresses];
	int frames = [addresses count];
	void *stack[frames];
	for (NSInteger i = 0; i < frames; i++) {
		stack[i] = (void *)[[addresses objectAtIndex:i] unsignedIntegerValue];
	}
	char **strs = backtrace_symbols(stack, frames);
	NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
	for (NSInteger i = 0; i < frames; i++) {
		NSString *entry = [NSString stringWithUTF8String:strs[i]];
		[backtrace addObject:entry];
	}
	free(strs);
	return backtrace;	
}
+ (NSString *)operatingSystemVersion {
#if TARGET_IPHONE_SIMULATOR
	
	return [[UIDevice currentDevice] systemVersion];
	
#else
	
	NSProcessInfo *process = [NSProcessInfo processInfo];
	return [process operatingSystemVersionString];
	
#endif
}
+ (NSString *)applicationVersion {
	NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
	NSString *bundleVersion = [infoPlist objectForKey:@"CFBundleVersion"];
	NSString *bundleShortVersionString = [infoPlist objectForKey:@"CFBundleShortVersionString"];
	if (bundleShortVersionString == nil) {
		return bundleVersion;
	}
	else {
		return [[NSString stringWithFormat:@"%@ (%@)", bundleVersion, bundleShortVersionString] retain];
	}
}
+ (NSString *)platform {
#if TARGET_IPHONE_SIMULATOR
	
	return @"iPhone Simulator";
	
#else
	
	// get platform
	size_t size = 256;
	char *machine = malloc(sizeof(char) * size);
	sysctlbyname("hw.machine", machine, &size, NULL, 0);
	NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
	NSLog(@"%@", platform);
	
	// get common device name
	NSString *commonString = nil;
	if ([platform isEqualToString:@"iPhone1,1"]) { commonString = @"iPhone"; }
	else if ([platform isEqualToString:@"iPhone1,2"]) { commonString = @"iPhone 3G"; }
	else if ([platform isEqualToString:@"iPhone2,1"]) { commonString = @"iPhone 3GS"; }
	else if ([platform isEqualToString:@"iPhone3,1"]) { commonString = @"iPhone 4"; }
	else if ([platform isEqualToString:@"iPad1,1"]) { commonString = @"iPad"; }
	if (commonString != nil) {
		platform = [NSString stringWithFormat:@"%@ (%@)", commonString, platform];
	}
	
	return platform;
	
#endif
}
+ (NSDictionary *)signals {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"SIGABRT", [NSNumber numberWithInteger:SIGABRT],
			@"SIGBUS", [NSNumber numberWithInteger:SIGBUS],
			@"SIGFPE", [NSNumber numberWithInteger:SIGFPE],
			@"SIGILL", [NSNumber numberWithInteger:SIGILL],
			@"SIGSEGV", [NSNumber numberWithInteger:SIGSEGV],
			@"SIGTRAP", [NSNumber numberWithInteger:SIGTRAP],
			nil];
}
+ (NSString *)currentViewController {
	// view controller to inspect
	UIViewController *rootController = nil;
	
	// try getting view controller from notifier delegate
	id<HTNotifierDelegate> notifierDelegate = [[HTNotifier sharedNotifier] delegate];
	if (rootController == nil && [notifierDelegate respondsToSelector:@selector(rootViewControllerForNotice)]) {
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

@end
