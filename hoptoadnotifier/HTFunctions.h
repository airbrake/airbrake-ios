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

// start handlers
void HTStartHandlers(void);
void HTStartExceptionHandler(void);
void HTStartSignalHandler(void);

// stop handlers
void HTStopHandlers(void);
void HTStopExceptionHandler(void);
void HTStopSignalHandler(void);

// get values from Info.plist
id HTInfoPlistValueForKey(NSString *);
NSString *HTExecutableName(void);
NSString *HTApplicationVersion(void);
NSString *HTBundleVersion(void);
NSString *HTApplicationName(void);

// get platform values
NSString *HTOperatingSystemVersion(void);
NSString *HTMachine(void);
NSString *HTPlatform(void);

// deal with notice information
void HTInitNoticeInfo(void);
void HTReleaseNoticeInfo(void);

// deal with notice information on disk
NSString * HTNoticesDirectory(void);
NSArray * HTNotices(void);

// callstack utilities
NSArray *HTCallStackSymbolsFromReturnAddresses(NSArray *);
NSArray *HTParseCallstack(NSArray *);
NSString *HTActionFromParsedCallstack(NSArray *);

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
NSString * HTCurrentViewController(void);

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
