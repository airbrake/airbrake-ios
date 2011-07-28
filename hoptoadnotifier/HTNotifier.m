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

#import "HTNotifier.h"
#import "HTNotice.h"
#import "HTFunctions.h"

// internal
static HTNotifier *sharedNotifier = nil;
static NSString *HTNotifierHostName = @"airbrakeapp.com";
static NSString *HTNotifierAlwaysSendKey = @"AlwaysSendCrashReports";
#define HTNotifierURL [NSURL URLWithString: \
	[NSString stringWithFormat: \
	@"%@://%@/notifier_api/v2/notices", \
	(self.useSSL) ? @"https" : @"http", \
	HTNotifierHostName]]
#define HTIsMultitaskingSupported \
	[[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && \
	[[UIDevice currentDevice] isMultitaskingSupported]
#define HT_IOS_SDK_4 (TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= 4000)

// extern strings
NSString *HTNotifierVersion                 = @"2.3";
NSString *HTNotifierBundleName              = @"${BUNDLE}";
NSString *HTNotifierBundleVersion           = @"${VERSION}";
NSString *HTNotifierDevelopmentEnvironment  = @"Development";
NSString *HTNotifierAdHocEnvironment        = @"Ad Hoc";
NSString *HTNotifierAppStoreEnvironment     = @"App Store";
NSString *HTNotifierReleaseEnvironment      = @"Release";
NSString *HTNotifierAutomaticEnvironment    = @"${AUTOMATIC}";

@interface HTNotifier ()
@property (nonatomic, readwrite, copy) NSString *apiKey;
@property (nonatomic, readwrite, copy) NSString *environmentName;
@end

#pragma mark - private methods
@interface HTNotifier (private)

// init
- (id)initWithAPIKey:(NSString *)key environmentName:(NSString *)name;

// post methods
- (void)postNoticesWithPaths:(NSArray *)paths;
- (void)postNoticeWithPath:(NSString *)path;

// reachability
- (BOOL)isHoptoadReachable;

// notifications
- (void)registerNotifications;
- (void)unregisterNotifications;
- (void)applicationDidBecomeActive:(NSNotification *)notif;

// show alert
- (void)showNoticeAlert;

@end
@implementation HTNotifier (private)
- (id)initWithAPIKey:(NSString *)key environmentName:(NSString *)name {
	self = [super init];
	if (self) {
		
		// create folder
		NSString *directory = ABNotifierPathForNoticesDirectory();
		if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
			[[NSFileManager defaultManager]
			 createDirectoryAtPath:directory
			 withIntermediateDirectories:YES
			 attributes:nil
			 error:nil];
		}
		
		// setup values
        self.apiKey = key;
        self.environmentName = name;
        self.useSSL = NO;
		__environmentInfo = [[NSMutableDictionary alloc] init];
#if TARGET_OS_IPHONE && defined(DEBUG)
        NSString *UDID = [[UIDevice currentDevice] uniqueIdentifier];
        [self
         setEnvironmentValue:UDID
         forKey:@"UDID"];
#endif
		
		// register defaults
		[[NSUserDefaults standardUserDefaults] registerDefaults:
		 [NSDictionary dictionaryWithObject:@"NO" forKey:HTNotifierAlwaysSendKey]];
		
		// setup reachability
		reachability = SCNetworkReachabilityCreateWithName(NULL, [HTNotifierHostName UTF8String]);
		
		// notifications
		[self registerNotifications];
        
        // start
        HTInitNoticeInfo();
		HTStartHandlers();
		
	}
	return self;
}
- (void)postNoticesWithPaths:(NSArray *)paths {
    
    // pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // notify delegate
    if ([paths count] && [self.delegate respondsToSelector:@selector(notifierWillPostNotices)]) {
        [self.delegate
         performSelectorOnMainThread:@selector(notifierWillPostNotices)
         withObject:nil
         waitUntilDone:YES];
    }
    
#if HT_IOS_SDK_4
	
	if (HTIsMultitaskingSupported) {
		
		// start background task
        __block BOOL keepPosting = YES;
		UIApplication *app = [UIApplication sharedApplication];
		UIBackgroundTaskIdentifier task = [app beginBackgroundTaskWithExpirationHandler:^{
			keepPosting = NO;
		}];
		
		// report each notice
		for (NSString *path in paths) {
			if (!keepPosting) { break; }
			[self postNoticeWithPath:path];
		}
		
		// end background task
		if (task != UIBackgroundTaskInvalid) {
			[app endBackgroundTask:task];
		}
		
	}
	else {
		
#endif
        
		// report each notice
		for (NSString *path in paths) {
			[self postNoticeWithPath:path];
		}
		
#if HT_IOS_SDK_4
		
	}
	
#endif
    
    // notify delegate
    if ([paths count] && [self.delegate respondsToSelector:@selector(notifierDidPostNotices)]) {
        [self.delegate
         performSelectorOnMainThread:@selector(notifierDidPostNotices)
         withObject:nil
         waitUntilDone:YES];
    }
    
    // pool
    [pool drain];
	
}
- (void)postNoticeWithPath:(NSString *)path {
    
    // create url request
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:HTNotifierURL];
	[request setTimeoutInterval:10.0];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPMethod:@"POST"];
    
	// get notice payload
    HTNotice *notice = [HTNotice noticeWithContentsOfFile:path];
    NSData *data = [notice hoptoadXMLData];
    if (!data) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        return;
    }
    else {
        [request setHTTPBody:data];
#ifdef DEBUG
        HTLog(@"%@", notice);
#endif
    }
	
	// perform request
    NSError *error = nil;
	NSHTTPURLResponse *response = nil;
	NSData *responseBody = [NSURLConnection
							sendSynchronousRequest:request
							returningResponse:&response
							error:&error];
	
	// error checking
	if (error == nil) {
		[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
	}
	else {
		HTLog(@"encountered error while posting notice\n%@", error);
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
- (BOOL)isHoptoadReachable {
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityGetFlags(reachability, &flags);
	return (flags & kSCNetworkReachabilityFlagsReachable);
}
- (void)registerNotifications {
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(applicationDidBecomeActive:)
	 name:UIApplicationDidBecomeActiveNotification
	 object:nil];
#else
    [[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(applicationDidBecomeActive:)
	 name:NSApplicationDidBecomeActiveNotification
	 object:nil];
#endif
}
- (void)unregisterNotifications {
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:UIApplicationDidBecomeActiveNotification
	 object:nil];
#else
    [[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:NSApplicationDidBecomeActiveNotification
	 object:nil];
#endif
}
- (void)applicationDidBecomeActive:(NSNotification *)notif {
    if ([self postNotices]) {
        [self unregisterNotifications];
    }
}
- (void)showNoticeAlert {
    
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
    
    // delegate
    if ([self.delegate respondsToSelector:@selector(notifierWillDisplayAlert)]) {
		[self.delegate notifierWillDisplayAlert];
	}
    
#if TARGET_OS_IPHONE
    
    UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:HTStringByReplacingHoptoadVariablesInString(title)
						  message:HTStringByReplacingHoptoadVariablesInString(body)
						  delegate:self
						  cancelButtonTitle:HTLocalizedString(@"DONT_SEND")
						  otherButtonTitles:HTLocalizedString(@"ALWAYS_SEND"), HTLocalizedString(@"SEND"), nil];
	[alert show];
	[alert release];
    
#else
	
    // build alert
	NSAlert *alert = [NSAlert
                      alertWithMessageText:HTStringByReplacingHoptoadVariablesInString(title)
                      defaultButton:HTLocalizedString(@"ALWAYS_SEND")
                      alternateButton:HTLocalizedString(@"DONT_SEND")
                      otherButton:HTLocalizedString(@"SEND")
                      informativeTextWithFormat:HTStringByReplacingHoptoadVariablesInString(body)];
    
    // run alert
	NSInteger code = [alert runModal];
    
    // get notices
    NSArray *notices = HTNotices();
    
    // don't send
    if (code == NSAlertAlternateReturn) {
        for (NSString *notice in notices) {
			[[NSFileManager defaultManager] removeItemAtPath:notice error:nil];
		}
    }
    
    // send
    else {
        if (code == NSAlertDefaultReturn) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HTNotifierAlwaysSendKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        [self performSelectorInBackground:@selector(postNoticesWithPaths:) withObject:notices];
    }
    
    // delegate
	if ([self.delegate respondsToSelector:@selector(notifierDidDismissAlert)]) {
		[self.delegate notifierDidDismissAlert];
	}
    
#endif
    
}
@end

#pragma mark - public methods
@implementation HTNotifier

@synthesize environmentInfo = __environmentInfo;
@synthesize environmentName = __environmentName;
@synthesize apiKey          = __apiKey;
@synthesize useSSL          = __useSSL;
@synthesize delegate        = __delegate;

#pragma mark - start notifier
+ (HTNotifier *)startNotifierWithAPIKey:(NSString *)key environmentName:(NSString *)name {
	if (sharedNotifier == nil) {
		
		// validate
		if (![key length]) {
			HTLog(@"The API key must not be blank");
			return nil;
		}
		if (![name length]) {
			HTLog(@"The environment name must not be blank");
			return nil;
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
	}
    return sharedNotifier;
}

#pragma mark - singleton methods
+ (HTNotifier *)sharedNotifier {
	@synchronized(self) {
		return sharedNotifier;
	}
}
+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (sharedNotifier == nil) {
			sharedNotifier = [super allocWithZone:zone];
			return sharedNotifier;
		}
	}
	return nil;
}
- (id)copyWithZone:(NSZone *)zone {
	return self;
}
- (id)retain {
	return self;
}
- (NSUInteger)retainCount {
	return NSUIntegerMax;
}
- (oneway void)release {
	// do nothing
}
- (id)autorelease {
	return self;
}

#pragma mark - memory management
- (void)dealloc {
    
    // stop event sources
	[self unregisterNotifications];
    HTStopHandlers();
    
    // release information
    HTReleaseNoticeInfo();
	if (reachability != NULL) { CFRelease(reachability);reachability = NULL; }
    self.apiKey = nil;
    self.environmentName = nil;
	[__environmentInfo release];
    __environmentInfo = nil;
    
    // super
	[super dealloc];
    
}

#pragma mark - test mechanism
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
        
        // open file
        NSString *name = [[NSProcessInfo processInfo] globallyUniqueString];
        NSString *path = ABNotifierPathForNewNoticeWithName(name);
        int fd = HTOpenFile(HTExceptionNoticeType, [path UTF8String]);
        
        // write file
        if (fd > -1) {
            @try {
                
                // crash info
                NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:5];
                
                // addresses
                NSArray *addresses = [exception callStackReturnAddresses];
                NSArray *symbols = HTCallStackSymbolsFromReturnAddresses(addresses);
                [dictionary setObject:symbols forKey:@"call stack"];
                
                // exception name and reason
                [dictionary setObject:[exception name] forKey:@"exception name"];
                [dictionary setObject:[exception reason] forKey:@"exception reason"];
                
#if TARGET_OS_IPHONE
                
                // view controller
                NSString *viewController = HTCurrentViewController();
                if (viewController != nil) {
                    [dictionary setObject:viewController forKey:@"view controller"];
                }
                
#endif
                
                // environment info
                [self setEnvironmentValue:[[exception userInfo] description] forKey:@"Exception"];
                [dictionary setObject:self.environmentInfo forKey:@"environment info"];
                
                // write data
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
                NSUInteger length = [data length];
                write(fd, &length, sizeof(unsigned long));
                write(fd, [data bytes], length);
                
                // notify delegate on main thread
                if ([self.delegate respondsToSelector:@selector(notifierDidLogException:)]) {
                    [self.delegate
                     performSelectorOnMainThread:@selector(notifierDidLogException:)
                     withObject:exception
                     waitUntilDone:YES];
                }
                
            }
            @catch (NSException *exception) {
                HTLog(@"Encountered an exception while logging an exception");
            }
            @finally {
                close(fd);
            }
        }
    }
}

#pragma mark - environment information accessors
- (void)setEnvironmentValue:(NSString *)valueOrNil forKey:(NSString *)key {
    if (valueOrNil == nil) { [__environmentInfo removeObjectForKey:key]; }
    else { [__environmentInfo setObject:valueOrNil forKey:key]; }
    NSData *environmentData = [NSKeyedArchiver archivedDataWithRootObject:__environmentInfo];
    NSUInteger length = [environmentData length];
    free(ht_notice_info.env_info);
    ht_notice_info.env_info = malloc(length);
    ht_notice_info.env_info_len = length;
    [environmentData getBytes:ht_notice_info.env_info length:length];
}
- (NSString *)environmentValueForKey:(NSString *)key {
    return [self.environmentInfo objectForKey:key];
}

#pragma mark - post notices
- (BOOL)postNotices {
    BOOL value = [self isHoptoadReachable];
    if (value) {
        NSArray *notices = ABNotifierAllNotices();
        if ([notices count]) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:HTNotifierAlwaysSendKey]) {
                [self performSelectorInBackground:@selector(postNoticesWithPaths:) withObject:notices];
            }
            else {
                [self performSelectorOnMainThread:@selector(showNoticeAlert) withObject:nil waitUntilDone:NO];
            }
        }
    }
    return value;
}

#if TARGET_OS_IPHONE
#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if ([self.delegate respondsToSelector:@selector(notifierDidDismissAlert)]) {
		[self.delegate notifierDidDismissAlert];
	}
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSArray *notices = ABNotifierAllNotices();
	if (buttonIndex == alertView.cancelButtonIndex) {
		for (NSString *notice in notices) {
			[[NSFileManager defaultManager]
			 removeItemAtPath:notice
			 error:nil];
		}
	}
    else {
        NSString *button = [alertView buttonTitleAtIndex:buttonIndex];
        if ([button isEqualToString:HTLocalizedString(@"ALWAYS_SEND")]) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HTNotifierAlwaysSendKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        [self performSelectorInBackground:@selector(postNoticesWithPaths:) withObject:notices];
    }
}
#endif

@end
