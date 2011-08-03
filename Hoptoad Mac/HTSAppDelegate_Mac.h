//
//  HTSAppDelegate_Mac.h
//  Hoptoad Mac
//
//  Created by Caleb Davenport on 5/10/11.
//  Copyright 2011 GUI Cocoa, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "HTNotifier.h"

@interface HTSAppDelegate_Mac : NSObject <NSApplicationDelegate, HTNotifierDelegate> {
@private
    NSWindow *__window;
}

@property (assign) IBOutlet NSWindow *window;

@end
