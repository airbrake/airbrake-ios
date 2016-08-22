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

#import "ABNotice.h"
#import "ABNotifierFunctions.h"

#import "ABNotifier.h"
#import "GCAlertView.h"
#import "ABCrashReport.h"
// internal
static SCNetworkReachabilityRef __reachability = nil;
static id<ABNotifierDelegate> __delegate = nil;
static NSMutableDictionary *__userData;
static NSString * __APIKey = nil;
static NSString * __ABProjectID = nil;
//__hostName will be used to format the URL to post the crash report.
//By default the hostName is airbrake.io and url is https://api.airbrake.io/api/v3/projects/%d/...
static NSString * __hostName = nil;
static BOOL __useSSL = NO;
static BOOL __displayPrompt = YES;
static NSString *__userName = @"Anonymous";
static NSString *__envName = nil;
static NSString *__noticePath = nil;
// constant strings
static NSString * const ABNotifierHostName                  = @"airbrake.io";
static NSString * const ABNotifierAlwaysSendKey             = @"AlwaysSendCrashReports";
NSString * const ABNotifierWillDisplayAlertNotification     = @"ABNotifierWillDisplayAlert";
NSString * const ABNotifierDidDismissAlertNotification      = @"ABNotifierDidDismissAlert";
NSString * const ABNotifierWillPostNoticesNotification      = @"ABNotifierWillPostNotices";
NSString * const ABNotifierDidPostNoticesNotification       = @"ABNotifierDidPostNotices";
NSString * const ABNotifierVersion                          = @"4.2.6";
NSString * const ABNotifierName                             = @"Airbrake-iOS";
NSString * const ABNotifierDevelopmentEnvironment           = @"Development";
NSString * const ABNotifierAdHocEnvironment                 = @"Ad Hoc";
NSString * const ABNotifierAppStoreEnvironment              = @"App Store";
NSString * const ABNotifierReleaseEnvironment               = @"Release";
#if defined (DEBUG) || defined (DEVELOPMENT)
NSString * const ABNotifierAutomaticEnvironment             = @"Development";
#elif defined (TEST) || defined (TESTING)
NSString * const ABNotifierAutomaticEnvironment             = @"Test";
#else
NSString * const ABNotifierAutomaticEnvironment             = @"Production";
#endif

// reachability callback
void ABNotifierReachabilityDidChange(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);

@interface ABNotifier ()

// get the path where notices are stored
+ (NSString *)pathForNoticesDirectory;

// get the path for a new notice given the file name
+ (NSString *)pathForNewNoticeWithName:(NSString *)name;

// get the paths for all valid notices
+ (NSArray *)pathsForAllNotices;

// post all provided notices to airbrake
+ (void)postNoticesWithPaths:(NSArray *)paths;

// post the given notice to server
+ (void)postNoticeWithContentsOfFile:(NSString *)path;

// caches user data to store that can be read at signal time
+ (void)cacheUserDataDictionary;

// pop a notice alert and perform necessary actions
+ (void)showNoticeAlertForNoticesWithPaths:(NSArray *)paths;

// determine if we are reachable with given flags
+ (BOOL)isReachable:(SCNetworkReachabilityFlags)flags;

@end

@implementation ABNotifier

#pragma mark - initialize the notifier
+ (void)startNotifierWithAPIKey:(NSString *)key projectID:(NSString *)projectId environmentName:(NSString *)name useSSL:(BOOL)useSSL {
    [self startNotifierWithAPIKey:key projectID:projectId environmentName:name useSSL:useSSL delegate:nil];
}

+ (void)startNotifierWithAPIKey:(NSString *)key projectID:(NSString *)projectId environmentName:(NSString *)name useSSL:(BOOL)useSSL delegate:(id<ABNotifierDelegate>)delegate {
    [self startNotifierWithAPIKey:key projectID:projectId environmentName:name userName:__userName useSSL:useSSL delegate:delegate installExceptionHandler:YES installSignalHandler:YES displayUserPrompt:YES];
}
+ (void)startNotifierWithAPIKey:(NSString *)key projectID:(NSString *)projectId environmentName:(NSString *)name useSSL:(BOOL)useSSL delegate:(id<ABNotifierDelegate>)delegate installExceptionHandler:(BOOL)exception installSignalHandler:(BOOL)signal {
    [self startNotifierWithAPIKey:key projectID:projectId environmentName:name userName:__userName useSSL:useSSL delegate:delegate installExceptionHandler:exception installSignalHandler:signal displayUserPrompt:YES];
}

+ (void)startNotifierWithAPIKey:(NSString *)key projectID:(NSString *)projectId environmentName:(NSString *)name userName:(NSString *)username useSSL:(BOOL)useSSL delegate:(id<ABNotifierDelegate>)delegate {
    [self startNotifierWithAPIKey:key projectID:projectId environmentName:name userName:username useSSL:useSSL delegate:delegate
          installExceptionHandler:YES
             installSignalHandler:YES
                displayUserPrompt:YES];
}

+ (void)startNotifierWithAPIKey:(NSString *)key projectID:(NSString *)projectId environmentName:(NSString *)name userName:(NSString *)username useSSL:(BOOL)useSSL delegate:(id<ABNotifierDelegate>)delegate installExceptionHandler:(BOOL)exception installSignalHandler:(BOOL)signal displayUserPrompt:(BOOL)display {
    [self startNotifierWithAPIKey:key projectID:projectId hostName:nil environmentName:name userName:username useSSL:useSSL delegate:delegate
          installExceptionHandler:exception
             installSignalHandler:signal
                displayUserPrompt:display];
}

+ (void)startNotifierWithAPIKey:(NSString *)key projectID:(NSString *)projectId hostName:(NSString *)hostName environmentName:(NSString *)name useSSL:(BOOL)useSSL delegate:(id<ABNotifierDelegate>)delegate {
    [self startNotifierWithAPIKey:key projectID:projectId hostName:hostName environmentName:name userName:__userName useSSL:useSSL delegate:delegate
          installExceptionHandler:YES
             installSignalHandler:YES
                displayUserPrompt:YES];
}

+ (void)startNotifierWithAPIKey:(NSString *)key
                      projectID:(NSString *)projectId
                       hostName:(NSString *)hostName
                environmentName:(NSString *)name
                       userName:(NSString *)username
                         useSSL:(BOOL)useSSL
                       delegate:(id<ABNotifierDelegate>)delegate
        installExceptionHandler:(BOOL)exception
           installSignalHandler:(BOOL)signal {
    [self startNotifierWithAPIKey:key projectID:projectId hostName:hostName environmentName:name userName:username useSSL:useSSL delegate:delegate
          installExceptionHandler:exception
             installSignalHandler:signal
                displayUserPrompt:YES];
}

+ (void)startNotifierWithAPIKey:(NSString *)key
                      projectID:(NSString *)projectId
                       hostName:(NSString *)hostName
                environmentName:(NSString *)name
                       userName:(NSString *)username
                         useSSL:(BOOL)useSSL
                       delegate:(id<ABNotifierDelegate>)delegate
        installExceptionHandler:(BOOL)exception
           installSignalHandler:(BOOL)signal
              displayUserPrompt:(BOOL)display {
    @synchronized(self) {
        static BOOL token = YES;
        if (token) {
            // store username
            if (username && username.length > 0) {
                __userName = username;
            }
            
            // change token5
            token = NO;
            
            // register defaults
            [[NSUserDefaults standardUserDefaults] registerDefaults:
             [NSDictionary dictionaryWithObject:@"NO" forKey:ABNotifierAlwaysSendKey]];
            
            // capture vars
            if (hostName && hostName.length > 0) {
                __hostName = hostName;
            } else {
                __hostName = ABNotifierHostName;
            }
            
            __userData = [[NSMutableDictionary alloc] init];
            __delegate = delegate;
            __useSSL = useSSL;
            __displayPrompt = display;
            
            // start crashreport
            [[ABCrashReport sharedInstance] startCrashReport];
            // switch on api key and project id
            if ([key length] && [projectId length]) {
                __APIKey = [key copy];
                __ABProjectID = [projectId copy];
                __reachability = SCNetworkReachabilityCreateWithName(NULL, [ABNotifierHostName UTF8String]);
                if (SCNetworkReachabilitySetCallback(__reachability, ABNotifierReachabilityDidChange, nil)) {
                    if (!SCNetworkReachabilityScheduleWithRunLoop(__reachability, CFRunLoopGetMain(), kCFRunLoopDefaultMode)) {
                        ABLog(@"Reachability could not be configired. No notices will be posted.");
                    }
                }
            }
            else {
                ABLog(@"The API key and ProjectID must not be blank. No notices will be posted.");
            }
            
            // switch on environment name
            if ([name length]) {
                
                __envName = name;
                // vars
                unsigned long length;
                
                // cache signal notice file path
                NSString *fileName = [[NSProcessInfo processInfo] globallyUniqueString];
                const char *filePath = [[ABNotifier pathForNewNoticeWithName:fileName] UTF8String];
                length = (strlen(filePath) + 1);
                ab_signal_info.notice_path = malloc(length);
                memcpy((void *)ab_signal_info.notice_path, filePath, length);
                
                // cache notice payload

                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:
                                [NSDictionary dictionaryWithObjectsAndKeys:
                                 name, ABNotifierEnvironmentNameKey,
                                 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
                                 ABNotifierBundleVersionKey,
                                 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"],
                                 ABNotifierExecutableKey,
                                 nil]];
                length = [data length];
                ab_signal_info.notice_payload = malloc(length);
                memcpy(ab_signal_info.notice_payload, [data bytes], length);
                ab_signal_info.notice_payload_length = length;
                
                // cache user data
                [self addEnvironmentEntriesFromDictionary:
                 [NSMutableDictionary dictionaryWithObjectsAndKeys:
                  ABNotifierPlatformName(), ABNotifierPlatformNameKey,
                  ABNotifierOperatingSystemVersion(), ABNotifierOperatingSystemVersionKey,
                  ABNotifierApplicationVersion(), ABNotifierApplicationVersionKey,
                  nil]];
                
                //only use the exception for custom exception log
//                if (exception) {
//                    ABNotifierStartExceptionHandler();
//                }
//                if (signal) {
//                    ABNotifierStartSignalHandler();
//                }
                
                // log
                ABLog(@"Notifier %@ ready to catch errors", ABNotifierVersion);
                ABLog(@"Environment \"%@\"", name);
            }
            else {
                ABLog(@"The environment name must not be blank. No new notices will be logged");
            }
            
        }
    }
}

#pragma mark - accessors
+ (id<ABNotifierDelegate>)delegate {
    @synchronized(self) {
        return __delegate;
    }
}
+ (NSString *)APIKey {
    @synchronized(self) {
        return __APIKey;
    }
}
+ (NSString *)projectID {
    @synchronized(self) {
        return __ABProjectID;
    }
}

#pragma mark - write data
+ (void)logException:(NSException *)exception parameters:(NSDictionary *)parameters {
    
    // force all activity onto main thread
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self logException:exception parameters:parameters];
        });
        return;
    }
    
    // get file handle
    NSString *name = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *path = [self pathForNewExceptionWithName:name];
    int fd = ABNotifierOpenNewNoticeFile([path UTF8String], ABNotifierExceptionNoticeType);
    
    // write stuff
    if (fd > -1) {
        @try {
            
            // create parameters
            NSMutableDictionary *exceptionParameters = [NSMutableDictionary dictionary];
            if ([parameters count]) { [exceptionParameters addEntriesFromDictionary:parameters]; }
            [exceptionParameters setValue:ABNotifierResidentMemoryUsage() forKey:@"Resident Memory Size"];
            [exceptionParameters setValue:ABNotifierVirtualMemoryUsage() forKey:@"Virtual Memory Size"];
            
            // write exception
            NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [exception name], ABNotifierExceptionNameKey,
                                        [exception reason], ABNotifierExceptionReasonKey,
                                        [exception callStackSymbols], ABNotifierCallStackKey,
                                        exceptionParameters, ABNotifierExceptionParametersKey,
#if TARGET_OS_IPHONE
                                        ABNotifierCurrentViewController(), ABNotifierControllerKey,
#endif
                                        nil];
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
            unsigned long length = [data length];
            write(fd, &length, sizeof(unsigned long));
            write(fd, [data bytes], length);
            
            // delegate
            id<ABNotifierDelegate> delegate = [self delegate];
            if (delegate && [delegate respondsToSelector:@selector(notifierDidLogException:)]) {
                [delegate notifierDidLogException:exception];
            }
            
        }
        @catch (NSException *exception) {
            ABLog(@"Exception encountered while logging exception");
            ABLog(@"%@", exception);
        }
        @finally {
            close(fd);
        }
    }
    
}
+ (void)logException:(NSException *)exception {
    [self logException:exception parameters:nil];
}

+ (void)writeTestNotice {
    @try {
        NSArray *array = [NSArray array];
        [array objectAtIndex:NSUIntegerMax];
    }
    @catch (NSException *e) {
        [self logException:e];
    }
}

#pragma mark - environment variables
+ (void)setEnvironmentValue:(NSString *)value forKey:(NSString *)key {
    @synchronized(self) {
        [__userData setObject:value forKey:key];
        [ABNotifier cacheUserDataDictionary];
    }
}
+ (void)addEnvironmentEntriesFromDictionary:(NSDictionary *)dictionary {
    @synchronized(self) {
        [__userData addEntriesFromDictionary:dictionary];
        [ABNotifier cacheUserDataDictionary];
    }
}
+ (NSString *)environmentValueForKey:(NSString *)key {
    @synchronized(self) {
        return [__userData objectForKey:key];
    }
}
+ (void)removeEnvironmentValueForKey:(NSString *)key {
    @synchronized(self) {
        [__userData removeObjectForKey:key];
        [ABNotifier cacheUserDataDictionary];
    }
}
+ (void)removeEnvironmentValuesForKeys:(NSArray *)keys {
    @synchronized(self) {
        [__userData removeObjectsForKeys:keys];
        [ABNotifier cacheUserDataDictionary];
    }
}

#pragma mark - file utilities
+ (NSString *)pathForNoticesDirectory {
    static NSString *path = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
#if TARGET_OS_IPHONE
        NSArray *folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        path = [folders objectAtIndex:0];
        if ([folders count] == 0) {
            path = NSTemporaryDirectory();
        }
        else {
            path = [path stringByAppendingPathComponent:@"AB Notices"];
        }
#else
        NSArray *folders = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        path = [folders objectAtIndex:0];
        if ([folders count] == 0) {
            path = NSTemporaryDirectory();
        }
        else {
            path = [path stringByAppendingPathComponent:ABNotifierApplicationName()];
            path = [path stringByAppendingPathComponent:@"AB Notices"];
        }
#endif
        NSFileManager *manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:path]) {
            [manager
             createDirectoryAtPath:path
             withIntermediateDirectories:YES
             attributes:nil
             error:nil];
        }
#if !TARGET_OS_IPHONE
        __noticePath = [[NSString alloc] initWithString:path];
#endif
    });
    return path;
}
+ (NSString *)pathForNewNoticeWithName:(NSString *)name {
    NSString *path = [self pathForNoticesDirectory];
#if !TARGET_OS_IPHONE
    if (__noticePath) {
        path = __noticePath;
    }
#endif
    path = [path stringByAppendingPathComponent:name];
    return [path stringByAppendingPathExtension:ABNotifierNoticePathExtension];
}

+ (NSString *)pathForNewExceptionWithName:(NSString *)name {
    NSString *path = [self pathForNoticesDirectory];
#if !TARGET_OS_IPHONE
    if (__noticePath) {
        path = __noticePath;
    }
#endif
    path = [path stringByAppendingPathComponent:name];
    return [path stringByAppendingPathExtension:ABNotifierExceptionPathExtension];
}

+ (NSArray *)pathsForAllNotices {
    NSString *path = [self pathForNoticesDirectory];
#if !TARGET_OS_IPHONE
    if (__noticePath) {
        path = __noticePath;
    }
#endif
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity:0];
    @try {
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        [contents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([[obj pathExtension] isEqualToString:ABNotifierNoticePathExtension]) {
                NSString *noticePath = [path stringByAppendingPathComponent:obj];
                [paths addObject:noticePath];
            } else if ([[obj pathExtension] isEqualToString:ABNotifierExceptionPathExtension]) {
                NSString *noticePath = [path stringByAppendingPathComponent:obj];
                [paths addObject:noticePath];
            }
        }];
    }
    @catch (NSException *exception) {
        ABLog(@"Error when getting pathsFroAllNotices: %@", exception.description);
    }
    @finally {
        return paths;
    }
}

#pragma mark - post notices
+ (void)postNoticesWithPaths:(NSArray *)paths {
    
    // assert
    NSAssert(![NSThread isMainThread], @"This method must not be called on the main thread");
    NSAssert([paths count], @"No paths were provided");
    
    // get variables
    if ([paths count] == 0) { return; }
    id<ABNotifierDelegate> delegate = [ABNotifier delegate];
    
    // notify people
    dispatch_sync(dispatch_get_main_queue(), ^{
        if ([delegate respondsToSelector:@selector(notifierWillPostNotices)]) {
            [delegate notifierWillPostNotices];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:ABNotifierWillPostNoticesNotification object:self];
    });
    
#if TARGET_OS_IPHONE
    
    // start background task
    __block BOOL keepPosting = YES;
    UIApplication *app = [UIApplication sharedApplication];
    UIBackgroundTaskIdentifier task = [app beginBackgroundTaskWithExpirationHandler:^{
        keepPosting = NO;
    }];
    
    // report each notice
    [paths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (keepPosting) { [self postNoticeWithContentsOfFile:obj]; }
        else { *stop = YES; }
    }];
    
    // end background task
    if (task != UIBackgroundTaskInvalid) {
        [app endBackgroundTask:task];
    }
    
#else
    
    // report each notice
    [paths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self postNoticeWithContentsOfFile:obj];
    }];
    
#endif
    
    // notify people
    dispatch_sync(dispatch_get_main_queue(), ^{
        if ([delegate respondsToSelector:@selector(notifierDidPostNotices)]) {
            [delegate notifierDidPostNotices];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:ABNotifierDidPostNoticesNotification object:self];
    });
	
}

+ (NSData *)JSONString:(NSString *)filePath {
    NSData *jsonData;
    NSError *error = NULL;
    NSError *jsonSerializationError = nil;
    NSString *dataStr = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (!dataStr) {
        jsonData = nil;
        ABLog(@"ERROR: Crash report data is not readable.");
        return jsonData;
    }
    NSDictionary *notice = @{@"report": dataStr, @"context":@{@"userName":__userName, @"environment":__envName, @"notifier":@{@"name":ABNotifierName,@"version":ABNotifierVersion,@"url":@"https://github.com/airbrake/airbrake-ios"}}};
    jsonData = [NSJSONSerialization dataWithJSONObject:notice options:NSJSONWritingPrettyPrinted error:&jsonSerializationError];
    if(jsonSerializationError) {
        jsonData = nil;
        ABLog(@"ERROR: JSON Encoding Failed: %@", [jsonSerializationError localizedDescription]);
    }
    return jsonData;
}

+ (void)postNoticeWithContentsOfFile:(NSString *)path {
    
    // create url
    //API V3 iOS report https://api.airbrake.io/api/v3/projects/%d/ios-reports?key=API_KEY
    NSString *URLString = [NSString stringWithFormat:
                           @"%@://api.%@/api/v3/projects/%@/ios-reports?key=%@",
                           (__useSSL ? @"https" : @"http"), __hostName,
                           [self projectID], [self APIKey]];
    NSData *jsonData;
    NSString *fileType = [path pathExtension];
    // create data based on file name, if it's a full crash report, will send the report as human readable string.
    if ([fileType isEqualToString:ABNotifierNoticePathExtension]) {
        jsonData = [self JSONString:path];
    } else {
        //current V3 API https://api.airbrake.io/api/v3/projects/%d/notices?key=API_KEY
        URLString = [NSString stringWithFormat:
                     @"%@://api.%@/api/v3/projects/%@/notices?key=%@",
                     (__useSSL ? @"https" : @"http"), __hostName,
                     [self projectID], [self APIKey]];
        // get ABNotice
        ABNotice *notice = [ABNotice noticeWithContentsOfFile:path];
        [notice setPOSTUserName:__userName];
        jsonData = [notice JSONString];
    }
    NSURL *URL = [NSURL URLWithString:URLString];
    // create url request
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	[request setTimeoutInterval:10.0];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPMethod:@"POST"];
    if (jsonData) {
        [request setHTTPBody:jsonData];
    }
    else {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        return;
    }
	

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseBody, NSError* error){
        if (response) {
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                
                if (error) {
                    ABLog(@"Encountered error while posting notice.");
                    ABLog(@"%@", error);
                    return;
                }
                else {
                    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                }
                
                // great success
                if (statusCode >= 200 && statusCode <=299) {
                    ABLog(@"Crash report posted status code:%ld",(long)statusCode);
                    ABLog(@"%@", [[NSString alloc] initWithData:responseBody encoding:NSUTF8StringEncoding]);
                }
                
                // forbidden
                else if (statusCode == 403) {
                    ABLog(@"Please make sure that your API key is correct and that your project supports SSL.");
                }
                
                // invalid post
                else if (statusCode == 422) {
                    ABLog(@"The posted notice payload is invalid.");
#ifdef DEBUG
                    ABLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
#endif
                }
                
                // unknown
                else {
                    ABLog(@"Encountered unexpected status code: %ld", (long)statusCode);
#ifdef DEBUG
                    ABLog(@"%@", [[NSString alloc] initWithData:responseBody encoding:NSUTF8StringEncoding]);
#endif
            }
        }
            
      }
    }];
}

#pragma mark - cache methods
+ (void)cacheUserDataDictionary {
    @synchronized(self) {
        
        // free old cached value
        free(ab_signal_info.user_data);
        ab_signal_info.user_data_length = 0;
        ab_signal_info.user_data = nil;
        
        // cache new value
        if (__userData) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:__userData];
            unsigned long length = [data length];
            ab_signal_info.user_data = malloc(length);
            [data getBytes:ab_signal_info.user_data length:length];
            ab_signal_info.user_data_length = length;
        }
        
    }
}

#pragma mark - user interface
+ (void)showNoticeAlertForNoticesWithPaths:(NSArray *)paths {
    
    // assert
    NSAssert([NSThread isMainThread], @"This method must be called on the main thread");
    NSAssert([paths count], @"No paths were provided");
    
    // get delegate
    id<ABNotifierDelegate> delegate = [self delegate];
    
    // alert title
    NSString *title = nil;
    if ([delegate respondsToSelector:@selector(titleForNoticeAlert)]) {
        title = [delegate titleForNoticeAlert];
    }
    if (title == nil) {
        title = ABLocalizedString(@"NOTICE_TITLE");
    }
    
    // alert body
    NSString *body = nil;
    if (delegate && [delegate respondsToSelector:@selector(bodyForNoticeAlert)]) {
        body = [delegate bodyForNoticeAlert];
    }
    if (body == nil) {
        body = [NSString stringWithFormat:ABLocalizedString(@"NOTICE_BODY"), ABNotifierApplicationName()];
    }
    
    // declare blocks
    void (^delegateDismissBlock) (void) = ^{
        if ([delegate respondsToSelector:@selector(notifierDidDismissAlert)]) {
            [delegate notifierDidDismissAlert];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:ABNotifierDidDismissAlertNotification object:self];
    };
    void (^delegatePresentBlock) (void) = ^{
        if ([delegate respondsToSelector:@selector(notifierWillDisplayAlert)]) {
            [delegate notifierWillDisplayAlert];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:ABNotifierWillDisplayAlertNotification object:self];
    };
    void (^postNoticesBlock) (void) = ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self postNoticesWithPaths:paths];
        });
    };
    void (^deleteNoticesBlock) (void) = ^{
        NSFileManager *manager = [NSFileManager defaultManager];
        [paths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [manager removeItemAtPath:obj error:nil];
        }];
    };
    void (^setDefaultsBlock) (void) = ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:ABNotifierAlwaysSendKey];
        [defaults synchronize];
    };
    
#if TARGET_OS_IPHONE
    if ([UIAlertController class]) {
        UIAlertController *alert= [UIAlertController alertControllerWithTitle:title
                                                                      message:body
                                                               preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* alwaysSend = [UIAlertAction actionWithTitle:ABLocalizedString(@"ALWAYS_SEND")
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action){
                                                               setDefaultsBlock();
                                                               postNoticesBlock();
                                                           }];
        UIAlertAction* send = [UIAlertAction actionWithTitle:ABLocalizedString(@"SEND")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action){
                                                         postNoticesBlock();
                                                     }];
        UIAlertAction* cancel = [UIAlertAction actionWithTitle:ABLocalizedString(@"DONT_SEND")
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           deleteNoticesBlock();
                                                           [alert dismissViewControllerAnimated:YES completion:nil];
                                                       }];
        
        [alert addAction:alwaysSend];
        [alert addAction:send];
        [alert addAction:cancel];
        [[[UIApplication sharedApplication] delegate].window.rootViewController presentViewController:alert animated:YES completion:nil];
    } else {
        GCAlertView *alert = [[GCAlertView alloc] initWithTitle:title message:body];
        [alert addButtonWithTitle:ABLocalizedString(@"ALWAYS_SEND") block:^{
            setDefaultsBlock();
            postNoticesBlock();
        }];
        [alert addButtonWithTitle:ABLocalizedString(@"SEND") block:postNoticesBlock];
        [alert addButtonWithTitle:ABLocalizedString(@"DONT_SEND") block:deleteNoticesBlock];
        [alert setDidDismissBlock:delegateDismissBlock];
        [alert setDidDismissBlock:delegatePresentBlock];
        [alert setCancelButtonIndex:2];
        [alert show];
    }
    
#else
    
    // delegate
    delegatePresentBlock();
    
    // build alert
	NSAlert *alert = [NSAlert
                      alertWithMessageText:title
                      defaultButton:ABLocalizedString(@"ALWAYS_SEND")
                      alternateButton:ABLocalizedString(@"DONT_SEND")
                      otherButton:ABLocalizedString(@"SEND")
                      informativeTextWithFormat:body];
    
    // run alert
	NSInteger code = [alert runModal];
    
    // don't send
    if (code == NSAlertAlternateReturn) {
        deleteNoticesBlock();
    }
    
    // send
    else {
        if (code == NSAlertDefaultReturn) {
            setDefaultsBlock();
        }
        postNoticesBlock();
    }
    
    // delegate
	delegateDismissBlock();
    
#endif
    
}

#pragma mark - reachability
+ (BOOL)isReachable:(SCNetworkReachabilityFlags)flags {
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
        return NO;
    }
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        return YES;
    }
    if (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) ||
        ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            return YES;
        }
    }
    return NO;
}

@end

#pragma mark - reachability change
void ABNotifierReachabilityDidChange(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    if ([ABNotifier isReachable:flags]) {
        static dispatch_once_t token;
        dispatch_once(&token, ^{
            NSArray *paths = [ABNotifier pathsForAllNotices];
            if ([paths count]) {
                if ([[NSUserDefaults standardUserDefaults] boolForKey:ABNotifierAlwaysSendKey] ||
                    !__displayPrompt) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [ABNotifier postNoticesWithPaths:paths];
                    });
                }
                else {
                    [ABNotifier showNoticeAlertForNoticesWithPaths:paths];
                }
            }
        });
    }
}
