//
//  HTNotice.m
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 10/2/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import "HTNotifier.h"

#import "DDXML.h"

int HTNoticeFileVersion = 1;
int HTSignalNoticeType = 1;
int HTExceptionNoticeType = 2;

@implementation HTNotice

@synthesize operatingSystem=_operatingSystem;
@synthesize applicationVersion=_applicationVersion;
@synthesize exceptionName=_exceptionName;
@synthesize exceptionReason=_exceptionReason;
@synthesize platform=_platform;
@synthesize environmentName=_environmentName;
@synthesize environmentInfo=_environmentInfo;
@synthesize callStack=_callStack;
@synthesize viewControllerName=_viewControllerName;

#pragma mark - factory method to create notice
+ (HTNotice *)noticeWithContentsOfFile:(NSString *)path {
	NSString *extension = [path pathExtension];
    if (![extension isEqualToString:HTNotifierNoticePathExtension]) {
        return nil;
    }
	
	HTNotice *notice = [[HTNotice alloc] init];
	
	// stuff
	NSData *data = [NSData dataWithContentsOfFile:path];
	NSUInteger location = 0;
	NSUInteger length = 0;
	
	// get version
    int version;
    [data getBytes:&version range:NSMakeRange(location, sizeof(int))];
    location += sizeof(int);
    
    // get type
    int type;
    [data getBytes:&type range:NSMakeRange(location, sizeof(int))];
    location += sizeof(int);
    
    // os version
    [data getBytes:&length range:NSMakeRange(location, sizeof(unsigned long))];
    location += sizeof(unsigned long);
	if (length > 0) {
		char * value_str = malloc(length * sizeof(char));
		[data getBytes:value_str range:NSMakeRange(location, length)];
		location += length;
		notice.operatingSystem = [NSString stringWithUTF8String:value_str];
		free(value_str);
	}
    
    // platform
    [data getBytes:&length range:NSMakeRange(location, sizeof(unsigned long))];
    location += sizeof(unsigned long);
	if (length > 0) {
		char * value_str = malloc(length * sizeof(char));
		[data getBytes:value_str range:NSMakeRange(location, length)];
		location += length;
		notice.platform = [NSString stringWithUTF8String:value_str];
		free(value_str);
	}
    
    // app version
    [data getBytes:&length range:NSMakeRange(location, sizeof(unsigned long))];
    location += sizeof(unsigned long);
	if (length > 0) {
		char * value_str = malloc(length * sizeof(char));
		[data getBytes:value_str range:NSMakeRange(location, length)];
		location += length;
		notice.applicationVersion = [NSString stringWithUTF8String:value_str];
		free(value_str);
	}
    
    // environment
    [data getBytes:&length range:NSMakeRange(location, sizeof(unsigned long))];
    location += sizeof(unsigned long);
	if (length > 0) {
		char * value_str = malloc(length * sizeof(char));
		[data getBytes:value_str range:NSMakeRange(location, length)];
		location += length;
		notice.environmentName = [NSString stringWithUTF8String:value_str];
		free(value_str);
	}
	
	if (type == HTSignalNoticeType) {
		
		// signal
        int signal;
        [data getBytes:&signal range:NSMakeRange(location, sizeof(int))];
        location += sizeof(int);
		
		// exception name and reason
		notice.exceptionName = [NSString stringWithUTF8String:strsignal(signal)];
		notice.exceptionReason = @"Application recieved signal";
		
		// call stack
		NSUInteger i = location;
		length = [data length];
		const char * bytes = [data bytes];
		NSMutableArray *array = [NSMutableArray array];
		while (i < length) {
			if (bytes[i] == '\0') {
				NSData *line = [data subdataWithRange:NSMakeRange(location, i - location)];
				NSString *lineString = [[NSString alloc]
										initWithBytes:[line bytes]
										length:[line length]
										encoding:NSUTF8StringEncoding];
				[array addObject:lineString];
				[lineString release];
				if (i + 1 < length && bytes[i + 1] == '\n') { i += 2; }
				else { i++; }
				location = i;
			}
			else { i++; }
		}
		notice.callStack = array;
		
    }
	else if (type == HTExceptionNoticeType) {
        
		// get dictionary
		[data getBytes:&length range:NSMakeRange(location, sizeof(unsigned long))];
		location += sizeof(unsigned long);
		NSData *subdata = [data subdataWithRange:NSMakeRange(location, length)];
		location += length;
		NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:subdata];
		notice.environmentInfo = [dictionary objectForKey:@"environment info"];
		notice.exceptionName = [dictionary objectForKey:@"exception name"];
		notice.exceptionReason = [dictionary objectForKey:@"exception reason"];
		notice.callStack = [dictionary objectForKey:@"call stack"];
		notice.viewControllerName = [dictionary objectForKey:@"view controller"];
        
    }
	
	return [notice autorelease];
}

#pragma mark - class methods
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
						@"5   CrashPhone                          0x000021ba -[HTNotifier crash] + 48",
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
						@"22  CrashPhone                          0x000020a0 main + 102",
						@"23  CrashPhone                          0x00002031 start + 53",
						nil];
	return notice;
}
+ (HTNotice *)readFromFile:(NSString *)file {
	return [NSKeyedUnarchiver unarchiveObjectWithFile:file];
}

#pragma mark - object methods
- (NSString *)hoptoadXMLString {
	
	// setup elements
	DDXMLElement *e1;
	DDXMLElement *e2;
	DDXMLElement *e3;
	DDXMLElement *root = [DDXMLElement elementWithName:@"notice"];;
	[root addAttribute:[DDXMLElement attributeWithName:@"version" stringValue:@"2.0"]];
	
	// set api key
	NSString *apiKey = [[HTNotifier sharedNotifier] apiKey];
	e1 = [DDXMLElement elementWithName:@"api-key" stringValue:(apiKey == nil) ? @"" : apiKey];
	[root addChild:e1];
	
	// set notifier information
	e1 = [DDXMLElement elementWithName:@"notifier"];
#if TARGET_OS_IPHONE
	[e1 addChild:[DDXMLElement elementWithName:@"name" stringValue:@"Hoptoad iOS Notifier"]];
#else
	[e1 addChild:[DDXMLElement elementWithName:@"name" stringValue:@"Hoptoad Mac Notifier"]];
#endif
	[e1 addChild:[DDXMLElement elementWithName:@"url" stringValue:@"http://github.com/guicocoa/hoptoad-ios"]];
	[e1 addChild:[DDXMLElement elementWithName:@"version" stringValue:HTNotifierVersion]];
	[root addChild:e1];
	
	// set error information
	NSString *message = [NSString stringWithFormat:@"%@: %@", self.exceptionName, self.exceptionReason];
	e1 = [DDXMLElement elementWithName:@"error"];
	[e1 addChild:[DDXMLElement elementWithName:@"class" stringValue:self.exceptionName]];
	[e1 addChild:[DDXMLElement elementWithName:@"message" stringValue:message]];
	e2 = [DDXMLElement elementWithName:@"backtrace"];
	NSArray *stack = HTParseCallstack(self.callStack);
	for (NSDictionary *line in stack) {
		e3 = [DDXMLElement elementWithName:@"line"];
		[e3 addAttribute:
		 [DDXMLElement attributeWithName:@"number" stringValue:
		  [[line objectForKey:@"number"] stringValue]]];
		[e3 addAttribute:
		 [DDXMLElement attributeWithName:@"file" stringValue:
		  [line objectForKey:@"file"]]];
		[e3 addAttribute:
		 [DDXMLElement attributeWithName:@"method" stringValue:
		  [line objectForKey:@"method"]]];
		[e2 addChild:e3];
	}
	[e1 addChild:e2];
	[root addChild:e1];
	
	// set request info
	e1 = [DDXMLElement elementWithName:@"request"];
	[e1 addChild:[DDXMLElement elementWithName:@"url"]];
	e2 = [DDXMLElement elementWithName:@"component"];
	[e2 setStringValue:self.viewControllerName];
	[e1 addChild:e2];
	e2 = [DDXMLElement elementWithName:@"action"];
	[e2 setStringValue:HTActionFromCallstack(stack)];
	[e1 addChild:e2];
	e2 = [DDXMLElement elementWithName:@"cgi-data"];
	for (id key in [self.environmentInfo allKeys]) {
		id var = [self.environmentInfo objectForKey:key];
		e3 = [DDXMLElement elementWithName:@"var" stringValue:[var description]];
		[e3 addAttribute:[DDXMLElement attributeWithName:@"key" stringValue:[key description]]];
		[e2 addChild:e3];
	}
	[e1 addChild:e2];
	[root addChild:e1];
	
	// set server environment
	e1 = [DDXMLElement elementWithName:@"server-environment"];
	[e1 addChild:[DDXMLElement elementWithName:@"environment-name" stringValue:self.environmentName]];
	[root addChild:e1];
	
	// return
	return [root XMLString];
}
- (NSData *)hoptoadXMLData {
	return [[self hoptoadXMLString] dataUsingEncoding:NSUTF8StringEncoding];
}
- (void)dealloc {
	self.operatingSystem = nil;
	self.applicationVersion = nil;
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
