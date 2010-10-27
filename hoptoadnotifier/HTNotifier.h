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

// string variables
extern NSString * const HTNotifierBundleName;
extern NSString * const HTNotifierBuildDate;
extern NSString * const HTNotifierBundleVersion;

/*
 provides callback and customizations for runtime options of
 the notifier. all of these methods are called on the main
 thread
 */
@protocol HTNotifierDelegate <NSObject>
@optional

/*
 will display and did dismiss alert are always called as a
 pair in this order
 
 treat these just like -applicationWillResignActive: and
 -applicationDidBecomeActive:
 (pause animations, etc)
 */
- (void)notifierWillDisplayAlert;
- (void)notifierDidDismissAlert;

/*
 customize the text in the crash alert. include ${BUNDLE} in
 the returned strings to have the bundle display name
 substituted in
 */
- (NSString *)titleForNoticeAlert;
- (NSString *)bodyForNoticeAlert;

/*
 lets the app delegate know that a crash has been handled.
 by the time this method is called, the offending crash has
 been logged and the notifier is no longer watching for
 crashes
 
 this can be used to sync user defaults, save state, etc.
 */
- (void)notifierDidHandleCrash;

/*
 return the root view controller for the app
 */
- (UIViewController *)rootViewControllerForNotice;

@end

/*
 HTNotifier is the primary class of the notifer library
 
 create an instance through
 +sharedNotifierWithAPIKey:environmentName:
 */
@interface HTNotifier : NSObject <UIAlertViewDelegate> {
@private
	NSString *apiKey;
	NSString *environmentName;
	NSDictionary *environmentInfo;
	SCNetworkReachabilityRef reachability;
	id<HTNotifierDelegate> delegate;
	BOOL useSSL;
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
 creates and returns the shared notifier object.
 
 the values for key and environment name must not be nil and
 must have a length greater than 0.
 
 pass HTNotifierBuildDate or HTNotifierBundleVersion into
 the environment namet o have the build date or build
 version inserted respectively
 */
+ (HTNotifier *)sharedNotifierWithAPIKey:(NSString *)key
			   environmentNameWithFormat:(NSString *)fmt, ...;

/*
 returns the shared notifier object.
 
 if this is called before
 +sharedNotifierWithAPIKey:environmentName:
 nil will be returned.
 */
+ (HTNotifier *)sharedNotifier;

/*
 writes a test notice to disk if one does not exist
 already
 */
- (void)writeTestNotice;

@end
