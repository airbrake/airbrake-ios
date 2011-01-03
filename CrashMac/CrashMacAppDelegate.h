//
//  CrashMacAppDelegate.h
//  CrashMac
//
//  Created by Caleb Davenport on 10/21/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "HTNotifier.h"

@interface CrashMacAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)crash:(id)sender;

@end
