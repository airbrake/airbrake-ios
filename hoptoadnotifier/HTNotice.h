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

#import <Foundation/Foundation.h>

// notice info
typedef struct ht_notice_info_t {
	
	// file name
	const char *notice_path;
	
	// os version
	const char *os_version;
	unsigned long os_version_len;
	
	// platform
	const char *platform;
	unsigned long platform_len;
	
	// app version
	const char *app_version;
	unsigned long app_version_len;
    
    // bundle version
    const char *bundle_version;
    unsigned long bundle_version_len;
    
	// environment name
	const char *env_name;
	unsigned long env_name_len;
    
    // environment info
    void *env_info;
    unsigned long env_info_len;
	
} ht_notice_info_t;
ht_notice_info_t ht_notice_info;

// file flags
extern NSString * const ABNotifierNoticePathExtension;
extern int HTNoticeFileVersion;
extern int HTSignalNoticeType;
extern int HTExceptionNoticeType;

/*
 
 Instances of the HTNotice class represent a single crash
 report. It holds all of the properties that get posted to
 Hoptoad.
 
 All of the properties represented as instance variables are
 persisted in the file representation of the object. Those
 that are not are pulled from the HTNotifier at runtime
 (primarily the API key).
 
 */
@interface HTNotice : NSObject {
@private
	NSString *_exceptionName;
	NSString *_exceptionReason;
	NSString *_environmentName;
	NSString *_viewControllerName;
    NSString *_bundleVersion;
    NSString *_action;
	NSDictionary *_environmentInfo;
	NSArray *_callStack;
}

@property (nonatomic, copy) NSString *exceptionName;
@property (nonatomic, copy) NSString *exceptionReason;
@property (nonatomic, copy) NSString *environmentName;
@property (nonatomic, copy) NSString *viewControllerName;
@property (nonatomic, copy) NSString *bundleVersion;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, copy) NSDictionary *environmentInfo;
@property (nonatomic, copy) NSArray *callStack;

// create an object representation of notice data
+ (HTNotice *)noticeWithContentsOfFile:(NSString *)path;

// get a string representation of the hoptoad xml payload
- (NSString *)hoptoadXMLString;

// get a data representation of the hoptoad xml payload
- (NSData *)hoptoadXMLData;

@end
