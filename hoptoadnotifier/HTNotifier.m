//
//  HTNotifier.m
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 10/2/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import "HTNotifier.h"
#import "HTNotice.h"
#import "HTFunctions.h"

// internal
void ht_handle_exception(NSException *);
static HTNotifier *sharedNotifier = nil;
static NSString *HTNotifierHostName = @"hoptoadapp.com";
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
NSString *HTNotifierVersion = @"2.2 Beta";
NSString *HTNotifierBundleName = @"${BUNDLE}";
NSString *HTNotifierBundleVersion  = @"${VERSION}";
NSString *HTNotifierDevelopmentEnvironment = @"Development";
NSString *HTNotifierAdHocEnvironment = @"Ad Hoc";
NSString *HTNotifierAppStoreEnvironment = @"App Store";
NSString *HTNotifierReleaseEnvironment = @"Release";
NSString *HTNotifierAlwaysSendKey = @"AlwaysSendCrashReports";

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
		NSString *directory = HTNoticesDirectory();
		if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
			[[NSFileManager defaultManager]
			 createDirectoryAtPath:directory
			 withIntermediateDirectories:YES
			 attributes:nil
			 error:nil];
		}
		
		// setup values
		_apiKey = [key copy];
		_environmentName = [HTStringByReplacingHoptoadVariablesInString(name) retain];
		_environmentInfo = [[NSMutableDictionary alloc] init];
		self.useSSL = NO;
#if TARGET_OS_IPHONE && DEBUG
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
	
}
- (void)postNoticeWithPath:(NSString *)path {
    
    // pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // create url request
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:HTNotifierURL];
	[request setTimeoutInterval:10.0];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPMethod:@"POST"];
    
	// get notice payload
    @try {
        HTNotice *notice = [HTNotice noticeWithContentsOfFile:path];
        NSData *data = [notice hoptoadXMLData];
        if (data == nil) {
            [NSException
             raise:NSInternalInconsistencyException
             format:@"[Hoptoad] unable to read notice at %@", path];
        }
        else {
            [request setHTTPBody:data];
#ifdef DEBUG
            HTLog(@"%@", notice);
#endif
        }

    }
    @catch (NSException *exception) {
        HTLog(@"%@", exception);
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        [pool drain];
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
		NSString *responseString = [[NSString alloc] initWithData:responseBody
														 encoding:NSUTF8StringEncoding];
		HTLog(@"unexpected response\nstatus code:%ld\nresponse body:%@", (long)statusCode, responseString);
		[responseString release];
	}
    
    // pool
    [pool drain];
    
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
	NSAlert *alert = [NSAlert alertWithMessageText:HTStringByReplacingHoptoadVariablesInString(title)
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

@synthesize environmentInfo=_environmentInfo;
@synthesize environmentName=_environmentName;
@synthesize apiKey=_apiKey;
@synthesize useSSL=_useSSL;
@synthesize delegate=_delegate;

#pragma mark - start notifier
+ (void)startNotifierWithAPIKey:(NSString *)key environmentName:(NSString *)name {
	if (sharedNotifier == nil) {
		
		// validate
		if (key == nil || [key length] == 0) {
			HTLog(@"The provided API key is not valid");
			return;
		}
		if (name == nil || [name length] == 0) {
			HTLog(@"The provided environment name is not valid");
			return;
		}
        
        // create
        sharedNotifier = [[HTNotifier alloc] initWithAPIKey:key environmentName:name];
		
		// log
        if (sharedNotifier) {
            HTLog(@"Notifier %@ ready to catch errors", HTNotifierVersion);
            HTLog(@"Environment \"%@\"", name);
        }
	}
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
- (void)release {
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
	[_apiKey release];_apiKey = nil;
	[_environmentName release];_environmentName = nil;
	[_environmentInfo release];_environmentInfo = nil;
    
    // super
	[super dealloc];
    
}

#pragma mark - test mechanism
- (void)writeTestNotice {
    NSString *testPath = [HTNoticesDirectory() stringByAppendingPathComponent:@"TEST"];
    testPath = [testPath stringByAppendingPathExtension:HTNoticePathExtension];
	if ([[NSFileManager defaultManager] fileExistsAtPath:testPath]) { return; }
	@try {
        NSArray *array = [NSArray array];
        [array objectAtIndex:NSUIntegerMax];
    }
	@catch (NSException *e) { ht_handle_exception(e); }
	NSString *noticePath = [NSString stringWithUTF8String:ht_notice_info.notice_path];
	[[NSFileManager defaultManager] moveItemAtPath:noticePath toPath:testPath error:nil];
}

#pragma mark - environment information accessors
- (void)setEnvironmentValue:(NSString *)valueOrNil forKey:(NSString *)key {
    if (valueOrNil == nil) { [_environmentInfo removeObjectForKey:key]; }
    else { [_environmentInfo setObject:valueOrNil forKey:key]; }
    NSData *environmentData = [NSKeyedArchiver archivedDataWithRootObject:_environmentInfo];
    NSUInteger length = [environmentData length];
    free(ht_notice_info.env_info);
    ht_notice_info.env_info = malloc(length);
    ht_notice_info.env_info_len = length;
    [environmentData getBytes:ht_notice_info.env_info length:length];
}
- (NSString *)environmentValueForKey:(NSString *)key {
    return [_environmentInfo objectForKey:key];
}

#pragma mark - post notices
- (BOOL)postNotices {
    BOOL value = [self isHoptoadReachable];
    if (value) {
        NSArray *notices = HTNotices();
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
    NSArray *notices = HTNotices();
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
