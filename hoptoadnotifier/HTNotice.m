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

#import <objc/runtime.h>
#import <TargetConditionals.h>

#import "HTNotice.h"
#import "HTNotifier.h"
#import "HTFunctions.h"

#import "DDXML.h"

NSString * const ABNotifierNoticePathExtension = @"htnotice";
int HTNoticeFileVersion = 4;
int HTSignalNoticeType = 1;
int HTExceptionNoticeType = 2;

@implementation HTNotice

@synthesize exceptionName=_exceptionName;
@synthesize exceptionReason=_exceptionReason;
@synthesize environmentName=_environmentName;
@synthesize environmentInfo=_environmentInfo;
@synthesize bundleVersion=_bundleVersion;
@synthesize action=_action;
@synthesize callStack=_callStack;
@synthesize viewControllerName=_viewControllerName;

#pragma mark - factory method to create notice
+ (HTNotice *)noticeWithContentsOfFile:(NSString *)path {
    
    @try {
        
        // check path
        NSString *extension = [path pathExtension];
        if (![extension isEqualToString:ABNotifierNoticePathExtension]) {
            [NSException raise:NSInvalidArgumentException format:@"%@ does is not a notice"];
        }
        
        // setup
        HTNotice *notice = [[HTNotice alloc] init];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:3];
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
        if (version >= 2 && version < 4) {
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
        
        // bundle version
        if (version >= 3) {
            [data getBytes:&length range:NSMakeRange(location, sizeof(unsigned long))];
            location += sizeof(unsigned long);
            if (length > 0) {
                char * value_str = malloc(length * sizeof(char));
                [data getBytes:value_str range:NSMakeRange(location, length)];
                location += length;
                notice.bundleVersion = [NSString stringWithUTF8String:value_str];
                free(value_str);
            }
        }
        
        
        // signal notice
        if (type == HTSignalNoticeType) {
            
            // signal
            int signal;
            [data getBytes:&signal range:NSMakeRange(location, sizeof(int))];
            location += sizeof(int);
            
            // exception name and reason
            notice.exceptionName = [NSString stringWithUTF8String:strsignal(signal)];
            notice.exceptionReason = @"Application recieved signal";
            
            // environment info
            if (version >= 4) {
                [data getBytes:&length range:NSMakeRange(location, sizeof(unsigned long))];
                location += sizeof(unsigned long);
                NSData *subdata = [data subdataWithRange:NSMakeRange(location, length)];
                location += length;
                NSDictionary *environmentInfo = [NSKeyedUnarchiver unarchiveObjectWithData:subdata];
                [info addEntriesFromDictionary:environmentInfo];
            }
            
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
        
        // exception notice
        else if (type == HTExceptionNoticeType) {
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
        
        // set action
        notice.callStack = HTParseCallstack(notice.callStack);
        notice.action = HTActionFromParsedCallstack(notice.callStack);
        if (type == HTSignalNoticeType && notice.action != nil) {
            notice.exceptionReason = notice.action;
        }
        
        // set env info
        notice.environmentInfo = info;
        
        // return
        return [notice autorelease];
        
    }
    @catch (NSException *exception) {
        HTLog(@"%@", exception);
        return nil;
    }
    
}

#pragma mark - object methods
- (NSString *)hoptoadXMLString {
    
    // create root
    DDXMLElement *notice = [[DDXMLElement alloc] initWithName:@"notice"];
	[notice addAttribute:[DDXMLElement attributeWithName:@"version" stringValue:@"2.1"]];
    
    // set api key
	NSString *apiKey = [[HTNotifier sharedNotifier] apiKey];
    if (apiKey == nil) { apiKey = @""; }
    [notice addChild:[DDXMLElement elementWithName:@"api-key" stringValue:apiKey]];
    
    // set notifier information
    DDXMLElement *notifier = [[DDXMLElement alloc] initWithName:@"notifier"];
#if TARGET_OS_IPHONE
    [notifier addChild:[DDXMLElement elementWithName:@"name" stringValue:@"Hoptoad iOS Notifier"]];
#else
    [notifier addChild:[DDXMLElement elementWithName:@"name" stringValue:@"Hoptoad Mac Notifier"]];
#endif
    [notifier addChild:[DDXMLElement elementWithName:@"url" stringValue:@"http://github.com/guicocoa/hoptoad-ios"]];
	[notifier addChild:[DDXMLElement elementWithName:@"version" stringValue:HTNotifierVersion]];
	[notice addChild:notifier];
    [notifier release];
    
    // set error information
    NSString *message = [NSString stringWithFormat:@"%@: %@", self.exceptionName, self.exceptionReason];
    DDXMLElement *error = [[DDXMLElement alloc] initWithName:@"error"];
    [error addChild:[DDXMLElement elementWithName:@"class" stringValue:self.exceptionName]];
	[error addChild:[DDXMLElement elementWithName:@"message" stringValue:message]];
    DDXMLElement *backtrace = [[DDXMLElement alloc] initWithName:@"backtrace"];
    for (NSArray *line in self.callStack) {
        DDXMLElement *element = [DDXMLElement elementWithName:@"line"];
        [element addAttribute:
         [DDXMLElement
          attributeWithName:@"number"
          stringValue:[line objectAtIndex:0]]];
        [element addAttribute:
         [DDXMLElement
          attributeWithName:@"file"
          stringValue:[line objectAtIndex:1]]];
        [element addAttribute:
         [DDXMLElement
          attributeWithName:@"method"
          stringValue:[line objectAtIndex:2]]];
        [backtrace addChild:element];
	}
    [error addChild:backtrace];
    [notice addChild:error];
    [backtrace release];
    [error release];
    
    // set request info
	DDXMLElement *request = [[DDXMLElement alloc] initWithName:@"request"];
	[request addChild:[DDXMLElement elementWithName:@"url"]];
    [request addChild:[DDXMLElement elementWithName:@"component" stringValue:self.viewControllerName]];
    [request addChild:[DDXMLElement elementWithName:@"action" stringValue:self.action]];
    DDXMLElement *cgi = [[DDXMLElement alloc] initWithName:@"cgi-data"];
    for (id key in [self.environmentInfo allKeys]) {
        id value = [self.environmentInfo objectForKey:key];
        DDXMLElement *element = [DDXMLElement elementWithName:@"var" stringValue:[value description]];
        [element addAttribute:
         [DDXMLElement
          attributeWithName:@"key"
          stringValue:[key description]]];
        [cgi addChild:element];
	}
    [request addChild:cgi];
    [notice addChild:request];
    [request release];
    [cgi release];
    
    // set server environment
	DDXMLElement *environment = [[DDXMLElement alloc] initWithName:@"server-environment"];
	[environment addChild:[DDXMLElement elementWithName:@"environment-name" stringValue:self.environmentName]];
    [environment addChild:[DDXMLElement elementWithName:@"app-version" stringValue:self.bundleVersion]];
	[notice addChild:environment];
    [environment release];
	
    // finish up
    NSString *XMLString = [notice XMLString];
    [notice release];
    return XMLString;
    
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
    self.bundleVersion = nil;
    self.action = nil;
	self.callStack = nil;
	self.viewControllerName = nil;
	[super dealloc];
}

@end
