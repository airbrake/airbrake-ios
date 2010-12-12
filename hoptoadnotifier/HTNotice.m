//
//  HTNotice.m
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 10/2/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import "HTNotice.h"
#import "HTUtilities.h"
#import "HTNotifier.h"

#import "DDXML.h"

@implementation HTNotice

@synthesize operatingSystemVersion;
@synthesize applicationVersion;
@synthesize exceptionName;
@synthesize exceptionReason;
@synthesize platform;
@synthesize environmentName;
@synthesize environmentInfo;
@synthesize backtrace;
@synthesize viewControllerName;

#pragma mark -
#pragma mark NSCoder
- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		NSInteger version = [decoder decodeInt32ForKey:@"archive_version"];
		if (version == 1) {
			self.operatingSystemVersion = [decoder decodeObjectForKey:@"os_version"];
			self.applicationVersion = [decoder decodeObjectForKey:@"app_version"];
			self.exceptionName = [decoder decodeObjectForKey:@"exc_name"];
			self.exceptionReason = [decoder decodeObjectForKey:@"exc_reason"];
			self.platform = [decoder decodeObjectForKey:@"platform"];
			self.backtrace = [decoder decodeObjectForKey:@"backtrace"];
			self.environmentName = [decoder decodeObjectForKey:@"env_name"];
			self.environmentInfo = [decoder decodeObjectForKey:@"env_info"];
			self.viewControllerName = [decoder decodeObjectForKey:@"view_controller"];
		}
	}
	return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeInt32:1 forKey:@"archive_version"];
	[encoder encodeObject:self.operatingSystemVersion forKey:@"os_version"];
	[encoder encodeObject:self.applicationVersion forKey:@"app_version"];
	[encoder encodeObject:self.exceptionName forKey:@"exc_name"];
	[encoder encodeObject:self.exceptionReason forKey:@"exc_reason"];
	[encoder encodeObject:self.platform forKey:@"platform"];
	[encoder encodeObject:self.backtrace forKey:@"backtrace"];
	[encoder encodeObject:self.environmentName forKey:@"env_name"];
	[encoder encodeObject:self.environmentInfo forKey:@"env_info"];
	[encoder encodeObject:self.viewControllerName forKey:@"view_controller"];
}

#pragma mark -
#pragma mark class methods
+ (HTNotice *)notice {
	HTNotice *notice = [[HTNotice alloc] init];
	notice.operatingSystemVersion = [HTUtilities operatingSystemVersion];
	notice.platform = [HTUtilities platform];
	notice.applicationVersion = [HTUtilities applicationVersion];
#if TARGET_OS_IPHONE
	notice.viewControllerName = [HTUtilities currentViewController];
#endif
	NSString *envName = [[HTNotifier sharedNotifier] environmentName];
	notice.environmentName = [HTUtilities stringByReplacingHoptoadVariablesInString:envName];
	notice.environmentInfo = [[HTNotifier sharedNotifier] environmentInfo];
	return [notice autorelease];
}
+ (HTNotice *)noticeWithException:(NSException *)exception {
	HTNotice *notice = [HTNotice notice];
	notice.exceptionName = [exception name];
	notice.exceptionReason = [exception reason];
	notice.backtrace = [HTUtilities backtraceWithException:exception];	
	return notice;
}
+ (HTNotice *)testNotice {
	HTNotice *notice = [HTNotice notice];
	notice.exceptionName = @"Test Crash Report";
	notice.exceptionReason = @"-[HTNotifier crash]: unrecognized selector sent to instance 0x59476f0";
	notice.backtrace = [NSArray arrayWithObjects:
						@"0   CoreFoundation                      0x024f98fc __exceptionPreprocess + 156",
						@"1   libobjc.A.dylib                     0x0230e5de objc_exception_throw + 47",
						@"2   CoreFoundation                      0x024fb42b -[NSObject(NSObject) doesNotRecognizeSelector:] + 187",
						@"3   CoreFoundation                      0x0246b116 ___forwarding___ + 966",
						@"4   CoreFoundation                      0x0246acd2 _CF_forwarding_prep_0 + 50",
						@"5   CrashApp                            0x000021ba -[HTNotifier crash] + 48",
						@"6   UIKit                               0x002bee14 -[UIApplication sendAction:to:from:forEvent:] + 119",
						@"7   UIKit                               0x003486c8 -[UIControl sendAction:to:forEvent:] + 67",
						@"8   UIKit                               0x0034ab4a -[UIControl(Internal) _sendActionsForEvents:withEvent:] + 527",
						@"9   UIKit                               0x003496f7 -[UIControl touchesEnded:withEvent:] + 458",
						@"10  UIKit                               0x002e22ff -[UIWindow _sendTouchesForEvent:] + 567",
						@"11  UIKit                               0x002c41ec -[UIApplication sendEvent:] + 447",
						@"12  UIKit                               0x002c8ac4 _UIApplicationHandleEvent + 7495",
						@"13  GraphicsServices                    0x02c00afa PurpleEventCallback + 1578",
						@"14  CoreFoundation                      0x024dadc4 __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE1_PERFORM_FUNCTION__ + 52",
						@"15  CoreFoundation                      0x0243b737 __CFRunLoopDoSource1 + 215",
						@"16  CoreFoundation                      0x024389c3 __CFRunLoopRun + 979",
						@"17  CoreFoundation                      0x02438280 CFRunLoopRunSpecific + 208",
						@"18  CoreFoundation                      0x024381a1 CFRunLoopRunInMode + 97",
						@"19  GraphicsServices                    0x02bff2c8 GSEventRunModal + 217",
						@"20  GraphicsServices                    0x02bff38d GSEventRun + 115",
						@"21  UIKit                               0x002ccb58 UIApplicationMain + 1160",
						@"22  CrashApp                            0x000020a0 main + 102",
						@"23  CrashApp                            0x00002031 start + 53",
						nil];
	return notice;
}
+ (HTNotice *)readFromFile:(NSString *)file {
	return [NSKeyedUnarchiver unarchiveObjectWithFile:file];
}

#pragma mark -
#pragma mark object methods
- (NSString *)hoptoadXMLString {
	DDXMLElement *payload;
	DDXMLElement *e1;
	DDXMLElement *e2;
	DDXMLElement *e3;
	
	// setup payload
	payload = [DDXMLElement elementWithName:@"notice"];
	[payload addAttribute:[DDXMLElement attributeWithName:@"version" stringValue:@"2.0"]];
	
	// set api key
	NSString *apiKey = [[HTNotifier sharedNotifier] apiKey];
	e1 = [DDXMLElement elementWithName:@"api-key" stringValue:(apiKey == nil) ? @"" : apiKey];
	[payload addChild:e1];
	
	// set notifier information
	e1 = [DDXMLElement elementWithName:@"notifier"];
#if TARGET_OS_IPHONE
	[e1 addChild:[DDXMLElement elementWithName:@"name" stringValue:@"Hoptoad iOS Notifier"]];
	[e1 addChild:[DDXMLElement elementWithName:@"url" stringValue:@"http://github.com/guicocoa/hoptoad-ios"]];
#else
	[e1 addChild:[DDXMLElement elementWithName:@"name" stringValue:@"Hoptoad Mac Notifier"]];
	[e1 addChild:[DDXMLElement elementWithName:@"url" stringValue:@"http://github.com/guicocoa/hoptoad-mac"]];
#endif
	[e1 addChild:[DDXMLElement elementWithName:@"version" stringValue:HTNotifierVersion]];
	[payload addChild:e1];
	
	// set error information
	e1 = [DDXMLElement elementWithName:@"error"];
	[e1 addChild:[DDXMLElement elementWithName:@"class" stringValue:self.exceptionName]];
	NSString *reason = [NSString stringWithFormat:@"%@: %@", self.exceptionName, self.exceptionReason];
	[e1 addChild:[DDXMLElement elementWithName:@"message" stringValue:reason]];
	e2 = [DDXMLElement elementWithName:@"backtrace"];
	NSCharacterSet *whiteSpaceCharSet = [NSCharacterSet whitespaceCharacterSet];
	NSCharacterSet *alphabetCharSet = [NSCharacterSet alphanumericCharacterSet];
	NSCharacterSet *newLineCharSet = [NSCharacterSet newlineCharacterSet];
	for (NSString *line in self.backtrace) {
		DDXMLElement *lineElement = [DDXMLElement elementWithName:@"line"];
		NSString *scanString;
		NSScanner *scanner = [NSScanner scannerWithString:line];
		[scanner scanUpToCharactersFromSet:whiteSpaceCharSet intoString:&scanString];
		[lineElement addAttribute:[DDXMLElement attributeWithName:@"number" stringValue:scanString]];
		[scanner scanUpToCharactersFromSet:alphabetCharSet intoString:nil];
		[scanner scanUpToCharactersFromSet:whiteSpaceCharSet intoString:&scanString];
		[lineElement addAttribute:[DDXMLElement attributeWithName:@"file" stringValue:scanString]];
		[scanner scanUpToCharactersFromSet:alphabetCharSet intoString:nil];
		[scanner scanUpToCharactersFromSet:newLineCharSet intoString:&scanString];
		[lineElement addAttribute:[DDXMLElement attributeWithName:@"method" stringValue:scanString]]; 
		[e2 addChild:lineElement];
	}
	[e1 addChild:e2];
	[payload addChild:e1];
	
	// set request info
	e1 = [DDXMLElement elementWithName:@"request"];
	[e1 addChild:[DDXMLElement elementWithName:@"url"]];
	e2 = [DDXMLElement elementWithName:@"component"];
	[e2 setStringValue:self.viewControllerName];
	[e1 addChild:e2];
	[e1 addChild:[DDXMLElement elementWithName:@"action"]];
	e2 = [DDXMLElement elementWithName:@"cgi-data"];
	NSMutableDictionary *cgiData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									self.platform, @"Device",
									self.applicationVersion, @"App Version",
									self.operatingSystemVersion, @"Operating System",
									nil];
	[cgiData addEntriesFromDictionary:self.environmentInfo];
	for (NSString *key in [cgiData allKeys]) {
		id var = [cgiData objectForKey:key];
		e3 = [DDXMLElement elementWithName:@"var" stringValue:[var description]];
		[e3 addAttribute:[DDXMLElement attributeWithName:@"key" stringValue:key]];
		[e2 addChild:e3];
	}
	[e1 addChild:e2];
	[payload addChild:e1];
	
	// set server environment
	e1 = [DDXMLElement elementWithName:@"server-environment"];
	[e1 addChild:[DDXMLElement elementWithName:@"environment-name" stringValue:self.environmentName]];
	[payload addChild:e1];
	
	return [payload XMLString];
}
- (NSData *)hoptoadXMLData {
	return [[self hoptoadXMLString] dataUsingEncoding:NSUTF8StringEncoding];
}
- (void)writeToFile:(NSString *)file {
	[NSKeyedArchiver archiveRootObject:self toFile:file];
}

@end
