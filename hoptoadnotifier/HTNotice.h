//
//  HTNotice.h
//  HoptoadNotifier
//
//  Created by Caleb Davenport on 10/2/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 Instances of the HTNotice class represent a single crash
 report. It holds all of the properties that get posted to
 Hoptoad.
 
 This class conforms to NSCoding and instances are
 responsible for transfering themselves to and from their
 file representations.
 
 All of the properties represented as instance variables are
 persisted in the file representation of the object. Those
 that are not are pulled from the HTNotifier at runtime
 (primarily the API key).
 */
@interface HTNotice : NSObject <NSCoding> {
@private
	NSString *operatingSystemVersion;
	NSString *applicationVersion;
	NSString *executableName;
	NSString *exceptionName;
	NSString *exceptionReason;
	NSString *platform;
	NSString *environmentName;
	NSString *viewControllerName;
	NSDictionary *environmentInfo;
	NSArray *callStack;
}

@property (nonatomic, copy) NSString *operatingSystemVersion;
@property (nonatomic, copy) NSString *applicationVersion;
@property (nonatomic, copy) NSString *executableName;
@property (nonatomic, copy) NSString *exceptionName;
@property (nonatomic, copy) NSString *exceptionReason;
@property (nonatomic, copy) NSString *platform;
@property (nonatomic, copy) NSString *environmentName;
@property (nonatomic, copy) NSString *viewControllerName;
@property (nonatomic, retain) NSDictionary *environmentInfo;
@property (nonatomic, retain) NSArray *callStack;

// create a notice with a few base properties set
+ (HTNotice *)notice;

// create a notice and set the exception information
+ (HTNotice *)noticeWithException:(NSException *)exception;

// create a test notice
+ (HTNotice *)testNotice;

// read a notice from given path
+ (HTNotice *)readFromFile:(NSString *)file;

// get a string representation of the hoptoad xml payload
- (NSString *)hoptoadXMLString;

// get a data representation of the hoptoad xml payload
- (NSData *)hoptoadXMLData;

// write a notice to a given path
- (void)writeToFile:(NSString *)file;

@end
