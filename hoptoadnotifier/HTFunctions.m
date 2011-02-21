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

int ht_signals_count = 6;
int ht_signals[] = {
	SIGABRT,
	SIGBUS,
	SIGFPE,
	SIGILL,
	SIGSEGV,
	SIGTRAP
};

// file flags
static int HTNoticeFileVersion = 1;
static int HTSignalNoticeType = 1;
static int HTExceptionNoticeType = 2;

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
        
		// container
		NSMutableDictionary *crashInfo = [NSMutableDictionary dictionaryWithCapacity:5];
		
		// addresses
        NSArray *addresses = [exception callStackReturnAddresses];
		NSArray *symbols = HTCallStackSymbolsFromReturnAddresses(addresses);
		[crashInfo setObject:symbols forKey:@"symbols"];
		
		// exception name
		[crashInfo setObject:[exception name] forKey:@"name"];
		
		// exception reason
		[crashInfo setObject:[exception reason] forKey:@"reason"];
		
		// view controller
		NSString *viewController = HTCurrentViewController();
		if (viewController != nil) {
			[crashInfo setObject:viewController forKey:@"view controller"];
		}
		
		// environment info
		NSDictionary *environmentInfo = [[HTNotifier sharedNotifier] environmentInfo];
		[crashInfo setObject:environmentInfo forKey:@"info"];
		
        // write data
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:crashInfo];
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
		ht_notice_info.os_version_len = 0;
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
    const char *value_str;
    NSUInteger length;
    
    // file path stuff
    NSString *directory = HTNoticesDirectory();
    NSString *fileName = [NSString stringWithFormat:@"%d", time(NULL)];
    
    // exception file name
    value = [directory stringByAppendingPathComponent:fileName];
    value = [value stringByAppendingPathExtension:HTNotifierNoticePathExtension];
    value_str = [value UTF8String];
    length = (strlen(value_str) + 1) * sizeof(char);
    ht_notice_info.notice_path = malloc(length);
    memcpy((void *)ht_notice_info.notice_path, value_str, length);
    
    // os version
    value = HTOperatingSystemVersion();
    if (value == nil) { HTLog(@"unable to cache operating system version"); }
    else {
        value_str = [value UTF8String];
        length = (strlen(value_str) + 1) * sizeof(char);
        ht_notice_info.os_version = malloc(length);
        ht_notice_info.os_version_len = length;
        memcpy((void *)ht_notice_info.os_version, value_str, length);
    }
    
    // app version
    value = HTApplicationVersion();
    if (value == nil) { HTLog(@"unable to cache app version"); }
    else {
        value_str = [value UTF8String];
        length = (strlen(value_str) + 1) * sizeof(char);
        ht_notice_info.app_version = malloc(length);
        ht_notice_info.app_version_len = length;
        memcpy((void *)ht_notice_info.app_version, value_str, length);
    }
    
    // platform
    value = HTPlatform();
    if (value == nil) { HTLog(@"unable to cache platform"); }
    else {
        value_str = [value UTF8String];
        length = (strlen(value_str) + 1) * sizeof(char);
        ht_notice_info.platform = malloc(length);
        ht_notice_info.platform_len = length;
        memcpy((void *)ht_notice_info.platform, value_str, length);
    }
    
    // environment
    value = [[HTNotifier sharedNotifier] environmentName];
    if (value == nil) { HTLog(@"unable to cach environment name"); }
    else {
        value_str = [value UTF8String];
        length = (strlen(value_str) + 1) * sizeof(char);
        ht_notice_info.env_name = malloc(length);
        ht_notice_info.env_name_len = length;
        memcpy((void *)ht_notice_info.env_name, value_str, length);
    }
    
}
void HTReleaseNoticeInfo() {
    free((void *)ht_notice_info.notice_path);
    ht_notice_info.notice_path = NULL;
    free((void *)ht_notice_info.os_version);
    ht_notice_info.os_version = NULL;
    free((void *)ht_notice_info.app_version);
    ht_notice_info.app_version = NULL;
    free((void *)ht_notice_info.platform);
    ht_notice_info.platform = NULL;
    free((void *)ht_notice_info.env_name);
    ht_notice_info.env_name = NULL;
}

#pragma mark - notice information on disk
void HTReadNoticeInfoAtPath(NSString *path) {
    NSString *extension = [path pathExtension];
    if (![extension isEqualToString:HTNotifierNoticePathExtension]) {
        return;
    }
    
    // get file data
    NSUInteger location = 0;
    NSUInteger length = 0;
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    // get version
    int version;
    [data getBytes:&version range:NSMakeRange(location, sizeof(int))];
    location += sizeof(int);
    HTLog(@"version:%d", version);
    
    // get type
    int type;
    [data getBytes:&type range:NSMakeRange(location, sizeof(int))];
    location += sizeof(int);
    HTLog(@"type:%d", type);
    
    // os version
    [data getBytes:&length range:NSMakeRange(location, sizeof(unsigned long))];
    location += sizeof(unsigned long);
	NSString *OSVersion = nil;
	if (length > 0) {
		char * os_version = malloc(length * sizeof(char));
		[data getBytes:os_version range:NSMakeRange(location, length)];
		location += length;
		OSVersion = [NSString stringWithUTF8String:os_version];
		free(os_version);
	}
	HTLog(@"os:%@", OSVersion);
    
    // platform
    [data getBytes:&length range:NSMakeRange(location, sizeof(unsigned long))];
    location += sizeof(unsigned long);
	NSString *platform = nil;
	if (length > 0) {
		char * _platform = malloc(length * sizeof(char));
		[data getBytes:_platform range:NSMakeRange(location, length)];
		location += length;
		platform = [NSString stringWithUTF8String:_platform];
		free(_platform);
	}
    HTLog(@"platform:%@", platform);
    
    // app version
    [data getBytes:&length range:NSMakeRange(location, sizeof(unsigned long))];
    location += sizeof(unsigned long);
	NSString *appVersion = nil;
	if (length > 0) {
		char * app_version = malloc(length * sizeof(char));
		[data getBytes:app_version range:NSMakeRange(location, length)];
		location += length;
		appVersion = [NSString stringWithUTF8String:app_version];
		free(app_version);
	}
    HTLog(@"app:%@", appVersion);
    
    // environment
    [data getBytes:&length range:NSMakeRange(location, sizeof(unsigned long))];
    location += sizeof(unsigned long);
	NSString *environment = nil;
	if (length > 0) {
		char * _environment = malloc(length * sizeof(char));
		[data getBytes:_environment range:NSMakeRange(location, length)];
		location += length;
		environment = [NSString stringWithUTF8String:_environment];
		free(_environment);
	}
    HTLog(@"environment:%@", environment);
    
    if (type == HTSignalNoticeType) {
		
		// signal
        int signal;
        [data getBytes:&signal range:NSMakeRange(location, sizeof(int))];
        location += sizeof(int);
        HTLog(@"signal:%d", signal);
		
		// call stack
		NSUInteger i = location;
		length = [data length];
		const char * bytes = [data bytes];
		NSMutableArray *callStack = [NSMutableArray array];
		while (i < length) {
			if (bytes[i] == '\0') {
				NSData *line = [data subdataWithRange:NSMakeRange(location, i - location)];
				NSString *lineString = [[NSString alloc]
										initWithBytes:[line bytes]
										length:[line length]
										encoding:NSUTF8StringEncoding];
				[callStack addObject:lineString];
				[lineString release];
				if (i + 1 < length && bytes[i + 1] == '\n') { i += 2; }
				else { i++; }
				location = i;
			}
			else { i++; }
		}
		HTLog(@"call stack:%@", callStack);
		
    }
    else if (type == HTExceptionNoticeType) {
        
		// get dictionary
		[data getBytes:&length range:NSMakeRange(location, sizeof(unsigned long))];
		location += sizeof(unsigned long);
		NSData *crashInfo = [data subdataWithRange:NSMakeRange(location, length)];
		location += length;
		NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:crashInfo];
		
		// call stack
		HTLog(@"call stack:\n%@", [dictionary objectForKey:@"symbols"]);
		
		// exception name
		HTLog(@"exception name:%@", [dictionary objectForKey:@"name"]);
		
		// exception reason
		HTLog(@"exception reason:%@", [dictionary objectForKey:@"reason"]);
		
		// call stack
		HTLog(@"view controller:%@", [dictionary objectForKey:@"view controller"]);

		// environment info
		HTLog(@"environment info:\n%@", [dictionary objectForKey:@"info"]);
        
    }
    
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
		if ([ext isEqualToString:HTNotifierNoticePathExtension]) {
			NSString *crashPath = [directory stringByAppendingPathComponent:file];
			[crashes addObject:crashPath];
		}
	}
	return crashes;
}

#pragma mark - callstack functions
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
	BOOL strip = [[HTNotifier sharedNotifier] stripCallStack];
	for (NSString *line in symbols) {
		
		// create scanner
		NSScanner *scanner = [NSScanner scannerWithString:line];
		
		// line number
		NSInteger number;
		[scanner scanInteger:&number];
		
		// binary name
		NSString *binary;
		[scanner scanCharactersFromSet:nonWhiteSpace intoString:&binary];
		
		// method
        NSString *method = @"";
        if (strip) {
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
		if ([file isEqualToString:@"ht_handle_signal"]) {
			continue;
		}
		else {
			return file;
		}
	}
	return @"";
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
