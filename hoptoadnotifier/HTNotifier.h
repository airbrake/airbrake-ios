//
//  HTNotifier.h
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 10/2/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "HTNotifierDelegate.h"
#import "HTFunctions.h"
#import "HTNotice.h"

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

/*
 
 use these standard environment names to have default
 values provided to hoptoad
 
 */
extern NSString * const HTNotifierDevelopmentEnvironment;
extern NSString * const HTNotifierAdHocEnvironment;
extern NSString * const HTNotifierAppStoreEnvironment;
extern NSString * const HTNotifierReleaseEnvironment;

/*
 
 HTNotifier is the primary class of the notifer library
 
 start the notifier by calling
	startNotifierWithAPIKey:environmentName:
 
 access the shared instance by calling sharedNotifier
 
 */
@interface HTNotifier : NSObject {
@private
	NSString *apiKey;
	NSString *environmentName;
	NSMutableDictionary *environmentInfo;
	SCNetworkReachabilityRef reachability;
	id<HTNotifierDelegate> delegate;
	BOOL useSSL;
}

@property (nonatomic, readonly) NSString *apiKey;
@property (nonatomic, readonly) NSString *environmentName;
@property (nonatomic, assign) id<HTNotifierDelegate> delegate;
/*
 
 set string key-value pairs on this item to have additional
 context for your crash notices. by default this is a blank
 mutable dictionary
 
 NOTE: do not use this to transmit UDID's, location, or any
 other private user information without permission
 
 */
@property (nonatomic, retain) NSMutableDictionary *environmentInfo;
/*
 
 control whether notices are posted using SSL. your account
 must support this feature
 
 default:NO
 
 */
@property (nonatomic, assign) BOOL useSSL;

/*
 
 this method is the entry point for the library. any code
 executed after this method call is monitored for crashes
 and signals
 
 the values for key and environment name must not be nil
 and must have a length greater than 0
 
 include any of the above constant strings in the
 enviromnent name to have the value replaced by the library
 
 */
+ (void)startNotifierWithAPIKey:(NSString *)key environmentName:(NSString *)name;

/*
 
 access the shared notifier object.
 
 if this is called before
	startNotifierWithAPIKey:environmentName:
 nil will be returned.
 
 */
+ (HTNotifier *)sharedNotifier;

/*
 
 writes a test notice to disk if one does not exist already
 
 */
- (void)writeTestNotice;

@end

// internal
extern NSString * const HTNotifierDirectoryName;
extern NSString * const HTNotifierPathExtension;
extern NSString * const HTNotifierAlwaysSendKey;
#define HTLocalizedString(key) \
NSLocalizedStringFromTable((key), @"HTNotifier", @"")
