//
//  iOSCrashReport.h
//  Hoptoad Sample
//
//  Created by Jocelyn Harrington on 2/14/14.
//  Copyright (c) 2014 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CrashReporter/CrashReporter.h"
@interface iOSCrashReport : NSObject

+(NSData *)getCrashReport;
@end
