//
//  HTNotifier.m
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 10/2/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import "HTNotifier.h"

#define HTLocalizedString(key) NSLocalizedStringFromTable((key), @"HTNotifier", @"")
#define HTNotifierURL [NSString stringWithFormat:@"%@://%@%/notifier_api/v2/notices", \
(self.useSSL) ? @"https" : @"http", \
HTNotifierHostName]

// internal variables
static NSString * const HTNotifierAlwaysSendKey = @"AlwaysSendCrashReports";
static NSString * const HTNotifierHostName = @"hoptoadapp.com";
static HTNotifier * sharedNotifier = nil;

// extern strings
NSString * const HTNotifierVersion = @"2.0";
NSString * const HTNotifierBundleName = @"${BUNDLE}";
NSString * const HTNotifierBuildDate = @"${DATE}";
NSString * const HTNotifierBuildTime = @"${TIME}";
NSString * const HTNotifierBundleVersion  = @"${VERSION}";
NSString * const HTNotifierDevelopmentEnvironment = @"Development";
NSString * const HTNotifierAdHocEnvironment = @"Ad Hoc";
NSString * const HTNotifierAppStoreEnvironment = @"App Store";
NSString * const HTNotifierDirectoryName = @"Hoptoad Notices";
NSString * const HTNotifierPathExtension = @"notice";

#pragma mark -
#pragma mark private methods
@interface HTNotifier (private)
- (id)initWithAPIKey:(NSString *)key environmentName:(NSString *)name;
- (void)applicationDidBecomeActive:(NSNotification *)notif;
- (void)checkForNoticesAndReportIfReachable;
- (void)showNoticeAlert;
- (void)postAllNoticesWithAutoreleasePool;
- (void)postNoticesWithPaths:(NSArray *)paths;
- (BOOL)isHoptoadReachable;
- (void)unregisterNotifications;
@end
@implementation HTNotifier (private)
- (id)initWithAPIKey:(NSString *)key environmentName:(NSString *)name {
	if (self = [super init]) {
		
		// create folder
		NSString *directory = HTNoticesDirectory();
		if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
			[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
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
		
		// register for application notifications
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationDidBecomeActive:)
													 name:UIApplicationDidBecomeActiveNotification
												   object:nil];
		
		// start handler
		HTStartHandler();
		
		// log start statement
		HTLog(@"Notifier %@ ready to catch errors", HTNotifierVersion);
		HTLog(@"Environment \"%@\"", environmentName);
		
	}
	return self;
}
- (void)applicationDidBecomeActive:(NSNotification *)notif {
	[self performSelectorInBackground:@selector(checkForNoticesAndReportIfReachable) withObject:nil];
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
- (void)showNoticeAlert {
	if ([self.delegate respondsToSelector:@selector(notifierWillDisplayAlert)]) {
		[self.delegate notifierWillDisplayAlert];
	}
	
	NSString *title = HTLocalizedString(@"NOTICE_TITLE");
	if ([self.delegate respondsToSelector:@selector(titleForNoticeAlert)]) {
		NSString *tempString = [self.delegate titleForNoticeAlert];
		if (tempString != nil) {
			title = tempString;
		}
	}
	
	NSString *body = HTLocalizedString(@"NOTICE_BODY");
	if ([self.delegate respondsToSelector:@selector(bodyForNoticeAlert)]) {
		NSString *tempString = [self.delegate bodyForNoticeAlert];
		if (tempString != nil) {
			body = tempString;
		}
	}
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:HTStringByReplacingHoptoadVariablesInString(title)
													message:HTStringByReplacingHoptoadVariablesInString(body)
												   delegate:self
										  cancelButtonTitle:HTLocalizedString(@"DONT_SEND")
										  otherButtonTitles:HTLocalizedString(@"ALWAYS_SEND"), HTLocalizedString(@"SEND"), nil];
	[alert show];
	[alert release];
}
- (void)postAllNoticesWithAutoreleasePool {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *paths = HTNotices();
	[self postNoticesWithPaths:paths];
	
	[pool drain];
}
- (void)postNoticesWithPaths:(NSArray *)paths {
	// setup post resources
	NSURL *url = [NSURL URLWithString:HTNotifierURL];
	
	// report each notice
	for (NSString *noticePath in paths) {
		
		// get notice payload
		HTNotice *notice = [HTNotice readFromFile:noticePath];
		NSData *xmlData = [notice hoptoadXMLData];
		
		// create url request
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url
																	cachePolicy:NSURLCacheStorageNotAllowed
																timeoutInterval:10.0];
		[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPMethod:@"POST"];
		[request setHTTPBody:xmlData];
		
		// perform request
		NSHTTPURLResponse *response = nil;
		NSError *error = nil;
		NSData *responseBody = [NSURLConnection sendSynchronousRequest:request
													 returningResponse:&response
																 error:&error];
		NSInteger statusCode = [response statusCode];
		
		if (error == nil) {
			[[NSFileManager defaultManager] removeItemAtPath:noticePath error:nil];
		}
		else {
			HTLog(@"encountered error while posting notice\n%@", error);
		}
		
		// all went well
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
		
		// clean up
		[request release];
	}
}
- (BOOL)isHoptoadReachable {
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityGetFlags(reachability, &flags);
	return ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
}
- (void)unregisterNotifications {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIApplicationDidBecomeActiveNotification
												  object:nil];
}
@end

#pragma mark -
#pragma mark public implementation
@implementation HTNotifier

@synthesize apiKey;
@synthesize environmentName;
@synthesize useSSL;
@synthesize environmentInfo;
@synthesize delegate;
@synthesize logCrashesInSimulator;

+ (void)startNotifierWithAPIKey:(NSString *)key environmentName:(NSString *)name {
	if (sharedNotifier == nil) {
		if (key == nil || [key length] == 0) {
			[NSException raise:NSInvalidArgumentException
						format:@"%@", HTLogStringWithFormat(@"The provided API key is not valid")];
			return;
		}
		
		if (name == nil || [name length] == 0) {
			[NSException raise:NSInvalidArgumentException
						format:@"%@", HTLogStringWithFormat(@"The provided environment name is not valid")];
			return;
		}
		
		sharedNotifier = [[self alloc] initWithAPIKey:key environmentName:name];
	}
}
+ (HTNotifier *)sharedNotifier {
	@synchronized(self) {
		return sharedNotifier;
	}
}
+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if(sharedNotifier == nil) {
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
	
	if (reachability != NULL) { CFRelease(reachability), reachability = NULL; }
	[apiKey release], apiKey = nil;
	[environmentName release], environmentName = nil;
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
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if ([self.delegate respondsToSelector:@selector(notifierDidDismissAlert)]) {
		[self.delegate notifierDidDismissAlert];
	}
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *button = [alertView buttonTitleAtIndex:buttonIndex];
	
	if (buttonIndex == alertView.cancelButtonIndex) {
		NSArray *noticePaths = HTNotices();
		for (NSString *notice in noticePaths) {
			[[NSFileManager defaultManager] removeItemAtPath:notice
													   error:nil];
		}
	}
	else if ([button isEqualToString:HTLocalizedString(@"ALWAYS_SEND")]) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:HTNotifierAlwaysSendKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[self performSelectorInBackground:@selector(postAllNoticesWithAutoreleasePool) withObject:nil];
	}
	else if ([button isEqualToString:HTLocalizedString(@"SEND")]) {
		[self performSelectorInBackground:@selector(postAllNoticesWithAutoreleasePool) withObject:nil];
	}
}

@end
