//
//  ABCrashReport.h
//  Hoptoad Sample
//
//  Created by Jocelyn Harrington on 8/14/14.
//
//

#import <Foundation/Foundation.h>
@class PLCrashReporter;
@class PLCrashReport;

@interface ABCrashReport : NSObject
@property (nonatomic, strong) PLCrashReporter *plCrashReporter;
+(ABCrashReport *)sharedInstance;
-(void)startCrashReport;
-(NSString *)crashReportStringFormat:(PLCrashReport *)report;
@end
