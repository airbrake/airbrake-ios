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

// library logging methods
void HTLog(NSString *fmt, ...);
NSString * HTLogStringWithFormat(NSString *fmt, ...);
NSString * HTLogStringWithArguments(NSString *fmt, va_list args);

