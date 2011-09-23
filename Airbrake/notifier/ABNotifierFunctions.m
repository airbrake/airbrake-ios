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

#import "ABNotifierFunctions.h"
#import "ABNotice.h"

#import "HTNotifier.h"

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

#pragma mark crash time methods
void ht_handle_signal(int signal, siginfo_t *info, void *context) {
    
    // stop handler
    ABNotifierStopSignalHandler();
    
    // get file handle
    int fd = ABNotifierOpenNewNoticeFile(ab_signal_info.notice_path, ABNotifierSignalNoticeType);
    
    // write if we have a file
    if (fd > -1) {
		
		// signal
        write(fd, &signal, sizeof(int));
		
		// backtrace
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
    ABNotifierStopSignalHandler();
    ABNotifierStopExceptionHandler();
    [HTNotifier logException:exception];
}

#pragma mark - notice file methods
int ABNotifierOpenNewNoticeFile(const char *path, int type) {
    int fd = open(path, O_WRONLY | O_CREAT, S_IREAD | S_IWRITE);
    if (fd > -1) {
        
        // file version
        write(fd, &ABNotifierNoticeVersion, sizeof(int));
        
        // file bype
        write(fd, &type, sizeof(int));
        
        // notice payload
        write(fd, &ab_signal_info.notice_payload_length, sizeof(unsigned long));
        write(fd, ab_signal_info.notice_payload, ab_signal_info.notice_payload_length);
        
        // user data
        write(fd, &ab_signal_info.user_data_length, sizeof(unsigned long));
        write(fd, ab_signal_info.user_data, ab_signal_info.user_data_length);
        
    }
    return fd;
}

#pragma mark - modify handler state
void ABNotifierStartExceptionHandler(void) {
    NSSetUncaughtExceptionHandler(&ht_handle_exception);
}
void ABNotifierStartSignalHandler(void) {
    for (int i = 0; i < ht_signals_count; i++) {
		int signal = ht_signals[i];
		struct sigaction action;
		sigemptyset(&action.sa_mask);
		action.sa_flags = SA_SIGINFO;
		action.sa_sigaction = ht_handle_signal;
		if (sigaction(signal, &action, NULL) != 0) {
            ABLog(@"unable to register signal handler for %s", strsignal(signal));
		}
	}
}
void ABNotifierStopExceptionHandler(void) {
    NSSetUncaughtExceptionHandler(NULL);
}
void ABNotifierStopSignalHandler(void) {
	for (int i = 0; i < ht_signals_count; i++) {
		int signal = ht_signals[i];
		struct sigaction action;
		sigemptyset(&action.sa_mask);
		action.sa_handler = SIG_DFL;
		sigaction(signal, &action, NULL);
	}
}

#pragma mark - Info.plist accessors
NSString *ABNotifierApplicationVersion(void) {
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	if (bundleVersion != nil && versionString != nil) {
		return [NSString stringWithFormat:@"%@ (%@)", versionString, bundleVersion];
	}
	else if (bundleVersion != nil) { return bundleVersion; }
	else if (versionString != nil) { return versionString; }
	else { return nil; }
}
NSString *ABNotifierApplicationName(void) {
	NSString *displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	NSString *identifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
	if (displayName != nil) { return displayName; }
	else if (bundleName != nil) { return bundleName; }
	else if (identifier != nil) { return identifier; }
	else { return nil; }
}

#pragma mark - platform accessors
NSString *ABNotifierOperatingSystemVersion(void) {
    static NSString *version = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
#if TARGET_IPHONE_SIMULATOR
        version = [[[UIDevice currentDevice] systemVersion] copy];
#else
        version = [[[NSProcessInfo processInfo] operatingSystemVersionString] copy];
#endif
    });
    return version;
}
NSString *ABNotifierMachineName(void) {
#if TARGET_IPHONE_SIMULATOR
    return @"iPhone Simulator";
#else
    static NSString *name = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        size_t size = 256;
        char *machine = malloc(size);
#if TARGET_OS_IPHONE
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
#else
        sysctlbyname("hw.model", machine, &size, NULL, 0);
#endif
        name = [[NSString alloc] initWithCString:machine encoding:NSUTF8StringEncoding];
        free(machine);
    });
    return name;
#endif
}
NSString *ABNotifierPlatformName(void) {
#if TARGET_IPHONE_SIMULATOR || !TARGET_OS_IPHONE
    return ABNotifierMachineName();
#else
    static NSString *platform = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        NSString *machine = ABNotifierMachineName();
        // iphone
        if ([machine isEqualToString:@"iPhone1,1"]) { platform = @"iPhone"; }
        else if ([machine isEqualToString:@"iPhone1,2"]) { platform = @"iPhone 3G"; }
        else if ([machine isEqualToString:@"iPhone2,1"]) { platform = @"iPhone 3GS"; }
        else if ([machine isEqualToString:@"iPhone3,1"]) { platform = @"iPhone 4 (GSM)"; }
        else if ([machine isEqualToString:@"iPhone3,3"]) { platform = @"iPhone 4 (CDMA)"; }
        // ipad
        else if ([machine isEqualToString:@"iPad1,1"]) { platform = @"iPad"; }
        else if ([machine isEqualToString:@"iPad2,1"]) { platform = @"iPad 2 (WiFi)"; }
        else if ([machine isEqualToString:@"iPad2,2"]) { platform = @"iPad 2 (GSM)"; }
        else if ([machine isEqualToString:@"iPad2,3"]) { platform = @"iPad 2 (CDMA)"; }
        // ipod
        else if ([machine isEqualToString:@"iPod1,1"]) { platform = @"iPod Touch"; }
        else if ([machine isEqualToString:@"iPod2,1"]) { platform = @"iPod Touch (2nd generation)"; }
        else if ([machine isEqualToString:@"iPod3,1"]) { platform = @"iPod Touch (3rd generation)"; }
        else if ([machine isEqualToString:@"iPod4,1"]) { platform = @"iPod Touch (4th generation)"; }
        // unknown
        else { platform = machine; }
    });
    return platform;
#endif
}

#pragma mark - call stack functions
NSArray *ABNotifierParseCallStack(NSArray *callStack) {
    static NSString *pattern = @"^(\\d+)\\s+(\\S.*?)\\s+((0x[0-9a-f]+)\\s+.*)$";
    NSMutableArray *parsed = [NSMutableArray arrayWithCapacity:[callStack count]];
    [callStack enumerateObjectsUsingBlock:^(NSString *line, NSUInteger lineIndex, BOOL *stop) {
        NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:pattern options:(NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators) error:nil];
        NSArray *components = [regularExpression matchesInString:line options:NSMatchingReportCompletion range:NSMakeRange(0, line.length)];
        NSMutableArray *frame = [NSMutableArray arrayWithCapacity:[components count]];
        [components enumerateObjectsUsingBlock:^(NSTextCheckingResult *result, NSUInteger resultIndex, BOOL *stopComponents) {
            for (NSUInteger j = 0; j < [result numberOfRanges]; j++) {
                NSString *item = [line substringWithRange:[result rangeAtIndex:j]];
                [frame addObject:item];
            }
        }];
        [parsed addObject:frame];
    }];
    return parsed;
}
NSString *ABNotifierActionFromParsedCallStack(NSArray *callStack, NSString *executable) {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
        
        // check binary
        if (![[obj objectAtIndex:2] isEqualToString:executable]) {
            return NO;
        }
        
        // check method name
        NSRange range = [[obj objectAtIndex:3] rangeOfString:@"ht_handle_signal"];
        return range.location == NSNotFound;
        
    }];
    NSArray *matching = [callStack filteredArrayUsingPredicate:predicate];
    if ([matching count]) {
        return [[matching objectAtIndex:0] objectAtIndex:3];
    }
    else {
        return nil;
    }
}

#pragma mark - get view controller
#if TARGET_OS_IPHONE
NSString *ABNotifierCurrentViewController(void) {
    
    // assert
    NSCAssert([NSThread isMainThread], @"This function must be called on the main thread");
    
	// view controller to inspect
	UIViewController *rootController = nil;
    
	// try getting view controller from notifier delegate
	id<HTNotifierDelegate> delegte = [HTNotifier delegate];
	if ([delegte respondsToSelector:@selector(rootViewControllerForNotice)]) {
		rootController = [delegte rootViewControllerForNotice];
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
	return ABNotifierVisibleViewControllerFromViewController(rootController);
    
}

NSString *ABNotifierVisibleViewControllerFromViewController(UIViewController *controller) {
    
    // assert
    NSCAssert([NSThread isMainThread], @"This function must be called on the main thread");
	
	// tab bar controller
	if ([controller isKindOfClass:[UITabBarController class]]) {
		UIViewController *visibleController = [(UITabBarController *)controller selectedViewController];
		return ABNotifierVisibleViewControllerFromViewController(visibleController);
	}
    
	// navigation controller
	else if ([controller isKindOfClass:[UINavigationController class]]) {
		UIViewController *visibleController = [(UINavigationController *)controller visibleViewController];
		return ABNotifierVisibleViewControllerFromViewController(visibleController);
	}
    
	// other type
	else {
		return NSStringFromClass([controller class]);
	}
	
}
#endif
