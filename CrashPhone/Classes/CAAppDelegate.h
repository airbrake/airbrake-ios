//
//  CrashAppAppDelegate.h
//  CrashApp
//
//  Created by Caleb Davenport on 5/26/10.
//  Copyright GUI Cocoa, LLC. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HTNotifier.h"

@interface CAAppDelegate : NSObject <UIApplicationDelegate, HTNotifierDelegate> {
    UIWindow *window;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

- (IBAction)crash:(id)sender;
- (IBAction)signal:(id)sender;

@end

