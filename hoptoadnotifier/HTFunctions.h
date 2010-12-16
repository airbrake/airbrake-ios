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

/*
 get the application version
 
 this is returned as a combination of the CFBundleVersion
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
NSString * HTBundleDisplayName();

/*
 get the current platform
 
 if the app is running on an iOS device, a common string
 like "iPhone 3G" or "iPad" is returned.
 
 if the app is running on a Mac OS device an identifier
 is returned like "MacBookPro7,1"
 */
NSString * HTPlatform();

// library logging methods
void HTLog(NSString *fmt, ...);
NSString * HTLogStringWithFormat(NSString *fmt, ...);
NSString * HTLogStringWithArguments(NSString *fmt, va_list args);

