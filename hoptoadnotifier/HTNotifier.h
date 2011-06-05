//
//  HTNotifier.h
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 10/2/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#else
#error [Hoptoad] unsupported platform
#endif

#import <SystemConfiguration/SystemConfiguration.h>

#import "HTNotifierDelegate.h"

// notifier version
extern NSString *HTNotifierVersion;

// internal
extern NSString *HTNotifierAlwaysSendKey;

/*
 use these variables in your alert title, alert body, and
 environment name to have their values replaced at runtime
 */
extern NSString *HTNotifierBundleName;      // app name
extern NSString *HTNotifierBundleVersion;   // bundle version

/*
 use these standard environment names to have default
 values provided to hoptoad
 */
extern NSString *HTNotifierDevelopmentEnvironment;
extern NSString *HTNotifierAdHocEnvironment;
extern NSString *HTNotifierAppStoreEnvironment;
extern NSString *HTNotifierReleaseEnvironment;

/*
 HTNotifier is the primary class of the notifer library
 
 start the notifier by calling
 startNotifierWithAPIKey:environmentName:
 
 access the shared instance by calling sharedNotifier
 */
#if TARGET_OS_IPHONE
@interface HTNotifier : NSObject <UIAlertViewDelegate> {
#else
@interface HTNotifier : NSObject {
#endif
@private
    NSMutableDictionary *_environmentInfo;
    NSString *_environmentName;
    NSString *_apiKey;
	NSObject<HTNotifierDelegate> *_delegate;
    BOOL _useSSL;
	SCNetworkReachabilityRef reachability;
}

// properties
@property (nonatomic, readonly) NSDictionary *environmentInfo;
@property (nonatomic, readonly) NSString *apiKey;
@property (nonatomic, readonly) NSString *environmentName;
@property (nonatomic, assign) NSObject<HTNotifierDelegate> *delegate;

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
 
 if this is called before `startNotifierWithAPIKey:environmentName:`
 nil will be returned.
 */
+ (HTNotifier *)sharedNotifier;

/*
 writes a test notice if one does not exist already. it
 will be reported just as an actual crash.
 */
- (void)writeTestNotice;

/*
 set environment info key/value pair. passing nil as the
 value will remove the value for the given key.
 */
- (void)setEnvironmentValue:(NSString *)valueOrNil forKey:(NSString *)key;

/*
 get environment info value for a given key.
 */
- (NSString *)environmentValueForKey:(NSString *)key;

/*
 scan for notices and take action if hoptoad is reachable.
 if the user has chosen to always send notices they will
 be posted imediately, otherwise the user will be asked
 for their preference.
 */
- (BOOL)postNotices;

@end
