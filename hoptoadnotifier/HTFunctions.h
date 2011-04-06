//
//  HTHandler.h
//  CrashPhone
//
//  Created by Caleb Davenport on 12/15/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

// start handlers
void HTStartHandlers();
void HTStartExceptionHandler();
void HTStartSignalHandler();

// stop handlers
void HTStopHandlers();
void HTStopExceptionHandler();
void HTStopSignalHandler();

// get values from Info.plist
id HTInfoPlistValueForKey(NSString *);
//result of memory probing
typedef enum {
    HT_MEMORY_SUCCESS = 0,
    HT_MEMORY_INVALID,
}ht_memory_result_t;

//the return type for the memory analysis functions
typedef double ht_memory_t;

// get a list of all handled signals
NSArray * HTHandledSignals();

// start signal and exception handlers
void HTStartHandler();

// stop signal and exception handlers
void HTStopHandler();

// get symbolicated call stack given return addresses
NSArray * HTCallStackSymbolsFromReturnAddresses(NSArray *);

// parse callstack
NSArray * HTParseCallstack(NSArray *symbols);

// get action from callstack
NSString * HTActionFromCallstack(NSArray *callStack);

// get folder where notices are stored
NSString * HTNoticesDirectory();

// get a list of all notices saved on disk
NSArray * HTNotices();

// get the operating system version
NSString * HTOperatingSystemVersion();

// utility method for getting a value from info.plist
id HTInfoPlistValueForKey(NSString *key);
NSString * HTExecutableName();
NSString * HTApplicationVersion();
NSString * HTApplicationName();

// get platform values
NSString * HTOperatingSystemVersion();
NSString * HTPlatform();

// deal with notice information
void HTInitNoticeInfo();
void HTReleaseNoticeInfo();

// deal with notice information on disk
NSString * HTNoticesDirectory();
NSArray * HTNotices();

// callstack utilities
NSArray * HTCallStackSymbolsFromReturnAddresses(NSArray *);
NSArray * HTParseCallstack(NSArray *);
NSString * HTActionFromCallstack(NSArray *);

/*
 returns a string with all of the hoptoad variables
 replaced by their appropriate values
 */
NSString * HTStringByReplacingHoptoadVariablesInString(NSString *);

#if TARGET_OS_IPHONE

/* 
 return the amount of memory used in megabytes.
 
 ios only for now until i can test in another environment. also
 should not be used within the signal handler until more testing is done.

 */

ht_memory_result_t HTMemoryUsedInMB(ht_memory_t *mb);


/* 
 populate the current environment with a snapshot of the current 
 memory usage
 */

void HTSetEnvironmentMemoryInfo();

/*
 return the class name of the on screen view controller.
 
 this does not indicate the controller where the crash
 occured, simply the one that has a view on screen
 
 if the HTNotifier delegate implements
	 - rootViewControllerForNotice
 the heirarchy of the returned controller will be inspected
 
 if not, the rootViewController of the key window will be
 inspected (if it exists)
 */
NSString * HTCurrentViewController();

/*
 return the name of the visible view controller given a
 starting view controller.
 
 this method makes assumptions about tab bar and navigation
 controllers and will traverse the view heirarchy until an
 unknown controller class is encountered. this is often the
 onscreen controller
 
 this method is recursive and is called by
	+ currentViewController
 */
NSString * HTVisibleViewControllerWithViewController(UIViewController *);

#endif

// useful defines
#define HTLog(fmt, args...) NSLog(@"[Hoptoad] " fmt, ##args)
#define HTLocalizedString(key) NSLocalizedStringFromTable((key), @"HTNotifier", @"")
