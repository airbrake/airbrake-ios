//
//  HTUtilities.m
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 10/13/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import <execinfo.h>
#import <sys/sysctl.h>

#import "HTUtilities.h"
#import "HTNotifier.h"

static NSString * const HTNotifierFolderName = @"Hoptoad Notices";
static NSString * const HTNotifierPathExtension = @"notice";

@implementation HTUtilities

+ (NSString *)noticesDirectory {
#if TARGET_OS_IPHONE
	NSArray *folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString *path = [folders objectAtIndex:0];
	if ([folders count] == 0) { path = NSTemporaryDirectory(); }
	return [path stringByAppendingPathComponent:HTNotifierFolderName];
#else
	NSArray *folders = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *path = [folders objectAtIndex:0];
	if ([folders count] == 0) { path = NSTemporaryDirectory(); }
	path = [path stringByAppendingPathComponent:[self bundleDisplayName]];
	return [path stringByAppendingPathComponent:HTNotifierFolderName];
#endif
}
+ (NSArray *)noticePaths {
	NSString *directory = [self noticesDirectory];
	NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:nil];
	NSMutableArray *crashes = [NSMutableArray arrayWithCapacity:[directoryContents count]];
	for (NSString *file in directoryContents) {
		if ([[file pathExtension] isEqualToString:HTNotifierPathExtension]) {
			NSString *crashPath = [directory stringByAppendingPathComponent:file];
			[crashes addObject:crashPath];
		}
	}
	return crashes;
}
+ (NSString *)noticePathWithName:(NSString *)name {
	NSString *path = [[self noticesDirectory] stringByAppendingPathComponent:name];
	return [path stringByAppendingPathExtension:HTNotifierPathExtension];
}
+ (NSString *)stringBySubstitutingHoptoadVariablesInString:(NSString *)string {
	NSMutableString *mutable = [string mutableCopy];
	NSRange fullRange = NSMakeRange(0, [mutable length]);
	
	[mutable replaceOccurrencesOfString:HTNotifierBundleName
							 withString:[self bundleDisplayName]
								options:0
								  range:fullRange];
	
	[mutable replaceOccurrencesOfString:HTNotifierBundleVersion
							 withString:[self applicationVersion]
								options:0
								  range:fullRange];
	
	[mutable replaceOccurrencesOfString:HTNotifierBuildDate
							 withString:[NSString stringWithFormat:@"%s", __DATE__]
								options:0
								  range:fullRange];
	
	[mutable replaceOccurrencesOfString:HTNotifierBuildTime
							 withString:[NSString stringWithFormat:@"%s", __TIME__]
								options:0
								  range:fullRange];
	
	NSString *toReturn = [NSString stringWithString:mutable];
	[mutable release];
	return toReturn;
}
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
	return [[NSProcessInfo processInfo] operatingSystemVersionString];
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
		return [NSString stringWithFormat:@"%@ (%@)", bundleVersion, bundleShortVersionString];
	}
}
+ (NSString *)bundleDisplayName {
	NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
	NSString *bundleDisplayName = [infoPlist objectForKey:@"CFBundleDisplayName"];
	NSString *bundleName = [infoPlist objectForKey:@"CFBundleName"];
	NSString *bundleIdentifier = [infoPlist objectForKey:@"CFBundleIdentifier"];
	if (bundleDisplayName != nil) {
		return bundleDisplayName;
	}
	else if (bundleName != nil) {
		return bundleName;
	}
	else if (bundleIdentifier != nil) {
		return bundleIdentifier;
	}
	return nil;
}
+ (NSString *)platform {
#if TARGET_IPHONE_SIMULATOR
	return @"iPhone Simulator";
#elif TARGET_OS_IPHONE
	size_t size = 256;
	char *machine = malloc(sizeof(char) * size);
	sysctlbyname("hw.machine", machine, &size, NULL, 0);
	NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
	return platform;
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
#else
	size_t size = 256;
	char *machine = malloc(sizeof(char) * size);
	sysctlbyname("hw.model", machine, &size, NULL, 0);
	return [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
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
