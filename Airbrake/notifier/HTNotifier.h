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
#import <SystemConfiguration/SystemConfiguration.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
    #ifndef __IPHONE_4_0
        #error This version of the Airbrake notifier requires iOS 4.0 or later
    #endif
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
    #ifndef __MAC_10_6
        #error This version of the Airbrake notifier requires Mac OS 10.6 or later
    #endif
#else
    #error [Airbrake] unsupported platform
#endif

#import "HTNotifierDelegate.h"

// notifier version
extern NSString *HTNotifierVersion;

/*
 
 These standard environment names provide default values for you to pick from.
 The automatic environment will set development or release depending on the
 presence of the DEBUG flag.
 
 */
extern NSString *HTNotifierDevelopmentEnvironment;
extern NSString *HTNotifierAdHocEnvironment;
extern NSString *HTNotifierAppStoreEnvironment;
extern NSString *HTNotifierReleaseEnvironment;
extern NSString *HTNotifierAutomaticEnvironment;

/*
 
 These notifications are designed to mirror the methods seen in 
 HTNotifierDelegate. They allow you to be aware of key events in the notifier
 outside of the single delegate. They will be posted on the main thread.
 
 */
extern NSString *ABNotifierWillDisplayAlertNotification;
extern NSString *ABNotifierDidDismissAlertNotification;
extern NSString *ABNotifierWillPostNoticesNotification;
extern NSString *ABNotifierDidPostNoticesNotification;

/*
 
 HTNotifier is the primary class of the notifer library
 
 start the notifier by calling `startNotifierWithAPIKey:environmentName:`
 
 access the shared instance by calling `sharedNotifier`
 
 */
@interface HTNotifier : NSObject
#if TARGET_OS_IPHONE
<UIAlertViewDelegate>
#endif
{}

/*
 
 this method is the entry point for the library. any code executed after this
 method call is monitored for crashes and signals
 
 the values for key and environment name must not be nil and must have a length
 greater than 0
 
 include any of the above constant strings in the enviromnent name to have the
 value replaced by the library
 
 */
+ (void)startNotifierWithAPIKey:(NSString *)key
                environmentName:(NSString *)name
                         useSSL:(BOOL)useSSL
                       delegate:(id<HTNotifierDelegate>)delegate;

/*
 
 Methods to expose some of the inner variables used by the notifier.
 
 */
+ (id<HTNotifierDelegate>)delegate;
+ (NSString *)APIKey;

/*
 
 Log an exception.
 
 */
+ (void)logException:(NSException *)exception;

/*
 
 Write a test notice to disk. It will be reported just like an actual crash.
 
 */
+ (void)writeTestNotice;

/*
 
 This family of methods modifies the custom payload sent with each notice that
 appears in the "Environment" tab in the Airbrake web interface. These methods
 are proxies for an instance of NSMutableDictionary and are therefore subject
 to the same conditions. To ensure the best presentation of your data, use only
 string key/value pairs
 
 */
+ (void)setEnvironmentValue:(NSString *)value forKey:(NSString *)key;
+ (void)addEnvironmentEntriesFromDictionary:(NSDictionary *)dictionary;
+ (NSString *)environmentValueForKey:(NSString *)key;
+ (void)removeEnvironmentValueForKey:(NSString *)key;
+ (void)removeEnvironmentValuesForKeys:(NSArray *)keys;

@end
