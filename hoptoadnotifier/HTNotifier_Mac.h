//
//  HTNotifier_Mac.h
//  CrashPhone
//
//  Created by Caleb Davenport on 1/3/11.
//  Copyright 2011 GUI Cocoa, LLC. All rights reserved.
//

#import <TargetConditionals.h>

#import "HTNotifier.h"

#if TARGET_OS_MAC && !(TARGET_OS_IPHONE)
#import <Cocoa/Cocoa.h>
@interface HTNotifier_Mac : HTNotifier {}
@end
#endif
