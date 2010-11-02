//
//  HTNotifier.h
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 10/2/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <UIKit/UIKit.h>

// notifier version
extern NSString * const HTNotifierVersion;

/*
 use these variables in your alert title, alert body, and
 environment name to have their values replaced at runtime
 */
// bundle name of the app
extern NSString * const HTNotifierBundleName;
// bundle version of the app
extern NSString * const HTNotifierBundleVersion;
// app build date
extern NSString * const HTNotifierBuildDate;
// app build date and time
extern NSString * const HTNotifierBuildTime;

/*
 use these standard environment names to have default values
 provided to hoptoad
 */
extern NSString * const HTNotifierDevelopmentEnvironment;
extern NSString * const HTNotifierAdHocEnvironment;
extern NSString * const HTNotifierAppStoreEnvironment;

/*
 provides callback and customizations for runtime options of
 the notifier. all of these methods are called on the main
 thread and are optional
 */
@protocol HTNotifierDelegate <NSObject>
@optional

/*
 will display and did dismiss alert are always called as a
 pair in this order
 
 treat these just like applicationWillResignActive: and
 applicationDidBecomeActive:
 (pause animations, etc)
 */
- (void)notifierWillDisplayAlert;
- (void)notifierDidDismissAlert;

/*
 customize the text in the crash alert. include any of the
 above constant strings in these strings to have the value
 replaced by the library
 */
- (NSString *)titleForNoticeAlert;
- (NSString *)bodyForNoticeAlert;

/*
 lets the app delegate know that an exception has been
 handled. by the time this method is called, the offending
 crash has been logged and the notifier is no longer
 watching for crashes
 
 this can be used to sync user defaults, save state, etc.
 */
- (void)notifierDidHandleException:(NSException *)exc;

/*
 return the root view controller for the app. this is used
 to determine the onscreen view at the time of a crash.
 */
- (UIViewController *)rootViewControllerForNotice;

@end

/*
 HTNotifier is the primary class of the notifer library
 
 start the notifier by calling
 startNotifierWithAPIKey:environmentName:
 
 access the shared instance by calling sharedNotifier
 */
@interface HTNotifier : NSObject <UIAlertViewDelegate> {
@private
	NSString *apiKey;
	NSString *environmentName;
	NSDictionary *environmentInfo;
	SCNetworkReachabilityRef reachability;
	id<HTNotifierDelegate> delegate;
	BOOL useSSL;
	BOOL logCrashesInSimulator;
}

@property (nonatomic, readonly) NSString *apiKey;
@property (nonatomic, readonly) NSString *environmentName;
@property (nonatomic, assign) id<HTNotifierDelegate> delegate;
/*
 the environment info property allows you to set a
 dictionary of string key-value pairs with additional
 context for a crash notice.
 
 e.g. user account email address.
 
 NOTE: do not use this to transmit UDID's, location, or any
 other private user information without permission
 */
@property (nonatomic, retain) NSDictionary *environmentInfo;
/*
 control whether notices are posted using SSL. your account
 must support this feature
 
 default:NO
 */
@property (nonatomic, assign) BOOL useSSL;
/*
 control whether crashes are logged in the simulator
 
 default:YES
 */
@property (nonatomic, assign) BOOL logCrashesInSimulator;

/*
 this method is the entry point for the library. any code
 executed after this method call is monitored for crashes
 and signals
 
 the values for key and environment name must not be nil and
 must have a length greater than 0
 
 include any of the above constant strings in these strings
 to have the value replaced by the library
 */
+ (void)startNotifierWithAPIKey:(NSString *)key environmentName:(NSString *)name;

/*
 returns the shared notifier object.
 
 if this is called before
 startNotifierWithAPIKey:environmentName:, nil
 will be returned.
 */
+ (HTNotifier *)sharedNotifier;

/*
 writes a test notice to disk if one does not exist already
 */
- (void)writeTestNotice;

@end
