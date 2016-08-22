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
    #ifndef __IPHONE_6_0
        #error This version of the Airbrake notifier requires iOS 6.0 or later
    #endif
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
    #ifndef __MAC_10_7
        #error This version of the Airbrake notifier requires Mac OS 10.6 or later
    #endif
#else
    #error [Airbrake] unsupported platform
#endif

#import "ABNotifierDelegate.h"

// notifier version
extern NSString * const ABNotifierName;
extern NSString * const ABNotifierVersion;

/*
 
 These standard environment names provide default values for you to pick from.
 The automatic environment will set development or release depending on the
 presence of the DEBUG flag.
 
 */
extern NSString * const ABNotifierDevelopmentEnvironment;
extern NSString * const ABNotifierAdHocEnvironment;
extern NSString * const ABNotifierAppStoreEnvironment;
extern NSString * const ABNotifierReleaseEnvironment;
extern NSString * const ABNotifierAutomaticEnvironment;

/*
 
 These notifications are designed to mirror the methods seen in 
 HTNotifierDelegate. They allow you to be aware of key events in the notifier
 outside of the single delegate. They will be posted on the main thread right
 after the associated delegate method is called.
 
 */
extern NSString * const ABNotifierWillDisplayAlertNotification;
extern NSString * const ABNotifierDidDismissAlertNotification;
extern NSString * const ABNotifierWillPostNoticesNotification;
extern NSString * const ABNotifierDidPostNoticesNotification;


/*
 
 HTNotifier is the primary class of the notifer library. Start the notifier by
 calling `startNotifierWithAPIKey:environmentName:`.
 
 */
@interface ABNotifier : NSObject

/*
 
 This is the entry point for the library. Any code executed after this
 method call is monitored for exceptions and signals. There parameters seen
 here are as follows:
 
 API Key: your Airbrake project API key
 Product ID: each app should have its own product ID. You can find your project ID from http://help.airbrake.io/kb/api-2/notifier-api-v3.
 Environment Name: the name of the environment to collect notices in
 SSL: set this to enable secure reporting if your Airbrake account supports it
 Delegate: the object that wishes to receive events from the notifier
 Exception Handler: choose whether or not to install the exception handler
 Signal Handler: choose whether or not to install the signal handler
 Display Prompt: choose whether or not a prompt will be shown to the user
    before notices are posted
 
 */

+ (void)startNotifierWithAPIKey:(NSString *)key
                      projectID:(NSString *)projectId
                environmentName:(NSString *)name
                         useSSL:(BOOL)useSSL;
+ (void)startNotifierWithAPIKey:(NSString *)key
                      projectID:(NSString *)projectId
                environmentName:(NSString *)name
                         useSSL:(BOOL)useSSL
                       delegate:(id<ABNotifierDelegate>)delegate;
+ (void)startNotifierWithAPIKey:(NSString *)key
                      projectID:(NSString *)projectId
                environmentName:(NSString *)name
                       userName:(NSString *)username
                         useSSL:(BOOL)useSSL
                       delegate:(id<ABNotifierDelegate>)delegate;
+ (void)startNotifierWithAPIKey:(NSString *)key
                      projectID:(NSString *)projectId
                environmentName:(NSString *)name
                         useSSL:(BOOL)useSSL
                       delegate:(id<ABNotifierDelegate>)delegate
        installExceptionHandler:(BOOL)exception
           installSignalHandler:(BOOL)signal;
+ (void)startNotifierWithAPIKey:(NSString *)key
                      projectID:(NSString *)projectId
                environmentName:(NSString *)name
                       userName:(NSString *)username
                         useSSL:(BOOL)useSSL
                       delegate:(id<ABNotifierDelegate>)delegate
        installExceptionHandler:(BOOL)exception
           installSignalHandler:(BOOL)signal
              displayUserPrompt:(BOOL)display;

+ (void)startNotifierWithAPIKey:(NSString *)key
                    projectID:(NSString *)projectId
                       hostName:(NSString *)hostName
                environmentName:(NSString *)name
                         useSSL:(BOOL)useSSL
                       delegate:(id<ABNotifierDelegate>)delegate;
+ (void)startNotifierWithAPIKey:(NSString *)key
                      projectID:(NSString *)projectId
                       hostName:(NSString *)hostName
                environmentName:(NSString *)name
                       userName:(NSString *)username
                         useSSL:(BOOL)useSSL
                       delegate:(id<ABNotifierDelegate>)delegate
        installExceptionHandler:(BOOL)exception
           installSignalHandler:(BOOL)signal;
+ (void)startNotifierWithAPIKey:(NSString *)key
                      projectID:(NSString *)projectId
                       hostName:(NSString *)hostName
                environmentName:(NSString *)name
                       userName:(NSString *)username
                         useSSL:(BOOL)useSSL
                       delegate:(id<ABNotifierDelegate>)delegate
        installExceptionHandler:(BOOL)exception
           installSignalHandler:(BOOL)signal
              displayUserPrompt:(BOOL)display;

/*
 
 Methods to expose some variables used by the notifier.
 
 */
+ (id<ABNotifierDelegate>)delegate;
+ (NSString *)APIKey;
+ (NSString *)projectID;
/*
 
 Log an exception and optionally save parameters with this exception. These
 parameters will be shown along with the environment key/value pairs on the
 "Environment" tab on Airbrake. Values passed in here will be used for this
 exception only and will override values stored in the environment info.
 
 */
+ (void)logException:(NSException *)exception parameters:(NSDictionary *)parameters;
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
