//
//  HTNotice.m
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 10/2/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import "HTNotifier.h"

#import "DDXML.h"

@implementation HTNotice

@synthesize operatingSystemVersion;
@synthesize applicationVersion;
@synthesize executableName;
@synthesize exceptionName;
@synthesize exceptionReason;
@synthesize platform;
@synthesize environmentName;
@synthesize environmentInfo;
@synthesize callStack;
@synthesize viewControllerName;

#pragma mark -
#pragma mark NSCoder
- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		NSInteger version = [decoder decodeInt32ForKey:@"archive_version"];
		if (version >= 1) {
			self.operatingSystemVersion = [decoder decodeObjectForKey:@"os_version"];
			self.applicationVersion = [decoder decodeObjectForKey:@"app_version"];
			self.exceptionName = [decoder decodeObjectForKey:@"exc_name"];
			self.exceptionReason = [decoder decodeObjectForKey:@"exc_reason"];
			self.platform = [decoder decodeObjectForKey:@"platform"];
			self.callStack = [decoder decodeObjectForKey:@"backtrace"];
			self.environmentName = [decoder decodeObjectForKey:@"env_name"];
			self.environmentInfo = [decoder decodeObjectForKey:@"env_info"];
			self.viewControllerName = [decoder decodeObjectForKey:@"view_controller"];
		}
		if (version >= 2) {
			self.executableName = [decoder decodeObjectForKey:@"executable"];
		}
	}
	return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeInt32:2 forKey:@"archive_version"];
	[encoder encodeObject:self.operatingSystemVersion forKey:@"os_version"];
	[encoder encodeObject:self.applicationVersion forKey:@"app_version"];
	[encoder encodeObject:self.exceptionName forKey:@"exc_name"];
	[encoder encodeObject:self.exceptionReason forKey:@"exc_reason"];
	[encoder encodeObject:self.platform forKey:@"platform"];
	[encoder encodeObject:self.callStack forKey:@"backtrace"];
	[encoder encodeObject:self.environmentName forKey:@"env_name"];
	[encoder encodeObject:self.environmentInfo forKey:@"env_info"];
	[encoder encodeObject:self.viewControllerName forKey:@"view_controller"];
	[encoder encodeObject:self.executableName forKey:@"executable"];
}

#pragma mark -
#pragma mark class methods
+ (HTNotice *)notice {
	HTNotice *notice = [[HTNotice alloc] init];
	notice.operatingSystemVersion = HTOperatingSystemVersion();
	notice.platform = HTPlatform();
	notice.applicationVersion = HTApplicationVersion();
	notice.executableName = HTExecutableName();
#if TARGET_OS_IPHONE
	notice.viewControllerName = HTCurrentViewController();
#endif
	NSString *envName = [[HTNotifier sharedNotifier] environmentName];
	notice.environmentName = HTStringByReplacingHoptoadVariablesInString(envName);
	notice.environmentInfo = [[HTNotifier sharedNotifier] environmentInfo];
	return [notice autorelease];
}
+ (HTNotice *)noticeWithException:(NSException *)exception {
	HTNotice *notice = [HTNotice notice];
	notice.exceptionName = [exception name];
	notice.exceptionReason = [exception reason];
	NSArray *addresses = [exception callStackReturnAddresses];
	notice.callStack = HTCallStackSymbolsFromReturnAddresses(addresses);
	return notice;
}
+ (HTNotice *)testNotice {
	HTNotice *notice = [HTNotice notice];
	notice.exceptionName = @"Test Crash Report";
	notice.exceptionReason = @"-[HTNotifier crash]: unrecognized selector sent to instance 0x59476f0";
	notice.callStack = [NSArray arrayWithObjects:
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
	[e1 addChild:[DDXMLElement elementWithName:@"url" stringValue:@"http://github.com/guicocoa/hoptoad-ios"]];
#endif
	[e1 addChild:[DDXMLElement elementWithName:@"version" stringValue:HTNotifierVersion]];
	[payload addChild:e1];
	
	// set error information
	e1 = [DDXMLElement elementWithName:@"error"];
	[e1 addChild:[DDXMLElement elementWithName:@"class" stringValue:self.exceptionName]];
	NSString *reason = [NSString stringWithFormat:@"%@: %@", self.exceptionName, self.exceptionReason];
	[e1 addChild:[DDXMLElement elementWithName:@"message" stringValue:reason]];
	e2 = [DDXMLElement elementWithName:@"backtrace"];
	NSCharacterSet *whiteSpaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
	NSCharacterSet *nonWhiteSpaceCharacterSet = [whiteSpaceCharacterSet invertedSet];
	for (NSString *line in self.callStack) {
		
		DDXMLElement *lineElement = [DDXMLElement elementWithName:@"line"];
		NSScanner *scanner = [NSScanner scannerWithString:line];
		NSString *string;
		
		// line number
		[scanner scanCharactersFromSet:nonWhiteSpaceCharacterSet intoString:&string];
		[lineElement addAttribute:[DDXMLElement attributeWithName:@"number" stringValue:string]];
		
		// binary name
		[scanner scanCharactersFromSet:nonWhiteSpaceCharacterSet intoString:&string];
		[lineElement addAttribute:[DDXMLElement attributeWithName:@"file" stringValue:string]];
		
		// eat that weird hex number
		[scanner scanCharactersFromSet:nonWhiteSpaceCharacterSet intoString:NULL];
		
		// method
		NSUInteger startLocation = [scanner scanLocation] + 1;
		NSUInteger endLocation = [line rangeOfString:@" +" options:NSBackwardsSearch].location;
		NSRange methodRange = NSMakeRange(startLocation, endLocation - startLocation);
		string = [line substringWithRange:methodRange];
		[lineElement addAttribute:[DDXMLElement attributeWithName:@"method" stringValue:string]];
		
		// save line
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
	NSMutableDictionary *cgi = [NSMutableDictionary dictionaryWithDictionary:self.environmentInfo];
	if (self.platform != nil) { [cgi setObject:self.platform forKey:@"Device"]; }
	if (self.applicationVersion != nil) { [cgi setObject:self.applicationVersion forKey:@"App Version"]; }
	if (self.operatingSystemVersion != nil) { [cgi setObject:self.operatingSystemVersion forKey:@"Operating System"]; }
	if (self.executableName != nil) { [cgi setObject:self.executableName forKey:@"Executable"]; }
	for (id key in [cgi allKeys]) {
		id var = [cgi objectForKey:key];
		e3 = [DDXMLElement elementWithName:@"var" stringValue:[var description]];
		[e3 addAttribute:[DDXMLElement attributeWithName:@"key" stringValue:[key description]]];
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
- (void)dealloc {
	self.operatingSystemVersion = nil;
	self.applicationVersion = nil;
	self.executableName = nil;
	self.exceptionName = nil;
	self.exceptionReason = nil;
	self.platform = nil;
	self.environmentName = nil;
	self.environmentInfo = nil;
	self.callStack = nil;
	self.viewControllerName = nil;
	
	[super dealloc];
}

@end
