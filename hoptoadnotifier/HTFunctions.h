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

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Foundation/Foundation.h>
#endif

/*
 
 opens a notice file given a path and populates it with the default header
 values. returns a file descriptor to the file. call this in handler functions.
 
 */
int ABNotifierOpenNewNoticeFile(const char *path, int type);

// start handlers
void ABNotifierStartHandlers(void);

// stop handlers
void ABNotifierStopHandlers(void);
void ABNotifierStopExceptionHandler(void);
void ABNotifierStopSignalHandler(void);

// get values from Info.plist
NSString *ABNotifierApplicationVersion(void);
NSString *ABNotifierApplicationName(void);

// get platform values
NSString *ABNotifierOperatingSystemVersion(void);
NSString *ABNotifierMachineName(void);
NSString *ABNotifierPlatformName(void);

/*
 
 parse a call stack and return an array of the following components:
 0 - matched line
 1 - frame number
 2 - binary name
 3 - description
 4 - address
 
 */
NSArray *ABNotifierParseCallStack(NSArray *callStack);

/*
 
 returns the method name of the highest entry in the callstack that matches
 the given executable name
 
 */
NSString *ABNotifierActionFromParsedCallStack(NSArray *callStack, NSString *executable);

/*
 
 returns a string with all of the airbrake variables replaced by their
 appropriate values
 
 */
NSString *ABNotifierStringByReplacingAirbrakeConstantsInString(NSString *string);

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
NSString *ABNotifierCurrentViewController(void);

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
NSString *ABNotifierVisibleViewControllerFromViewController(UIViewController *controller);
#endif

// useful defines
#define HTLog(fmt, args...) NSLog(@"[Hoptoad] " fmt, ##args)
#define HTLocalizedString(key) NSLocalizedStringFromTable((key), @"HTNotifier", @"")
