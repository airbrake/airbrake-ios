//
//  HTNotifier.m
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 10/2/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import "HTNotifier.h"
#import "HTNotifier_iOS.h"
#import "HTNotifier_Mac.h"

// internal
static HTNotifier * sharedNotifier = nil;
static NSString * const HTNotifierHostName = @"hoptoadapp.com";
#define HTNotifierURL [NSURL URLWithString: \
[NSString stringWithFormat: \
@"%@://%@%/notifier_api/v2/notices", \
(self.useSSL) ? @"https" : @"http", \
HTNotifierHostName]]
#define HTIsMultitaskingSupported \
[[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && \
[[UIDevice currentDevice] isMultitaskingSupported]
#define HT_IOS_SDK_4 (TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= 4000)

// extern strings
NSString * const HTNotifierVersion = @"1.3";
NSString * const HTNotifierBundleName = @"${BUNDLE}";
NSString * const HTNotifierBundleVersion  = @"${VERSION}";
NSString * const HTNotifierDevelopmentEnvironment = @"Development";
NSString * const HTNotifierAdHocEnvironment = @"Ad Hoc";
NSString * const HTNotifierAppStoreEnvironment = @"App Store";
NSString * const HTNotifierReleaseEnvironment = @"Release";
NSString * const HTNotifierDirectoryName = @"Hoptoad Notices";
NSString * const HTNotifierPathExtension = @"notice";
NSString * const HTNotifierAlwaysSendKey = @"AlwaysSendCrashReports";

#pragma mark -
#pragma mark private methods
@interface HTNotifier (private)

// methods to be implemented
- (id)initWithAPIKey:(NSString *)key environmentName:(NSString *)name;
- (void)checkForNoticesAndReportIfReachable;
- (void)postAllNoticesWithAutoreleasePool;
- (void)postNoticesWithPaths:(NSArray *)paths;
- (BOOL)isHoptoadReachable;

// methods to be overridden
- (void)showNoticeAlert;
- (void)registerNotifications;
- (void)unregisterNotifications;

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
		apiKey = [key copy];
		environmentName = [HTStringByReplacingHoptoadVariablesInString(name) retain];
		self.useSSL = NO;
		self.environmentInfo = [NSMutableDictionary dictionary];
		
		// register defaults
		[[NSUserDefaults standardUserDefaults] registerDefaults:
		 [NSDictionary dictionaryWithObject:@"NO" forKey:HTNotifierAlwaysSendKey]];
		
		// setup reachability
		reachability = SCNetworkReachabilityCreateWithName(NULL, [HTNotifierHostName UTF8String]);
		
		// notifications
		[self registerNotifications];
		
	}
	return self;
}
- (void)checkForNoticesAndReportIfReachable {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if ([self isHoptoadReachable]) {
		[self performSelectorOnMainThread:@selector(unregisterNotifications) withObject:nil waitUntilDone:YES];
		
		NSArray *notices = HTNotices();
		if ([notices count] > 0) {
			if ([[NSUserDefaults standardUserDefaults] boolForKey:HTNotifierAlwaysSendKey]) {
				[self postNoticesWithPaths:notices];
			}
			else {
				[self performSelectorOnMainThread:@selector(showNoticeAlert) withObject:nil waitUntilDone:YES];
			}
		}
	}
	
	[pool drain];
}
- (void)postAllNoticesWithAutoreleasePool {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *paths = HTNotices();
	[self postNoticesWithPaths:paths];
	
	[pool drain];
}
- (void)postNoticesWithPaths:(NSArray *)paths {

#if HT_IOS_SDK_4
	__block NSUInteger task;
	__block UIApplication *app = [UIApplication sharedApplication];
	__block BOOL shouldKeepPosting = YES;
	if (HTIsMultitaskingSupported) {
		task = [app beginBackgroundTaskWithExpirationHandler:^{
			shouldKeepPosting = NO;
		}];
	}
#endif
	
	// report each notice
	for (NSString *noticePath in paths) {
		
#if HT_IOS_SDK_4
		if (!shouldKeepPosting) {
			break;
		}
#endif
		
		// get notice payload
		HTNotice *notice = [HTNotice readFromFile:noticePath];
		NSData *xmlData = [notice hoptoadXMLData];
		
		// create url request
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:HTNotifierURL];
		[request setTimeoutInterval:10.0];
		[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPMethod:@"POST"];
		[request setHTTPBody:xmlData];
		
		// perform request
		NSHTTPURLResponse *response = nil;
		NSError *error = nil;
		NSData *responseBody = [NSURLConnection sendSynchronousRequest:request
													 returningResponse:&response
																 error:&error];
		
		if (error == nil) {
			[[NSFileManager defaultManager] removeItemAtPath:noticePath error:nil];
		}
		else {
			HTLog(@"encountered error while posting notice\n%@", error);
		}
		
		NSInteger statusCode = [response statusCode];
		if (statusCode == 200) {
			HTLog(@"crash report posted");
		}
		else if (responseBody == nil) {
			HTLog(@"unexpected response\nstatus code:%d", statusCode);
		}
		else {
			NSString *responseString = [[NSString alloc] initWithData:responseBody
															 encoding:NSUTF8StringEncoding];
			HTLog(@"unexpected response\nstatus code:%d\nresponse body:%@",
				  statusCode,
				  responseString);
			[responseString release];
		}
	}
	
#if HT_IOS_SDK_4
	if (HTIsMultitaskingSupported) {
		[app endBackgroundTask:task];
	}
#endif
	
}
- (BOOL)isHoptoadReachable {
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityGetFlags(reachability, &flags);
	return ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
}

- (void)registerNotifications {}
- (void)unregisterNotifications {}
- (void)showNoticeAlert {}

@end

#pragma mark -
#pragma mark public implementation
@implementation HTNotifier

@synthesize apiKey;
@synthesize environmentName;
@synthesize useSSL;
@synthesize environmentInfo;
@synthesize delegate;

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
#if TARGET_OS_IPHONE
		sharedNotifier = [[HTNotifier_iOS alloc] initWithAPIKey:key environmentName:name];
#elif TARGET_OS_MAC
		sharedNotifier = [[HTNotifier_Mac alloc] initWithAPIKey:key environmentName:name];
#endif
		
		// start
		HTStartHandler();
		
		// log
		HTLog(@"Notifier %@ ready to catch errors", HTNotifierVersion);
		HTLog(@"Environment \"%@\"", sharedNotifier.environmentName);
	}
}
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
- (void)dealloc {
	[self unregisterNotifications];
	HTStopHandler();
	
	if (reachability != NULL) { CFRelease(reachability);reachability = NULL; }
	[apiKey release];apiKey = nil;
	[environmentName release];environmentName = nil;
	self.environmentInfo = nil;
	
	[super dealloc];
}
- (void)writeTestNotice {
	NSString *noticePath = HTPathForNewNoticeWithName(@"TEST");
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:noticePath]) {
		return;
	}
	
	HTNotice *notice = [HTNotice testNotice];
	[notice writeToFile:noticePath];
}

@end
