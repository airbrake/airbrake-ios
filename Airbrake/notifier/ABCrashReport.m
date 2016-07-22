//
//  ABCrashReport.m
//  Hoptoad Sample
//
//  Created by Jocelyn Harrington on 8/14/14.
//
//

#import "ABCrashReport.h"
#import "ABNotifierFunctions.h"
#import "ABNotice.h"
@interface ABCrashReport()
@property (nonatomic) NSUncaughtExceptionHandler *exceptionHandler;
@end

@implementation ABCrashReport

-(id)init {
    self = [super init];
    if (self) {
    
    }
    return self;
}

+(ABCrashReport *)sharedInstance {
    static ABCrashReport *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[ABCrashReport alloc] init];
    });
    return _sharedInstance;
}

-(void)startCrashReport {
    @synchronized(self) {
        PLCrashReporterSignalHandlerType signalHandlerType = PLCrashReporterSignalHandlerTypeBSD;
        PLCrashReporterSymbolicationStrategy symbolicationStrategy = PLCrashReporterSymbolicationStrategyAll;
        PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType: signalHandlerType symbolicationStrategy: symbolicationStrategy];
        self.plCrashReporter = [[PLCrashReporter alloc] initWithConfiguration: config];
        
        // Check if we previously crashed
        if ([self.plCrashReporter hasPendingCrashReport]) {
            [self handleCrashReport];
        }
        
        NSUncaughtExceptionHandler *initialHandler = NSGetUncaughtExceptionHandler();
        NSError *error = NULL;
        // Enable the Crash Reporter
        if (![self.plCrashReporter enableCrashReporterAndReturnError: &error]) {
            ABLog(@"ERROR: Could not enable crash reporter: %@", [error localizedDescription]);
        }
        NSUncaughtExceptionHandler *currentHandler = NSGetUncaughtExceptionHandler();
        if (currentHandler && currentHandler != initialHandler) {
            self.exceptionHandler = currentHandler;
        } else {
            ABLog(@"ERROR: Exception handler could not be set.");
        }

    }
}


- (void) handleCrashReport {
    NSError *error = NULL;
	
    if (!self.plCrashReporter) return;
    // Try loading the crash report
    NSData *crashData = [[NSData alloc] initWithData:[self.plCrashReporter loadPendingCrashReportDataAndReturnError: &error]];
    if (crashData == nil) {
        ABLog(@"ERROR: Could not load crash report: %@", error);
    } else {
            //save crashreport locally
            PLCrashReport *report = [[PLCrashReport alloc] initWithData:crashData error:&error];
            
            if (report == nil) {
                ABLog(@"ERROR: Could not parse crash report");
            } else {
                NSString *name = [[NSProcessInfo processInfo] globallyUniqueString];
                NSString *filePath = [[self pathForNoticesDirectory] stringByAppendingPathComponent: name];
                NSString *fileName = [filePath stringByAppendingPathExtension:ABNotifierNoticePathExtension];
                NSError *error = NULL;
                [[self crashReportStringFormat:report] writeToFile: fileName atomically:YES encoding:NSUTF8StringEncoding error:&error];
                 //ABLog(@"new crash report saved at %@", fileName);
            }
    }
    [self.plCrashReporter purgePendingCrashReport];
}

-(NSString *)crashReportStringFormat:(PLCrashReport *)report {
    return [PLCrashReportTextFormatter stringValueForCrashReport:report withTextFormat:PLCrashReportTextFormatiOS];
}

#pragma mark - file utilities
- (NSString *)pathForNoticesDirectory {
    static NSString *path = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
#if TARGET_OS_IPHONE
        NSArray *folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        path = [folders objectAtIndex:0];
        if ([folders count] == 0) {
            path = NSTemporaryDirectory();
        }
        else {
            path = [path stringByAppendingPathComponent:@"AB Notices"];
        }
#else
        NSArray *folders = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        path = [folders objectAtIndex:0];
        if ([folders count] == 0) {
            path = NSTemporaryDirectory();
        }
        else {
            path = [path stringByAppendingPathComponent:ABNotifierApplicationName()];
            path = [path stringByAppendingPathComponent:@"AB Notices"];
        }
#endif
        NSFileManager *manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:path]) {
            [manager
             createDirectoryAtPath:path
             withIntermediateDirectories:YES
             attributes:nil
             error:nil];
        }
    });
    return path;
}


@end
