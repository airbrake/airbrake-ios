/*
 
 Copyright (C) 2011 GUI Cocoa, LLC.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import <execinfo.h>
#import <fcntl.h>
#import <unistd.h>
#import <sys/sysctl.h>

#import "RegexKitLite.h"

#import "HTFunctions.h"
#import "HTNotifier.h"
#import "HTNotice.h"

NSString *HTNotifierDirectoryName = @"Hoptoad Notices";

// handled signals
int ht_signals_count = 6;
int ht_signals[] = {
	SIGABRT,
	SIGBUS,
	SIGFPE,
	SIGILL,
	SIGSEGV,
	SIGTRAP
};

// internal function prototypes
void ht_handle_signal(int, siginfo_t *, void *);
void ht_handle_exception(NSException *);
int ht_open_file(int);

#pragma mark crash time methods
void ht_handle_signal(int signal, siginfo_t *info, void *context) {
    HTStopSignalHandler();
    int fd = ht_open_file(HTSignalNoticeType);
    if (fd > -1) {
		
		// signal
        write(fd, &signal, sizeof(int));
        
        // environment info
        write(fd, &ht_notice_info.env_info_len, sizeof(unsigned long));
        write(fd, ht_notice_info.env_info, ht_notice_info.env_info_len);
		
		// backtraces
		int count = 128;
		void *frames[count];
		count = backtrace(frames, count);
		backtrace_symbols_fd(frames, count, fd);
		
		// close
        close(fd);
    }
	
	// re raise
	raise(signal);
}
void ht_handle_exception(NSException *exception) {
    HTStopHandlers();
    int fd = ht_open_file(HTExceptionNoticeType);
    if (fd > -1) {
        
		// crash info
		NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:5];
		
		// addresses
        NSArray *addresses = [exception callStackReturnAddresses];
		NSArray *symbols = HTCallStackSymbolsFromReturnAddresses(addresses);
		[dictionary setObject:symbols forKey:@"call stack"];
		
		// exception name and reason
		[dictionary setObject:[exception name] forKey:@"exception name"];
		[dictionary setObject:[exception reason] forKey:@"exception reason"];
		
#if TARGET_OS_IPHONE
		
		// view controller
		NSString *viewController = HTCurrentViewController();
		if (viewController != nil) {
			[dictionary setObject:viewController forKey:@"view controller"];
		}
		
#endif
		
		// environment info
        [[HTNotifier sharedNotifier] setEnvironmentValue:[[exception userInfo] description] forKey:@"Exception"];
		NSDictionary *environmentInfo = [[HTNotifier sharedNotifier] environmentInfo];
		[dictionary setObject:environmentInfo forKey:@"environment info"];
		
        // write data
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
        NSUInteger length = [data length];
        write(fd, &length, sizeof(unsigned long));
        write(fd, [data bytes], length);
        
        // close file
        close(fd);
        
    }
	id<HTNotifierDelegate> delegate = [[HTNotifier sharedNotifier] delegate];
	if ([delegate respondsToSelector:@selector(notifierDidHandleException:)]) {
		[delegate notifierDidHandleException:exception];
	}
}
int ht_open_file(int type) {
    int fd = open(ht_notice_info.notice_path, O_WRONLY | O_CREAT, S_IREAD | S_IWRITE);
    if (fd > -1) {
        write(fd, &HTNoticeFileVersion, sizeof(int));
        write(fd, &type, sizeof(int));
        write(fd, &ht_notice_info.os_version_len, sizeof(unsigned long));
        if (ht_notice_info.os_version_len > 0) {
            write(fd, ht_notice_info.os_version, ht_notice_info.os_version_len);
        }
        write(fd, &ht_notice_info.platform_len, sizeof(unsigned long));
        if (ht_notice_info.platform_len > 0) {
            write(fd, ht_notice_info.platform, ht_notice_info.platform_len);
        }
        write(fd, &ht_notice_info.app_version_len, sizeof(unsigned long));
        if (ht_notice_info.app_version_len > 0) {
            write(fd, ht_notice_info.app_version, ht_notice_info.app_version_len);
        }
        write(fd, &ht_notice_info.env_name_len, sizeof(unsigned long));
        if (ht_notice_info.env_name_len > 0) {
            write(fd, ht_notice_info.env_name, ht_notice_info.env_name_len);
        }
        write(fd, &ht_notice_info.bundle_version_len, sizeof(unsigned long));
        if (ht_notice_info.bundle_version_len > 0) {
            write(fd, ht_notice_info.bundle_version, ht_notice_info.bundle_version_len);
        }
    }
    return fd;
}

#pragma mark - modify handler state
void HTStartHandlers() {
    HTStartExceptionHandler();
    HTStartSignalHandler();
}
void HTStartExceptionHandler() {
    NSSetUncaughtExceptionHandler(&ht_handle_exception);
}
void HTStartSignalHandler() {
	for (NSUInteger i = 0; i < ht_signals_count; i++) {
		int signal = ht_signals[i];
		struct sigaction action;
		sigemptyset(&action.sa_mask);
		action.sa_flags = SA_SIGINFO;
		action.sa_sigaction = ht_handle_signal;
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
	for (NSUInteger i = 0; i < ht_signals_count; i++) {
		int signal = ht_signals[i];
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
NSString *HTExecutableName() {
	return HTInfoPlistValueForKey(@"CFBundleExecutable");
}
NSString *HTApplicationVersion() {
	NSString *bundleVersion = HTBundleVersion();
	NSString *versionString = HTInfoPlistValueForKey(@"CFBundleShortVersionString");
	if (bundleVersion != nil && versionString != nil) {
		return [NSString stringWithFormat:@"%@ (%@)", versionString, bundleVersion];
	}
	else if (bundleVersion != nil) { return bundleVersion; }
	else if (versionString != nil) { return versionString; }
	else { return nil; }
}
NSString *HTBundleVersion() {
    return HTInfoPlistValueForKey(@"CFBundleVersion");
}
NSString *HTApplicationName() {
	NSString *displayName = HTInfoPlistValueForKey(@"CFBundleDisplayName");
	NSString *bundleName = HTInfoPlistValueForKey(@"CFBundleName");
	NSString *identifier = HTInfoPlistValueForKey(@"CFBundleIdentifier");
	if (displayName != nil) { return displayName; }
	else if (bundleName != nil) { return bundleName; }
	else if (identifier != nil) { return identifier; }
	else { return nil; }
}

#pragma mark - platform accessors
NSString *HTOperatingSystemVersion() {
#if TARGET_IPHONE_SIMULATOR
	return [[UIDevice currentDevice] systemVersion];
#else
	return [[NSProcessInfo processInfo] operatingSystemVersionString];
#endif
}
NSString *HTMachine() {
#if TARGET_IPHONE_SIMULATOR
	return @"iPhone Simulator";
#else
    
    size_t size = 256;
	char *machine = malloc(size);
#if TARGET_OS_IPHONE
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
#else
    sysctlbyname("hw.model", machine, &size, NULL, 0);
#endif
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    return platform;
    
#endif
}
NSString *HTPlatform() {
#if TARGET_IPHONE_SIMULATOR
	return @"iPhone Simulator";
#else
    
    NSString *machine = HTMachine();
#if TARGET_OS_IPHONE
    // iphone
	if ([machine isEqualToString:@"iPhone1,1"]) { return @"iPhone"; }
	else if ([machine isEqualToString:@"iPhone1,2"]) { return @"iPhone 3G"; }
	else if ([machine isEqualToString:@"iPhone2,1"]) { return @"iPhone 3GS"; }
	else if ([machine isEqualToString:@"iPhone3,1"]) { return @"iPhone 4 (GSM)"; }
    else if ([machine isEqualToString:@"iPhone3,3"]) { return @"iPhone 4 (CDMA)"; }
	// ipad
	else if ([machine isEqualToString:@"iPad1,1"]) { return @"iPad"; }
    else if ([machine isEqualToString:@"iPad2,1"]) { return @"iPad 2 (WiFi)"; }
    else if ([machine isEqualToString:@"iPad2,2"]) { return @"iPad 2 (GSM)"; }
    else if ([machine isEqualToString:@"iPad2,3"]) { return @"iPad 2 (CDMA)"; }
	// ipod
	else if ([machine isEqualToString:@"iPod1,1"]) { return @"iPod Touch"; }
	else if ([machine isEqualToString:@"iPod2,1"]) { return @"iPod Touch 2nd Gen"; }
	else if ([machine isEqualToString:@"iPod3,1"]) { return @"iPod Touch 3rd Gen"; }
	else if ([machine isEqualToString:@"iPod4,1"]) { return @"iPod Touch 4th Gen"; }
	// unknown
	else { return machine; }
#else
    return machine;
#endif
    
#endif
}

#pragma mark - init notice info
void HTInitNoticeInfo() {
    
    NSString *value;
    const char *value_str;
    NSUInteger length;
    
    // exception file name
    NSString *directory = HTNoticesDirectory();
    NSString *fileName = [NSString stringWithFormat:@"%d", time(NULL)];
    value = [directory stringByAppendingPathComponent:fileName];
    value = [value stringByAppendingPathExtension:HTNoticePathExtension];
    value_str = [value UTF8String];
    length = (strlen(value_str) + 1);
    ht_notice_info.notice_path = malloc(length);
    memcpy((void *)ht_notice_info.notice_path, value_str, length);
    
    // os version
    value = HTOperatingSystemVersion();
    if (value == nil) { HTLog(@"unable to cache operating system version"); }
    else {
        value_str = [value UTF8String];
        length = (strlen(value_str) + 1);
        ht_notice_info.os_version = malloc(length);
        ht_notice_info.os_version_len = length;
        memcpy((void *)ht_notice_info.os_version, value_str, length);
    }
    
    // app version
    value = HTApplicationVersion();
    if (value == nil) { HTLog(@"unable to cache app version"); }
    else {
        value_str = [value UTF8String];
        length = (strlen(value_str) + 1);
        ht_notice_info.app_version = malloc(length);
        ht_notice_info.app_version_len = length;
        memcpy((void *)ht_notice_info.app_version, value_str, length);
    }
    
    // platform
    value = HTPlatform();
    if (value == nil) { HTLog(@"unable to cache platform"); }
    else {
        value_str = [value UTF8String];
        length = (strlen(value_str) + 1);
        ht_notice_info.platform = malloc(length);
        ht_notice_info.platform_len = length;
        memcpy((void *)ht_notice_info.platform, value_str, length);
    }
    
    // environment
    value = [[HTNotifier sharedNotifier] environmentName];
    if (value == nil) { HTLog(@"unable to cache environment name"); }
    else {
        value_str = [value UTF8String];
        length = (strlen(value_str) + 1);
        ht_notice_info.env_name = malloc(length);
        ht_notice_info.env_name_len = length;
        memcpy((void *)ht_notice_info.env_name, value_str, length);
    }
    
    // bundle version
    value = HTInfoPlistValueForKey(@"CFBundleVersion");
    if (value == nil) { HTLog(@"unable to cache bundle version"); }
    else {
        value_str = [value UTF8String];
        length = (strlen(value_str) + 1);
        ht_notice_info.bundle_version = malloc(length);
        ht_notice_info.bundle_version_len = length;
        memcpy((void *)ht_notice_info.bundle_version, value_str, length);
    }
    
}
void HTReleaseNoticeInfo() {
    free((void *)ht_notice_info.notice_path);
    ht_notice_info.notice_path = NULL;
    free((void *)ht_notice_info.os_version);
    ht_notice_info.os_version = NULL;
    ht_notice_info.os_version_len = 0;
    free((void *)ht_notice_info.app_version);
    ht_notice_info.app_version = NULL;
    ht_notice_info.app_version_len = 0;
    free((void *)ht_notice_info.platform);
    ht_notice_info.platform = NULL;
    ht_notice_info.platform_len = 0;
    free((void *)ht_notice_info.env_name);
    ht_notice_info.env_name = NULL;
    ht_notice_info.env_name_len = 0;
    free((void *)ht_notice_info.bundle_version);
    ht_notice_info.bundle_version = NULL;
    ht_notice_info.bundle_version_len = 0;
    free(ht_notice_info.env_info);
    ht_notice_info.env_info = NULL;
    ht_notice_info.env_info_len = 0;
}

#pragma mark - notice information on disk
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
		if ([ext isEqualToString:HTNoticePathExtension]) {
			NSString *crashPath = [directory stringByAppendingPathComponent:file];
			[crashes addObject:crashPath];
		}
	}
	return crashes;
}

#pragma mark - callstack functions
NSArray *HTCallStackSymbolsFromReturnAddresses(NSArray *addresses) {
	NSUInteger frames = [addresses count];
	void *stack[frames];
	for (NSInteger i = 0; i < frames; i++) {
		stack[i] = (void *)[[addresses objectAtIndex:i] unsignedIntegerValue];
	}
	char **strs = backtrace_symbols(stack, (int)frames);
	NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
	for (NSInteger i = 0; i < frames; i++) {
		NSString *entry = [NSString stringWithUTF8String:strs[i]];
		[backtrace addObject:entry];
	}
	free(strs);
	return backtrace;
}
NSArray *HTParseCallstack(NSArray *symbols) {
    NSMutableArray *parsed = [NSMutableArray arrayWithCapacity:[symbols count]];
    NSString *pattern = @"([0-9]+)[:blank:]*(.*)(0x[0-9a-f]{8}.*)";
    NSCharacterSet *blank = [NSCharacterSet whitespaceCharacterSet];
    for (NSString *line in symbols) {
        NSArray *components = [line captureComponentsMatchedByRegex:pattern];
        NSMutableArray *frame = [[NSMutableArray alloc] initWithCapacity:3];
        for (NSInteger i = 1; i < [components count]; i++) {
            NSString *item = [[components objectAtIndex:i] stringByTrimmingCharactersInSet:blank];
            [frame addObject:item];
        }
        [parsed addObject:frame];
        [frame release];
    }
    return parsed;
}
NSString *HTActionFromParsedCallstack(NSArray *callStack) {
    NSString *executable = HTExecutableName();
    for (NSArray *line in callStack) {
        NSString *binary = [line objectAtIndex:1];
        NSString *method = [line objectAtIndex:2];
        if ([binary isEqualToString:executable] && [method rangeOfString:@"ht_handle_signal"].location == NSNotFound) {
            return method;
        }
    }
    return nil;
}

#pragma mark - string substitution
NSString * HTStringByReplacingHoptoadVariablesInString(NSString *string) {
	NSString *toReturn = string;
	
	toReturn = [toReturn
				stringByReplacingOccurrencesOfString:HTNotifierBundleName
				withString:HTApplicationName()];
	toReturn = [toReturn
				stringByReplacingOccurrencesOfString:HTNotifierBundleVersion
				withString:HTApplicationVersion()];
	
	return toReturn;
}

#pragma mark - get view controller
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
