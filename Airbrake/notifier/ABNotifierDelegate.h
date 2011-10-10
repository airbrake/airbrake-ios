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

/*
 
 Classes that conform to this protocol can provide customization of the notifier
 at runtime. All of these methods are called on the main thread and are
 optional.
 
 */
@protocol ABNotifierDelegate <NSObject>
@optional

/*
 
 These methods allow your application to respond to alerts presented to the user
 by the notifier. They are always called as a pair in the order shown below.
 
 Treat these like `applicationWillResignActive:` and
 `applicationDidBecomeActive:`
 
 */
- (void)notifierWillDisplayAlert;
- (void)notifierDidDismissAlert;

/*
 
 Customize the text seen by the user in
 the crash report alert.
 
 */
- (NSString *)titleForNoticeAlert;
- (NSString *)bodyForNoticeAlert;


/*
 
 Perform actions before and after notices are posted to the server.
 
 */
- (void)notifierWillPostNotices;
- (void)notifierDidPostNotices;

/*
 
 Informs the delegate that an exception was successfully logged.
 
 */
- (void)notifierDidLogException:(NSException *)exception;

#if TARGET_OS_IPHONE
/*
 
 Asks the delegate to return the root view controller for the app. This is used
 to walk the view hierarchy and determine what view is on screen at the time of
 a crash.
 
 If you used the iOS 4 method `setRootViewController:` in UIWindow you do not
 need to implement this method.
 
 */
- (UIViewController *)rootViewControllerForNotice;
#endif

@end
