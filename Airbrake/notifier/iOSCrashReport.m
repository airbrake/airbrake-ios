//
//  iOSCrashReport.m
//  Hoptoad Sample
//
//  Created by Jocelyn Harrington on 2/14/14.
//  Copyright (c) 2014 . All rights reserved.
//

#import "iOSCrashReport.h"

@implementation iOSCrashReport

+(NSData *)getCrashReport {
    PLCrashReporter  *crashReporter = [PLCrashReporter sharedReporter];
    NSData  *crashData;
    NSError  *error;
    crashData = [crashReporter loadPendingCrashReportDataAndReturnError: &error];
    if (crashData == nil) {
        NSLog(@"Could not load crash report: %@", error);
        goto finish;
    }
    
    return crashData;
    /*
    // We could send the report from here, but we'll just print out
    // some debugging info instead
    PLCrashReport  *report = [[[PLCrashReport alloc] initWithData: crashData error: &error] autorelease];
    if (report == nil) {
        NSLog(@"Could not parse crash report");
        goto finish;
    }
    
    NSLog(@"Crashed on %@", report.systemInfo.timestamp);
    NSLog(@"Crashed with signal %@ (code %@, address=0x%" PRIx64 ")", report.signalInfo.name,
          report.signalInfo.code, report.signalInfo.address);
    */
    // Purge the report
finish:
    [crashReporter purgePendingCrashReport];
    return nil;
}

@end
