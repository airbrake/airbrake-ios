//
//  HTHandler.h
//  CrashPhone
//
//  Created by Caleb Davenport on 12/15/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

// get a list of all handled signals
NSArray * HTHandledSignals();

// start signal and exception handlers
void HTStartHandler();

// stop signal and exception handlers
void HTStopHandler();

// get symbolicated call stack given return addresses
NSArray * HTCallStackSymbolsFromReturnAddresses(NSArray *);

// get folder where notices are stored
NSString * HTNoticesDirectory();

// get a list of all notices saved on disk
NSArray * HTNotices();

// get the operating system version
NSString * HTOperatingSystemVersion();

// utility method for getting a value from info.plist
id HTInfoPlistValueForKey(NSString *key);

// get the executable name
NSString * HTExecutableName();

/*
 get the application version
 
 the value returned is a combination of the CFBundleVersion
 and CFBundleShortVersionString
 */
NSString * HTApplicationVersion();

/*
 get a string that can be shown to the user that represents
 the application name
 
 a name is searched for in this order:
	- CFBundleDisplayName
	- CFBundleName
	- CFBundleIdentifier
 */
NSString * HTApplicationName();

/*
 get the current platform
 
 if the app is running on an iOS device, a common string
 like "iPhone 3G" or "iPad" is returned.
 
 if the app is running on a Mac OS device an identifier
 is returned like "MacBookPro7,1"
 */
NSString * HTPlatform();

/*
 get the path to a notice given a file name
 
 the file name should not contain a path extension
 */
NSString * HTPathForNewNoticeWithName(NSString *);

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

// library logging methods
void HTLog(NSString *fmt, ...);
NSString * HTLogStringWithFormat(NSString *fmt, ...);
NSString * HTLogStringWithArguments(NSString *fmt, va_list args);

