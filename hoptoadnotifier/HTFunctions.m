//
//  HTHandler.m
//  CrashPhone
//
//  Created by Caleb Davenport on 12/15/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import <execinfo.h>

#import "HTNotifier.h"

static void HTHandleSignal(int signal) {
	HTStopHandler();
	NSLog(@"%s", strsignal(signal));
	NSLog(@"%@", [NSThread callStackReturnAddresses]);
	id<HTNotifierDelegate> delegate = [[HTNotifier sharedNotifier] delegate];
	if ([delegate respondsToSelector:@selector(notifierDidHandleSignal:)]) {
		[delegate notifierDidHandleSignal:signal];
	}
	raise(signal);
}

static void HTHandleException(NSException *e) {
	HTStopHandler();
	NSString *noticeName = [NSString stringWithFormat:@"%d", time(NULL)];
	NSString *noticePath = [HTUtilities noticePathWithName:noticeName];
	HTNotice *notice = [HTNotice noticeWithException:e];
	[notice writeToFile:noticePath];
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
	NSSetUncaughtExceptionHandler(HTHandleException);
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
	path = [path stringByAppendingPathComponent:[self bundleDisplayName]];
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

void HTLog(NSString *frmt, ...) {
	va_list list;
	va_start(list, frmt);
	NSLog(@"%@", HTLogStringWithArguments(frmt, list));
	va_end(list);
}

NSString *HTLogStringWithFormat(NSString *fmt, ...) {
	va_list list;
	va_start(list, fmt);
	NSString *toReturn = HTLogStringWithArguments(fmt, list);
	va_end(list);
	return toReturn;
}

NSString *HTLogStringWithArguments(NSString *fmt, va_list args) {
	NSString *format = [[NSString alloc] initWithFormat:fmt arguments:args];
	NSString *toReturn = [@"[Hoptoad] " stringByAppendingString:format];
	[format release];
	return toReturn;
}
