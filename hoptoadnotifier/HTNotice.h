//
//  HTNotice.h
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 10/2/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

// notice info
typedef struct ht_notice_info_t {
	
	// file names
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
	
	// environment name
	const char *env_name;
	unsigned long env_name_len;
    
    // git hash
    const char *git_hash;
    unsigned long git_hash_len;
	
} ht_notice_info_t;
ht_notice_info_t ht_notice_info;

// file flags
extern NSString *HTNoticePathExtension;
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
	NSDictionary *_environmentInfo;
	NSArray *_callStack;
}

@property (nonatomic, copy) NSString *exceptionName;
@property (nonatomic, copy) NSString *exceptionReason;
@property (nonatomic, copy) NSString *environmentName;
@property (nonatomic, copy) NSString *viewControllerName;
@property (nonatomic, retain) NSDictionary *environmentInfo;
@property (nonatomic, retain) NSArray *callStack;

// create an object representation of notice data
+ (HTNotice *)noticeWithContentsOfFile:(NSString *)path;

// get a string representation of the hoptoad xml payload
- (NSString *)hoptoadXMLString;

// get a data representation of the hoptoad xml payload
- (NSData *)hoptoadXMLData;

@end
