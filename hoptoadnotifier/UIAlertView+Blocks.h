//
//  Blocks.h
//  Hoptoad Sample
//
//  Created by Caleb Davenport on 8/12/11.
//  Copyright 2011 GUI Cocoa, LLC. All rights reserved.
//

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

@interface UIAlertView (Blocks)
- (id)initWithTitle:(NSString *)title message:(NSString *)message;
- (void)addButtonWithTitle:(NSString *)title action:(void (^) (void))action;
- (void)setWillDismissAction:(void (^) (void))action;
- (void)setDidDismissAction:(void (^) (void))action;
- (void)setWillPresentAction:(void (^) (void))action;
- (void)setDidPresentAction:(void (^) (void))action;
@end

#endif
