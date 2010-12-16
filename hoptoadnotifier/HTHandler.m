//
//  HTHandler.m
//  CrashPhone
//
//  Created by Caleb Davenport on 12/15/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import "HTHandler.h"
//#import "HTNotifier.h"

static int signals[] = {
    SIGABRT,
    SIGBUS,
    SIGFPE,
    SIGILL,
    SIGSEGV,
    SIGTRAP
};
static int count_signals = 6;

static void handle_signal(int signal) {
	NSLog(@"signal %d", signal);
}

@implementation HTHandler

- (id)init {
	self = [super init];
	if (self) {
		
		for (int i = 0; i < count_signals; i++) {
			struct sigaction action;
			sigemptyset(&action.sa_mask);
			action.sa_handler = handle_signal;
			if (sigaction(signals[i], &action, NULL) != 0) {
				NSLog(@"[Hoptoad] unable to register signal handler for %s", strsignal(signals[i]));
				[self release];
				return nil;
			}
		}
		
	}
	return self;
}

- (void)dealloc {
	for (int i = 0; i < count_signals; i++) {
		struct sigaction action;
		sigemptyset(&action.sa_mask);
		action.sa_handler = SIG_DFL;
		sigaction(signals[i], &action, NULL);
	}
	
	[super dealloc];
}

@end
