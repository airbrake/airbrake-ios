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
#import <fcntl.h>
#import <unistd.h>

#import "HTNotifier.h"

#pragma mark - handlers
void HTHandleSignal(int signal) {
	
#if 0    
    
	// stop handlers
	HTStopHandler();
	
	// create notice and set properties
	NSArray *addresses = [NSThread callStackReturnAddresses];
	HTNotice *notice = [HTNotice notice];
	notice.exceptionName = [NSString stringWithUTF8String:strsignal(signal)];
	notice.exceptionReason = @"Application received signal";
	notice.callStack = HTCallStackSymbolsFromReturnAddresses(addresses);
	
	// write notice
	[notice writeToFile:[NSString stringWithUTF8String:ht_notice_info.file_name]];
	
	// delegate call
	id<HTNotifierDelegate> delegate = [[HTNotifier sharedNotifier] delegate];
	if ([delegate respondsToSelector:@selector(notifierDidHandleSignal:)]) {
		[delegate notifierDidHandleSignal:signal];
	}
	
	// re raise
	raise(signal);
    
#else
    
    // stop handlers
    HTStopSignalHandler();
    
    // open file
    NSLog(@"%s", ht_notice_info.signal_file);
    int fd = open(ht_notice_info.signal_file, O_WRONLY | O_CREAT, S_IREAD | S_IWRITE);
    if (fd == -1) { NSLog(@"%d", errno); }
    else {
        // write signal
        write(fd, &signal, sizeof(int));
        // write os version
        write(fd, &ht_notice_info.os_version_len, sizeof(int));
        write(fd, ht_notice_info.os_version, ht_notice_info.os_version_len);
        // write platform
        write(fd, &ht_notice_info.platform_len, sizeof(int));
        write(fd, ht_notice_info.platform, ht_notice_info.platform_len);
        // write app version
        write(fd, &ht_notice_info.app_version_len, sizeof(int));
        write(fd, ht_notice_info.app_version, ht_notice_info.app_version_len);
        // write environment
        write(fd, &ht_notice_info.env_name_len, sizeof(int));
        write(fd, ht_notice_info.env_name, ht_notice_info.env_name_len);
        // close value
        close(fd);
    }
    
    // re-raise
    //raise(signal);
    
#endif
	
}
void HTHandleException(NSException *e) {
	HTStopHandlers();
	HTNotice *notice = [HTNotice noticeWithException:e];
	[notice writeToFile:[NSString stringWithUTF8String:ht_notice_info.exception_file]];
	id<HTNotifierDelegate> delegate = [[HTNotifier sharedNotifier] delegate];
	if ([delegate respondsToSelector:@selector(notifierDidHandleException:)]) {
		[delegate notifierDidHandleException:e];
	}
}

#pragma mark - modify handler state
void HTStartHandlers() {
    HTStartExceptionHandler();
    HTStartSignalHandler();
}
void HTStartExceptionHandler() {
    NSSetUncaughtExceptionHandler(&HTHandleException);
}
void HTStartSignalHandler() {
    NSArray *signals = HTHandledSignals();
	for (NSUInteger i = 0; i < [signals count]; i++) {
		NSInteger signal = [[signals objectAtIndex:i] integerValue];
		struct sigaction action;
		sigemptyset(&action.sa_mask);
		action.sa_handler = HTHandleSignal;
		if (sigaction(signal, &action, NULL) != 0) {
            HTLog(@"unable to register signal handler for %s", strsignal(signal));
		}
	}
}
void HTStopHandlers() {
    HTStopExceptionHandler();
    HTStopSignalHandler();
}
void HTStopExceptionHandler() {
    NSSetUncaughtExceptionHandler(NULL);
}
void HTStopSignalHandler() {
    NSArray *signals = HTHandledSignals();
	for (NSUInteger i = 0; i < [signals count]; i++) {
		NSInteger signal = [[signals objectAtIndex:i] integerValue];
		struct sigaction action;
		sigemptyset(&action.sa_mask);
		action.sa_handler = SIG_DFL;
		sigaction(signal, &action, NULL);
	}
}

#pragma mark - Info.plist accessors
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

#pragma mark - platform accessors
NSString * HTOperatingSystemVersion() {
#if TARGET_IPHONE_SIMULATOR
	return [[UIDevice currentDevice] systemVersion];
#else
	return [[NSProcessInfo processInfo] operatingSystemVersionString];
#endif
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
	else if ([platform isEqualToString:@"iPhone3,1"]) { return @"iPhone 4 (GSM)"; }
    else if ([platform isEqualToString:@"iPhone3,3"]) { return @"iPhone 4 (CDMA)"; }
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

#pragma mark - init notice info
void HTInitNoticeInfo() {
    
    NSString *value;
    char *value_str;
    NSUInteger length;
    
    // file path stuff
    NSString *directory = HTNoticesDirectory();
    NSString *fileName = [NSString stringWithFormat:@"%d", time(NULL)];
    
    // exception file name
    value = [directory stringByAppendingPathComponent:fileName];
    value = [value stringByAppendingPathExtension:HTNotifierExceptionNoticeExtension];
    length = [value length] * sizeof(char);
    value_str = malloc(length);
    memcpy(value_str, [value UTF8String], length);
    ht_notice_info.exception_file = value_str;
    
    // signal file name
    value = [directory stringByAppendingPathComponent:fileName];
    value = [value stringByAppendingPathExtension:HTNotifierSignalNoticeExtension];
    length = [value length] * sizeof(char);
    value_str = malloc(length);
    memcpy(value_str, [value UTF8String], length);
    ht_notice_info.signal_file = value_str;
    
    // os version
    value = HTOperatingSystemVersion();
    length = [value length] * sizeof(char);
    value_str = malloc(length);
    memcpy(value_str, [value UTF8String], length);
    ht_notice_info.os_version = value_str;
    ht_notice_info.os_version_len = length;
    
    // app version
    value = HTApplicationVersion();
    length = [value length] * sizeof(char);
    value_str = malloc(length);
    memcpy(value_str, [value UTF8String], length);
    ht_notice_info.app_version = value_str;
    ht_notice_info.app_version_len = length;
    
    // platform
    value = HTPlatform();
    length = [value length] * sizeof(char);
    value_str = malloc(length);
    strcpy(value_str, [value UTF8String]);
    ht_notice_info.app_version = value_str;
    ht_notice_info.app_version_len = length;
    
    // environment name
    value = [[HTNotifier sharedNotifier] environmentName];
    length = [value length] * sizeof(char);
    value_str = malloc(length);
    memcpy(value_str, [value UTF8String], length);
    ht_notice_info.env_name = value_str;
    ht_notice_info.env_name_len = length;
    
}
void HTReleaseNoticeInfo() {
    free((void *)ht_notice_info.exception_file);
    ht_notice_info.exception_file = NULL;
    free((void *)ht_notice_info.signal_file);
    ht_notice_info.signal_file = NULL;
    free((void *)ht_notice_info.os_version);
    ht_notice_info.os_version = NULL;
    free((void *)ht_notice_info.app_version);
    ht_notice_info.app_version = NULL;
    free((void *)ht_notice_info.platform);
    ht_notice_info.platform = NULL;
    free((void *)ht_notice_info.env_name);
    ht_notice_info.env_name = NULL;
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

NSArray * HTParseCallstack(NSArray *symbols) {
	NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSCharacterSet *nonWhiteSpace = [whiteSpace invertedSet];
	NSMutableArray *parsed = [NSMutableArray arrayWithCapacity:[symbols count]];
	for (NSString *line in symbols) {
		NSScanner *scanner = [NSScanner scannerWithString:line];
		
		// line number
		NSInteger number;
		[scanner scanInteger:&number];
		
		// binary name
		NSString *binary;
		[scanner scanCharactersFromSet:nonWhiteSpace intoString:&binary];

		// method
        NSString *method = @"";
        if ([[HTNotifier sharedNotifier] stripCallStack]) {
            [scanner scanCharactersFromSet:nonWhiteSpace intoString:NULL];
            NSUInteger startLocation = [scanner scanLocation];
            NSUInteger endLocation = [line rangeOfString:@" +" options:NSBackwardsSearch].location;
            method = [line substringWithRange:NSMakeRange(startLocation, endLocation - startLocation)];
            method = [method stringByTrimmingCharactersInSet:whiteSpace];
        }
        else {
            NSUInteger location = [scanner scanLocation];
            method = [line substringFromIndex:location];
            method = [method stringByTrimmingCharactersInSet:whiteSpace];
        }
		
		// add line
		[parsed addObject:
		 [NSDictionary dictionaryWithObjectsAndKeys:
		  [NSNumber numberWithInteger:number], @"number",
		  binary, @"file",
		  method, @"method",
		  nil]];
	}
	return parsed;
}

NSString * HTActionFromCallstack(NSArray *callStack) {
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"file like %@", HTExecutableName()];
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"number" ascending:YES];
	NSArray *matching = [callStack filteredArrayUsingPredicate:predicate];
	matching = [matching sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
	matching = [matching valueForKey:@"method"];
	[sort release];
	for (NSString *file in matching) {
		if ([file isEqualToString:@"HTHandleSignal"]) {
			continue;
		}
		else {
			return file;
		}
	}
	return @"";
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
        NSString *ext = [file pathExtension];
		if ([ext isEqualToString:HTNotifierSignalNoticeExtension] ||
            [ext isEqualToString:HTNotifierExceptionNoticeExtension]) {
			NSString *crashPath = [directory stringByAppendingPathComponent:file];
			[crashes addObject:crashPath];
		}
	}
	return crashes;
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
