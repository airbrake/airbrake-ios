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
 
 Classes that conform to this protocol can provide
 customization of the notifier at runtime. All of these
 methods are called on the main thread and are optional.
 
 */
@protocol HTNotifierDelegate <NSObject>
@optional

/*
 
 These methods allow your application to respond to alerts
 posted by the notifier to the user. They are always called
 as a pair in the order shown below.
 
 Treat these like
	applicationWillResignActive:
 and
	applicationDidBecomeActive:
 
 */
- (void)notifierWillDisplayAlert;
- (void)notifierDidDismissAlert;

/*
 
 These methods allow your application to customize the text
 in the crash report alert. Include any of the constant
 strings listed in HTNotifier.h to have the value replaced
 automatically.
 
 */
- (NSString *)titleForNoticeAlert;
- (NSString *)bodyForNoticeAlert;


/*
 
 These methods allow your application to perform actions
 before and after notices are posted to the server.
 
 */
- (void)notifierWillPostNotices;
- (void)notifierDidPostNotices;

/*
 
 This lets the notifier delegate know that an exception
 was logged to the file system.
 
 */
- (void)notifierDidLogException:(NSException *)exception;

#if TARGET_OS_IPHONE
/*
 
 This method asks the delegate to return the root view
 controller for the app. This is used to walk the view
 hierarchy to determine what view is on screen at the time
 of a crash.
 
 If you used the iOS 4 method from UIWindow
	setRootViewController:
 you do not need to implement this method
 
 */
- (UIViewController *)rootViewControllerForNotice;
#endif

@end
