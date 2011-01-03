//
//  HTNotifier_iOS.h
//  CrashPhone
//
//  Created by Caleb Davenport on 1/3/11.
//  Copyright 2011 GUI Cocoa, LLC. All rights reserved.
//

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

#import "HTNotifier.h"

@interface HTNotifier_iOS : HTNotifier <UIAlertViewDelegate> {

}

@end

#endif
