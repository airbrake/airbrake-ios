//
//  HTSAppDelegate_iOS.h
//  Hoptoad iOS
//
//  Created by Caleb Davenport on 5/10/11.
//  Copyright 2011 GUI Cocoa, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ABNotifier.h"

@interface HTSAppDelegate_iOS : NSObject <UIApplicationDelegate, HTNotifierDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

- (IBAction)exception;
- (IBAction)signal;

@end
