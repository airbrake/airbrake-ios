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
@property (nonatomic, readwrite, copy) NSString *apiKey;
@property (nonatomic, readwrite, copy) NSString *environmentName;
@property (nonatomic, assign) dispatch_queue_t backgroundQueue;
@end

@interface HTNotifier (private)

// init
- (id)initWithAPIKey:(NSString *)key environmentName:(NSString *)name;

// post methods
- (void)postNoticesWithPaths:(NSArray *)paths;
- (void)postNoticeWithContentsOfFile:(NSString *)path toURL:(NSURL *)URL;

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
        self.backgroundQueue = dispatch_queue_create("com.airbrakeapp.BackgroundQueue", nil);
#ifdef DEBUG
        NSString *UDID = [[UIDevice currentDevice] uniqueIdentifier];
        [self
         setEnvironmentValue:UDID
         forKey:@"UDID"];
#endif
		
		// register defaults
		[[NSUserDefaults standardUserDefaults] registerDefaults:
		 [NSDictionary dictionaryWithObject:@"NO" forKey:HTNotifierAlwaysSendKey]];
		
		// setup reachability
        BOOL reachabilityConfigured = NO;
		reachability = SCNetworkReachabilityCreateWithName(NULL, [HTNotifierHostName UTF8String]);
        if (SCNetworkReachabilitySetCallback(reachability, ABNotifierReachabilityDidChange, nil)) {
            if (SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), kCFRunLoopDefaultMode)) {
                reachabilityConfigured = YES;
            }
        }
        if (!reachabilityConfigured) {
            [self release];
            return nil;
        }
        
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
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate notifierWillPostNotices];
        });
    }
    
    // create url
    NSString *URLString = [NSString stringWithFormat:
                           @"%@://%@/notifier_api/v2/notices",
                           (self.useSSL) ? @"https" : @"http",
                           HTNotifierHostName];
    NSURL *URL = [NSURL URLWithString:URLString];
    
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
    
    // notify delegate
    if ([paths count] && [self.delegate respondsToSelector:@selector(notifierDidPostNotices)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate notifierDidPostNotices]; 
        });
    }
    
    // pool
    [pool drain];
	
}
- (void)postNoticeWithContentsOfFile:(NSString *)path toURL:(NSURL *)URL {
    
    // create url request
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	[request setTimeoutInterval:10.0];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPMethod:@"POST"];
    
	// get notice payload
    HTNotice *notice = [HTNotice noticeWithContentsOfFile:path];
    NSData *data = [notice hoptoadXMLData];
    if (data) {
        [request setHTTPBody:data];
#ifdef DEBUG
        HTLog(@"%@", notice);
#endif
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
    
    // show alert
    UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:HTStringByReplacingHoptoadVariablesInString(title)
						  message:HTStringByReplacingHoptoadVariablesInString(body)
						  delegate:self
						  cancelButtonTitle:HTLocalizedString(@"DONT_SEND")
						  otherButtonTitles:HTLocalizedString(@"ALWAYS_SEND"), HTLocalizedString(@"SEND"), nil];
	[alert show];
	[alert release];
    
}
@end

@implementation HTNotifier

@synthesize environmentInfo = __environmentInfo;
@synthesize environmentName = __environmentName;
@synthesize backgroundQueue = __backgroundQueue;
@synthesize apiKey          = __apiKey;
@synthesize useSSL          = __useSSL;
@synthesize delegate        = __delegate;

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

#pragma mark - environment variables
- (void)setEnvironmentValue:(NSString *)valueOrNil forKey:(NSString *)key {
    @synchronized(self) {
        if (valueOrNil == nil) { [__environmentInfo removeObjectForKey:key]; }
        else { [__environmentInfo setObject:valueOrNil forKey:key]; }
        NSData *environmentData = [NSKeyedArchiver archivedDataWithRootObject:__environmentInfo];
        NSUInteger length = [environmentData length];
        free(ht_notice_info.env_info);
        ht_notice_info.env_info = malloc(length);
        ht_notice_info.env_info_len = length;
        [environmentData getBytes:ht_notice_info.env_info length:length];
    }
}
- (NSString *)environmentValueForKey:(NSString *)key {
    NSString *value = nil;
    @synchronized(self) {
        value = [self.environmentInfo objectForKey:key];
    }
    return value;
}

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
                
                // view controller
                NSString *viewController = HTCurrentViewController();
                if (viewController != nil) {
                    [dictionary setObject:viewController forKey:@"view controller"];
                }
                
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
    HTStopHandlers();
    
    // release information
    HTReleaseNoticeInfo();
    self.apiKey = nil;
    self.environmentName = nil;
	[__environmentInfo release];
    __environmentInfo = nil;
    dispatch_release(self.backgroundQueue);
    self.backgroundQueue = nil;
    
    // super
	[super dealloc];
    
}

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

@end

#pragma mark - reachability change
void ABNotifierReachabilityDidChange(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    if (flags & kSCNetworkReachabilityFlagsReachable) {
        SCNetworkReachabilitySetCallback(target, nil, nil);
        SCNetworkReachabilityUnscheduleFromRunLoop(target, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        HTNotifier *notifier = [HTNotifier sharedNotifier];
        dispatch_async([notifier backgroundQueue], ^{
            NSArray *notices = ABNotifierAllNotices();
            if ([notices count]) {
                if ([[NSUserDefaults standardUserDefaults] boolForKey:HTNotifierAlwaysSendKey]) {
                    [notifier postNoticesWithPaths:notices];
                }
                else {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [notifier showNoticeAlert];
                    });
                }
            }
        });
    }
}
