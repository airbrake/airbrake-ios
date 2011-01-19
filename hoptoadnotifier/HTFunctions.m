//
//  HTHandler.m
//  CrashPhone
//
//  Created by Caleb Davenport on 12/15/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import <execinfo.h>
#import <sys/types.h>
#import <sys/sysctl.h>

#import "HTNotifier.h"

static void HTHandleSignal(int signal) {
	
	// stop handlers
	HTStopHandler();
	
	// create notice and set properties
	NSArray *addresses = [NSThread callStackReturnAddresses];
	HTNotice *notice = [HTNotice notice];
	notice.exceptionName = [NSString stringWithUTF8String:strsignal(signal)];
	notice.exceptionReason = @"Application received signal";
	notice.callStack = HTCallStackSymbolsFromReturnAddresses(addresses);
	
	// write notice
	NSString *name = [NSString stringWithFormat:@"%d", time(NULL)];
	[notice writeToFile:HTPathForNewNoticeWithName(name)];
	
	// delegate call
	id<HTNotifierDelegate> delegate = [[HTNotifier sharedNotifier] delegate];
	if ([delegate respondsToSelector:@selector(notifierDidHandleSignal:)]) {
		[delegate notifierDidHandleSignal:signal];
	}
	
	// re raise
	raise(signal);
	
}

static void HTHandleException(NSException *e) {
	
	// stop handlers
	HTStopHandler();
	
	// create notice and set properties
	HTNotice *notice = [HTNotice noticeWithException:e];
	
	// write notice
	NSString *name = [NSString stringWithFormat:@"%d", time(NULL)];
	[notice writeToFile:HTPathForNewNoticeWithName(name)];
	
	// delegate call
	id<HTNotifierDelegate> delegate = [[HTNotifier sharedNotifier] delegate];
	if ([delegate respondsToSelector:@selector(notifierDidHandleException:)]) {
		[delegate notifierDidHandleException:e];
	}
	
}

NSArray * HTHandledSignals() {
	return [NSArray arrayWithObjects:
			[NSNumber numberWithInteger:SIGABRT],
			[NSNumber numberWithInteger:SIGBUS],
			[NSNumber numberWithInteger:SIGFPE],
			[NSNumber numberWithInteger:SIGILL],
			[NSNumber numberWithInteger:SIGSEGV],
			[NSNumber numberWithInteger:SIGTRAP],
			nil];
}

void HTStartHandler() {
	NSSetUncaughtExceptionHandler(&HTHandleException);
	NSArray *signals = HTHandledSignals();
	for (NSUInteger i = 0; i < [signals count]; i++) {
		NSInteger signal = [[signals objectAtIndex:i] integerValue];
		struct sigaction action;
		sigemptyset(&action.sa_mask);
		action.sa_handler = HTHandleSignal;
		if (sigaction(signal, &action, NULL) != 0) {
			NSLog(@"[Hoptoad] unable to register signal handler for %s", strsignal(signal));
		}
	}
}

void HTStopHandler() {
	NSSetUncaughtExceptionHandler(NULL);
	NSArray *signals = HTHandledSignals();
	for (NSUInteger i = 0; i < [signals count]; i++) {
		NSInteger signal = [[signals objectAtIndex:i] integerValue];
		struct sigaction action;
		sigemptyset(&action.sa_mask);
		action.sa_handler = SIG_DFL;
		sigaction(signal, &action, NULL);
	}
}

NSArray * HTCallStackSymbolsFromReturnAddresses(NSArray *addresses) {
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

NSString * HTNoticesDirectory() {
#if TARGET_OS_IPHONE
	NSArray *folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString *path = [folders objectAtIndex:0];
	if ([folders count] == 0) { path = NSTemporaryDirectory(); }
	return [path stringByAppendingPathComponent:HTNotifierDirectoryName];
#else
	NSArray *folders = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *path = [folders objectAtIndex:0];
	if ([folders count] == 0) { path = NSTemporaryDirectory(); }
	path = [path stringByAppendingPathComponent:HTApplicationName()];
	return [path stringByAppendingPathComponent:HTNotifierDirectoryName];
#endif
}

NSArray * HTNotices() {
	NSString *directory = HTNoticesDirectory();
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

NSString * HTOperatingSystemVersion() {
#if TARGET_IPHONE_SIMULATOR
	return [[UIDevice currentDevice] systemVersion];
#else
	return [[NSProcessInfo processInfo] operatingSystemVersionString];
#endif
}

id HTInfoPlistValueForKey(NSString *key) {
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:key];
}

NSString * HTExecutableName() {
	return HTInfoPlistValueForKey(@"CFBundleExecutable");
}

NSString * HTApplicationVersion() {
	NSString *bundleVersion = HTInfoPlistValueForKey(@"CFBundleVersion");
	NSString *versionString = HTInfoPlistValueForKey(@"CFBundleShortVersionString");
	if (bundleVersion != nil && versionString != nil) {
		return [NSString stringWithFormat:@"%@ (%@)", versionString, bundleVersion];
	}
	else if (bundleVersion != nil) { return bundleVersion; }
	else if (versionString != nil) { return versionString; }
	else { return nil; }
}

NSString * HTApplicationName() {
	NSString *displayName = HTInfoPlistValueForKey(@"CFBundleDisplayName");
	NSString *bundleName = HTInfoPlistValueForKey(@"CFBundleName");
	NSString *identifier = HTInfoPlistValueForKey(@"CFBundleIdentifier");
	if (displayName != nil) { return displayName; }
	else if (bundleName != nil) { return bundleName; }
	else if (identifier != nil) { return identifier; }
	else { return nil; }
}

NSString * HTPlatform() {
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

NSString * HTPathForNewNoticeWithName(NSString *name) {
	NSString *path = [HTNoticesDirectory() stringByAppendingPathComponent:name];
	return [path stringByAppendingPathExtension:HTNotifierPathExtension];
}

NSString * HTStringByReplacingHoptoadVariablesInString(NSString *string) {
	NSMutableString *mutable = [string mutableCopy];
	
	[mutable replaceOccurrencesOfString:HTNotifierBundleName
							 withString:HTApplicationName()
								options:0
								  range:NSMakeRange(0, [mutable length])];
	
	[mutable replaceOccurrencesOfString:HTNotifierBundleVersion
							 withString:HTApplicationVersion()
								options:0
								  range:NSMakeRange(0, [mutable length])];
	
	NSString *toReturn = [NSString stringWithString:mutable];
	[mutable release];
	return toReturn;
}

#if TARGET_OS_IPHONE
NSString * HTCurrentViewController() {
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
	return HTVisibleViewControllerWithViewController(rootController);
}

NSString * HTVisibleViewControllerWithViewController(UIViewController *controller) {
	
	// tab bar controller
	if ([controller isKindOfClass:[UITabBarController class]]) {
		UIViewController *visibleController = [(UITabBarController *)controller selectedViewController];
		return HTVisibleViewControllerWithViewController(visibleController);
	}
	// navigation controller
	else if ([controller isKindOfClass:[UINavigationController class]]) {
		UIViewController *visibleController = [(UINavigationController *)controller visibleViewController];
		return HTVisibleViewControllerWithViewController(visibleController);
	}
	// other type
	else {
		return NSStringFromClass([controller class]);
	}
	
}
#endif

void HTLog(NSString *frmt, ...) {
	va_list list;
	va_start(list, frmt);
	NSLog(@"%@", HTLogStringWithArguments(frmt, list));
	va_end(list);
}

NSString * HTLogStringWithFormat(NSString *fmt, ...) {
	va_list list;
	va_start(list, fmt);
	NSString *toReturn = HTLogStringWithArguments(fmt, list);
	va_end(list);
	return toReturn;
}

NSString * HTLogStringWithArguments(NSString *fmt, va_list args) {
	NSString *format = [[NSString alloc] initWithFormat:fmt arguments:args];
	NSString *toReturn = [@"[Hoptoad] " stringByAppendingString:format];
	[format release];
	return toReturn;
}
