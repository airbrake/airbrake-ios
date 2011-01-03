//
//  HTNotifier.h
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 12/15/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

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
 
 This lets the app delegate know that an event causing a
 crash has been handled. By the time this method is called,
 the offending crash has been logged and the notifier is no
 longer watching for crashes. Use this to sync user
 defaults, save state, etc.
 
 */
- (void)notifierDidHandleException:(NSException *)exc;
- (void)notifierDidHandleSignal:(NSInteger)signal;

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
