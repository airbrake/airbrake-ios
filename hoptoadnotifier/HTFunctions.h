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
NSString * HTExecutableName();
NSString * HTApplicationVersion();
NSString * HTApplicationName();

// get platform values
NSString * HTOperatingSystemVersion();
NSString * HTMachine();
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
