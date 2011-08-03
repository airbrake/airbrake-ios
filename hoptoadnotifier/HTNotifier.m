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

#import "HTNotifier.h"
#import "HTNotice.h"
#import "HTFunctions.h"

// internal
static HTNotifier *sharedNotifier = nil;
static NSString *ABNotifierHostName = @"airbrakeapp.com";
static NSString *ABNotifierAlwaysSendKey = @"AlwaysSendCrashReports";

// extern strings
NSString *HTNotifierVersion                 = @"2.3";
NSString *HTNotifierBundleName              = @"${BUNDLE}";
NSString *HTNotifierBundleVersion           = @"${VERSION}";
NSString *HTNotifierDevelopmentEnvironment  = @"Development";
NSString *HTNotifierAdHocEnvironment        = @"Ad Hoc";
NSString *HTNotifierAppStoreEnvironment     = @"App Store";
NSString *HTNotifierReleaseEnvironment      = @"Release";
NSString *HTNotifierAutomaticEnvironment    = @"${AUTOMATIC}";

// reachability callback
void ABNotifierReachabilityDidChange(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);

@interface HTNotifier ()
@property (nonatomic, readwrite, copy) NSString *APIKey;
@end

@interface HTNotifier (private)

// utility methods
+ (NSString *)pathForNoticesDirectory;
+ (NSString *)pathForNewNoticeWithName:(NSString *)name;
+ (BOOL)hasNotices;
+ (NSArray *)pathsForAllNotices;

// init
- (id)initWithAPIKey:(NSString *)APIKey environmentName:(NSString *)environmentName;

// post methods
- (void)postAllNotices;
- (void)postNoticeWithContentsOfFile:(NSString *)path toURL:(NSURL *)URL;

// show alert
- (void)showNoticeAlert;

@end

@implementation HTNotifier (private)
+ (NSString *)pathForNoticesDirectory {
    static NSString *folderName = @"Hoptoad Notices";
    static NSString *path = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        NSArray *folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        path = [folders objectAtIndex:0];
        if ([folders count] == 0) {
            path = NSTemporaryDirectory();
        }
        else {
            path = [path stringByAppendingPathComponent:folderName];
        }
        NSFileManager *manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:path]) {
            [manager
             createDirectoryAtPath:path
             withIntermediateDirectories:YES
             attributes:nil
             error:nil];
        }
        [path retain];
    });
    return path;
}
+ (NSString *)pathForNewNoticeWithName:(NSString *)name {
    NSString *path = [self pathForNoticesDirectory];
    path = [path stringByAppendingPathComponent:name];
    return [path stringByAppendingPathExtension:ABNotifierNoticePathExtension];
}
+ (BOOL)hasNotices {
    NSString *path = [self pathForNoticesDirectory];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    return ([contents count] > 0);
}
+ (NSArray *)pathsForAllNotices {
    NSString *path = [self pathForNoticesDirectory];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSMutableArray *paths = [[NSMutableArray alloc] initWithCapacity:[contents count]];
    [contents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj pathExtension] isEqualToString:ABNotifierNoticePathExtension]) {
            NSString *noticePath = [path stringByAppendingPathComponent:obj];
            [paths addObject:noticePath];
        }
    }];
    return [paths autorelease];
}
- (id)initWithAPIKey:(NSString *)APIKey environmentName:(NSString *)environmentName {
	self = [super init];
	if (self) {
        
		// setup ivars
        self.APIKey = APIKey;
        self.useSSL = NO;
		
		// register defaults
        NSDictionary *toRegister = [NSDictionary dictionaryWithObject:@"NO" forKey:ABNotifierAlwaysSendKey];
		[[NSUserDefaults standardUserDefaults] registerDefaults:toRegister];
		
		// setup reachability
        BOOL reachabilityConfigured = NO;
		reachability = SCNetworkReachabilityCreateWithName(NULL, [ABNotifierHostName UTF8String]);
        if (SCNetworkReachabilitySetCallback(reachability, ABNotifierReachabilityDidChange, nil)) {
            if (SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), kCFRunLoopDefaultMode)) {
                reachabilityConfigured = YES;
            }
        }
        if (!reachabilityConfigured) {
            [self release];
            return nil;
        }
        
        {
            
            // vars
            NSDictionary *dictionary;
            NSData *data;
            unsigned long length;
            
            // cache notice file path
            NSString *fileName = [[NSProcessInfo processInfo] globallyUniqueString];
            const char *filePath = [[HTNotifier pathForNewNoticeWithName:fileName] UTF8String];
            length = (strlen(filePath) + 1);
            ab_signal_info.notice_path = malloc(length);
            memcpy((void *)ab_signal_info.notice_path, filePath, length);
            
            // notice payload
            dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                          environmentName, ABNotifierEnvironmentNameKey,
                          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
                          ABNotifierBundleVersionKey,
                          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"],
                          ABNotifierExecutableKey,
                          nil];
            data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
            length = [data length];
            ab_signal_info.notice_payload = malloc(length);
            ab_signal_info.notice_payload_length = length;
            [data getBytes:ab_signal_info.notice_payload length:length];
            
            // user data
            dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                          ABNotifierPlatformName(), ABNotifierPlatformNameKey,
                          ABNotifierOperatingSystemVersion(), ABNotifierOperatingSystemVersionKey,
                          ABNotifierApplicationVersion(), ABNotifierApplicationVersionKey,
                          nil];
            
#if TARGET_OS_IPHONE && defined(DEBUG)
            [(NSMutableDictionary *)dictionary
             setObject:[[UIDevice currentDevice] uniqueIdentifier]
             forKey:@"UDID"];
#endif
            data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
            length = [data length];
            ab_signal_info.user_data = malloc(length);
            ab_signal_info.user_data_length = length;
            [data getBytes:ab_signal_info.user_data length:length];
            
        }
        
        // start handlers
		ABNotifierStartHandlers();
		
	}
	return self;
}
- (void)postAllNotices {
    
    // assert
    NSAssert1(![NSThread isMainThread], @"%@ must not be called on the main thread", NSStringFromSelector(_cmd));
    
    // get paths
    NSArray *paths = [HTNotifier pathsForAllNotices];
    
    // notify delegate
    if ([paths count] && [self.delegate respondsToSelector:@selector(notifierWillPostNotices)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate notifierWillPostNotices];
        });
    }
    
    // create url
    NSString *URLString = [NSString stringWithFormat:
                           @"%@://%@/notifier_api/v2/notices",
                           (self.useSSL) ? @"https" : @"http",
                           ABNotifierHostName];
    NSURL *URL = [NSURL URLWithString:URLString];
    
#if TARGET_OS_IPHONE
    
    // start background task
    __block BOOL keepPosting = YES;
    UIApplication *app = [UIApplication sharedApplication];
    UIBackgroundTaskIdentifier task = [app beginBackgroundTaskWithExpirationHandler:^{
        keepPosting = NO;
    }];
    
    // report each notice
    [paths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (keepPosting) { [self postNoticeWithContentsOfFile:obj toURL:URL]; }
        else { *stop = YES; }
    }];
    
    // end background task
    if (task != UIBackgroundTaskInvalid) {
        [app endBackgroundTask:task];
    }
    
#else
    
    // report each notice
    [paths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self postNoticeWithContentsOfFile:obj toURL:URL];
    }];
    
#endif
    
    
    
    // notify delegate
    if ([paths count] && [self.delegate respondsToSelector:@selector(notifierDidPostNotices)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate notifierDidPostNotices]; 
        });
    }
	
}
- (void)postNoticeWithContentsOfFile:(NSString *)path toURL:(NSURL *)URL {
    
    // create url request
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	[request setTimeoutInterval:10.0];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPMethod:@"POST"];
    
	// get notice payload
    HTNotice *notice = [HTNotice noticeWithContentsOfFile:path];
#ifdef DEBUG
    HTLog(@"%@", notice);
#endif 
    NSData *data = [notice hoptoadXMLData];
    if (data) {
        [request setHTTPBody:data];
    }
    else {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        return;
    }
	
	// perform request
    NSError *error = nil;
	NSHTTPURLResponse *response = nil;
	NSData *responseBody = [NSURLConnection
							sendSynchronousRequest:request
							returningResponse:&response
							error:&error];
	
	// error checking
    if (error) {
        HTLog(@"encountered error while posting notice\n%@", error);
    }
    else {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
	
	// status code checking
	NSInteger statusCode = [response statusCode];
	if (statusCode == 200) {
		HTLog(@"crash report posted");
	}
	else if (responseBody == nil) {
		HTLog(@"unexpected response\nstatus code:%ld", (long)statusCode);
	}
	else {
		NSString *responseString = [[NSString alloc]
                                    initWithData:responseBody
                                    encoding:NSUTF8StringEncoding];
		HTLog(@"unexpected response\nstatus code:%ld\nresponse body:%@", (long)statusCode, responseString);
		[responseString release];
	}
    
}
- (void)showNoticeAlert {
    
    // delegate
    if ([self.delegate respondsToSelector:@selector(notifierWillDisplayAlert)]) {
		[self.delegate notifierWillDisplayAlert];
	}
    
    // alert title
    NSString *title = nil;
    if ([self.delegate respondsToSelector:@selector(titleForNoticeAlert)]) {
        title = [self.delegate titleForNoticeAlert];
    }
    if (title == nil) {
        title = HTLocalizedString(@"NOTICE_TITLE");
    }
    
    // alert body
    NSString *body = nil;
    if ([self.delegate respondsToSelector:@selector(bodyForNoticeAlert)]) {
        body = [self.delegate bodyForNoticeAlert];
    }
    if (body == nil) {
        body = HTLocalizedString(@"NOTICE_BODY");
    }
    
#if TARGET_OS_IPHONE
    
    // show alert
    UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:ABNotifierStringByReplacingAirbrakeConstantsInString(title)
						  message:ABNotifierStringByReplacingAirbrakeConstantsInString(body)
						  delegate:self
						  cancelButtonTitle:HTLocalizedString(@"DONT_SEND")
						  otherButtonTitles:HTLocalizedString(@"ALWAYS_SEND"), HTLocalizedString(@"SEND"), nil];
	[alert show];
	[alert release];
    
#else
    
    // build alert
	NSAlert *alert = [NSAlert
                      alertWithMessageText:ABNotifierStringByReplacingAirbrakeConstantsInString(title)
                      defaultButton:HTLocalizedString(@"ALWAYS_SEND")
                      alternateButton:HTLocalizedString(@"DONT_SEND")
                      otherButton:HTLocalizedString(@"SEND")
                      informativeTextWithFormat:ABNotifierStringByReplacingAirbrakeConstantsInString(body)];
    
    // run alert
	NSInteger code = [alert runModal];
    
    // don't send
    if (code == NSAlertAlternateReturn) {
        NSFileManager *manager = [NSFileManager defaultManager];
        [[HTNotifier pathsForAllNotices] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [manager removeItemAtPath:obj error:nil];
        }];
    }
    
    // send
    else {
        if (code == NSAlertDefaultReturn) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:ABNotifierAlwaysSendKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self postAllNotices];
        });
    }
    
    // delegate
	if ([self.delegate respondsToSelector:@selector(notifierDidDismissAlert)]) {
		[self.delegate notifierDidDismissAlert];
	}
    
#endif
    
    
    
}
@end

@implementation HTNotifier

@synthesize APIKey = __APIKey;
@synthesize useSSL = __useSSL;
@synthesize delegate = __delegate;

#pragma mark - class methods
+ (HTNotifier *)startNotifierWithAPIKey:(NSString *)key environmentName:(NSString *)name {
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        
        // validate
		if (![key length]) {
			HTLog(@"The API key must not be blank");
			return;
		}
		if (![name length]) {
			HTLog(@"The environment name must not be blank");
			return;
		}
        
        // create
        NSString *envName = name;
        if ([envName isEqualToString:HTNotifierAutomaticEnvironment]) {
#ifdef DEBUG
            envName = HTNotifierDevelopmentEnvironment;
#else
            envName = HTNotifierReleaseEnvironment;
#endif
        }
        sharedNotifier = [[HTNotifier alloc] initWithAPIKey:key environmentName:envName];
		
		// log
        if (sharedNotifier) {
            HTLog(@"Notifier %@ ready to catch errors", HTNotifierVersion);
            HTLog(@"Environment \"%@\"", envName);
        }
        else {
            HTLog(@"Unable to create crash notifier");
        }
        
    });
    return sharedNotifier;
}
+ (HTNotifier *)sharedNotifier {
	@synchronized(self) {
		return sharedNotifier;
	}
}

//#pragma mark - environment variables
//- (void)setEnvironmentValue:(NSString *)valueOrNil forKey:(NSString *)key {
//    @synchronized(self) {
//        NSMutableDictionary *dictionary = [self.environmentInfo mutableCopy];
//        if (valueOrNil) { [dictionary removeObjectForKey:key]; }
//        else { [dictionary setObject:valueOrNil forKey:key]; }
//        self.environmentInfo = dictionary;
//    }
//}
//- (NSString *)environmentValueForKey:(NSString *)key {
//    NSString *value = nil;
//    @synchronized(self) {
//        value = [self.environmentInfo objectForKey:key];
//    }
//    return value;
//}

#pragma mark - test notice
- (void)writeTestNotice {
    @try {
        NSArray *array = [NSArray array];
        [array objectAtIndex:NSUIntegerMax];
    }
    @catch (NSException *e) {
        [self logException:e];
    }
}

#pragma mark - log exception
- (void)logException:(NSException *)exception {
    @synchronized(self) {
        
        // get file handle
        NSString *name = [[NSProcessInfo processInfo] globallyUniqueString];
        NSString *path = [HTNotifier pathForNewNoticeWithName:name];
        int fd = ABNotifierOpenNewNoticeFile([path UTF8String], ABNotifierExceptionNoticeType);
        
        // write stuff
        if (fd > -1) {
            @try {
                
                // write exception
                NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [exception name], ABNotifierExceptionNameKey,
                                            [exception reason], ABNotifierExceptionReasonKey,
                                            [exception callStackSymbols], ABNotifierCallStackKey,
#if TARGET_OS_IPHONE
                                            ABNotifierCurrentViewController(), ABNotifierControllerKey,
#endif
                                            nil];
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
                unsigned long length = [data length];
                write(fd, &length, sizeof(unsigned long));
                write(fd, [data bytes], length);
                
            }
            @catch (NSException *exception) {
                
            }
            @finally {
                close(fd);
            }
        }

        
        
        
//        // open file
//        NSString *name = [[NSProcessInfo processInfo] globallyUniqueString];
//        NSString *path = [HTNotifier pathForNewNoticeWithName:name];
//        int fd = HTOpenFile(HTExceptionNoticeType, [path UTF8String]);
//        
//        // write file
//        if (fd > -1) {
//            @try {
//                
//                // crash info
//                NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:5];
//                
//                // addresses
//                NSArray *symbols = [exception callStackSymbols];
//                [dictionary setObject:symbols forKey:@"call stack"];
//                
//                // exception name and reason
//                [dictionary setObject:[exception name] forKey:@"exception name"];
//                [dictionary setObject:[exception reason] forKey:@"exception reason"];
//                
//                // view controller
//                NSString *viewController = HTCurrentViewController();
//                if (viewController != nil) {
//                    [dictionary setObject:viewController forKey:@"view controller"];
//                }
//                
//                // environment info
//                [self setEnvironmentValue:[[exception userInfo] description] forKey:@"Exception"];
//                [dictionary setObject:self.environmentInfo forKey:@"environment info"];
//                
//                // write data
//                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
//                NSUInteger length = [data length];
//                write(fd, &length, sizeof(unsigned long));
//                write(fd, [data bytes], length);
//                
//                // notify delegate on main thread
//                if ([self.delegate respondsToSelector:@selector(notifierDidLogException:)]) {
//                    [self.delegate notifierDidLogException:exception];
//                }
//                
//            }
//            @catch (NSException *exception) {
//                HTLog(@"Encountered an exception while logging an exception");
//            }
//            @finally {
//                close(fd);
//            }
//        }
    }
}

#pragma mark - memory management
- (void)dealloc {
    
    // stop event sources
    if (reachability) {
        SCNetworkReachabilitySetCallback(reachability, nil, nil);
        SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        CFRelease(reachability);
        reachability = nil;
    }
    
    // stop handlers
    ABNotifierStopHandlers();
    free(ab_signal_info.user_data);
    ab_signal_info.user_data = nil;
    ab_signal_info.user_data_length = 0;
    free(ab_signal_info.notice_payload);
    ab_signal_info.notice_payload = nil;
    ab_signal_info.notice_payload_length = 0;
    free((void *)ab_signal_info.notice_path);
    ab_signal_info.notice_path = nil;
    
    // free ivars
    self.APIKey = nil;
    
    // super
	[super dealloc];
    
}

#if TARGET_OS_IPHONE
#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if ([self.delegate respondsToSelector:@selector(notifierDidDismissAlert)]) {
		[self.delegate notifierDidDismissAlert];
	}
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == alertView.cancelButtonIndex) {
        NSFileManager *manager = [NSFileManager defaultManager];
        [[HTNotifier pathsForAllNotices] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [manager removeItemAtPath:obj error:nil];
        }];
	}
    else {
        NSString *button = [alertView buttonTitleAtIndex:buttonIndex];
        if ([button isEqualToString:HTLocalizedString(@"ALWAYS_SEND")]) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:ABNotifierAlwaysSendKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self postAllNotices];
        });
    }
}
#endif

@end

#pragma mark - reachability change
void ABNotifierReachabilityDidChange(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    if (flags & kSCNetworkReachabilityFlagsReachable) {
        static dispatch_once_t predicate;
        dispatch_once(&predicate, ^{
            SCNetworkReachabilitySetCallback(target, nil, nil);
            SCNetworkReachabilityUnscheduleFromRunLoop(target, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if ([HTNotifier hasNotices]) {
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:ABNotifierAlwaysSendKey]) {
                        [[HTNotifier sharedNotifier] postAllNotices];
                    }
                    else {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [[HTNotifier sharedNotifier] showNoticeAlert];
                        });
                    }
                }
            });
        });
    }
}
