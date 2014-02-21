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
 
 Open a notice file at the given path and populates it with the default header
 values. Returns a file descriptor to the file. Call this in handler functions.
 
 */
int ABNotifierOpenNewNoticeFile(const char *path, int type);

// start handlers
void ABNotifierStartExceptionHandler(void);
void ABNotifierStartSignalHandler(void);

// stop handlers
void ABNotifierStopExceptionHandler(void);
void ABNotifierStopSignalHandler(void);

// get improved values from Info.plist
NSString *ABNotifierApplicationVersion(void);
NSString *ABNotifierApplicationName(void);

/*
 
 Get the current operating system version.
 
 */
NSString *ABNotifierOperatingSystemVersion(void);

/*
 
 Returns the value retrived from `sysctlbyname`. You will see a value like
 "iPhone4,1" or "MacBookPro7,1".
 
 */
NSString *ABNotifierMachineName(void);

/*
 
 Returns the common device name for iOS devices, e.g. "iPhone 4 (GSM)". Returns
 the value of `ABNotifierMachineName` for other products.
 
 */
NSString *ABNotifierPlatformName(void);

// Get the amount of resident memory in use in a formatted string.
NSString *ABNotifierResidentMemoryUsage(void);

// Get the amount of virtual memory in use in a formatted string.
NSString *ABNotifierVirtualMemoryUsage(void);

/*
 
 Parse a call stack and return an array of the following components:
 0 - matched line
 1 - frame number
 2 - binary name
 3 - description
 4 - address
 
 */
NSArray *ABNotifierParseCallStack(NSArray *callStack);

/*
 
 Returns the method name of the highest entry in the callstack that matches
 the given executable name.
 
 */
NSString *ABNotifierActionFromParsedCallStack(NSArray *callStack, NSString *executable);

#if TARGET_OS_IPHONE
/*
 
 Get the class name of the on-screen view controller. This does not indicate the
 controller where the crash occured, simply the one that has a view on screen.
 
 If the notifier delegate implements `rootViewControllerForNotice:` the
 heirarchy of the returned controller will be inspected. If not, the
 `rootViewController` of the key window will be inspected (if one exists).
 
 This method must be called on the main thread.
 
 
 */
NSString *ABNotifierCurrentViewController(void);

/*
 
 Get the name of the visible view controller given a starting view controller.
 
 This method makes assumptions about tab bar and navigation controllers and will
 traverse the view heirarchy until an unknown controller class is encountered.
 This is often the onscreen controller. This method should never need to be
 called directly from your code.
 
 This method must be called on the main thread.
 
 */
NSString *ABNotifierVisibleViewControllerFromViewController(UIViewController *controller);
#endif

/*
 
 Get a localized string for the given key from the ABNotifier bundle
 
 */
NSString* ABLocalizedString(NSString* key);

// useful defines
#if(DEBUG)
#define ABLog(fmt, args...) NSLog(@"[Airbrake] " fmt, ##args)
#else
#define ABLog(args...)
#endif