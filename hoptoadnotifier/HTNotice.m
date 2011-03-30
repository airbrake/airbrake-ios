//
//  HTNotice.m
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 10/2/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import <objc/runtime.h>
#import <TargetConditionals.h>

#import "HTNotice.h"
#import "HTNotifier.h"
#import "HTFunctions.h"

#import "DDXML.h"

NSString *HTNoticePathExtension = @"htnotice";
int HTNoticeFileVersion = 2;
int HTSignalNoticeType = 1;
int HTExceptionNoticeType = 2;

@implementation HTNotice

@synthesize exceptionName=_exceptionName;
@synthesize exceptionReason=_exceptionReason;
@synthesize environmentName=_environmentName;
@synthesize environmentInfo=_environmentInfo;
@synthesize callStack=_callStack;
@synthesize viewControllerName=_viewControllerName;

#pragma mark - factory method to create notice
+ (HTNotice *)noticeWithContentsOfFile:(NSString *)path {
	NSString *extension = [path pathExtension];
    if (![extension isEqualToString:HTNoticePathExtension]) {
        return nil;
    }
	
	HTNotice *notice = [[HTNotice alloc] init];
	NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:3];
	
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
		[info setObject:[NSString stringWithUTF8String:value_str] forKey:@"Operating System"];
		free(value_str);
	}
    
    // platform
    [data getBytes:&length range:NSMakeRange(location, sizeof(unsigned long))];
    location += sizeof(unsigned long);
	if (length > 0) {
		char * value_str = malloc(length * sizeof(char));
		[data getBytes:value_str range:NSMakeRange(location, length)];
		location += length;
		[info setObject:[NSString stringWithUTF8String:value_str] forKey:@"Device"];
		free(value_str);
	}
    
    // app version
    [data getBytes:&length range:NSMakeRange(location, sizeof(unsigned long))];
    location += sizeof(unsigned long);
	if (length > 0) {
		char * value_str = malloc(length * sizeof(char));
		[data getBytes:value_str range:NSMakeRange(location, length)];
		location += length;
		[info setObject:[NSString stringWithUTF8String:value_str] forKey:@"App Version"];
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
    
    // git hash
    if (version >= 2) {
        [data getBytes:&length range:NSMakeRange(location, sizeof(unsigned long))];
        location += sizeof(unsigned long);
        if (length > 0) {
            char * value_str = malloc(length * sizeof(char));
            [data getBytes:value_str range:NSMakeRange(location, length)];
            location += length;
            [info setObject:[NSString stringWithUTF8String:value_str] forKey:@"Git Commit"];
            free(value_str);
        }
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
		[info addEntriesFromDictionary:[dictionary objectForKey:@"environment info"]];
		notice.exceptionName = [dictionary objectForKey:@"exception name"];
		notice.exceptionReason = [dictionary objectForKey:@"exception reason"];
		notice.callStack = [dictionary objectForKey:@"call stack"];
		notice.viewControllerName = [dictionary objectForKey:@"view controller"];
        
    }
	
	notice.environmentInfo = info;
	return [notice autorelease];
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
- (NSString *)description {
	unsigned int count;
	objc_property_t *properties = class_copyPropertyList([self class], &count);
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:count];
	for (unsigned int i = 0; i < count; i++) {
		NSString *name = [NSString stringWithUTF8String:property_getName(properties[i])];
		NSString *value = [self valueForKey:name];
		if (value != nil) {
			[dictionary setObject:value forKey:name];
		}
	}
	free(properties);
	return [dictionary description];
}
- (void)dealloc {
	self.exceptionName = nil;
	self.exceptionReason = nil;
	self.environmentName = nil;
	self.environmentInfo = nil;
	self.callStack = nil;
	self.viewControllerName = nil;
	[super dealloc];
}

@end
