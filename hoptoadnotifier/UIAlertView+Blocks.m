//
//  Blocks.m
//  Hoptoad Sample
//
//  Created by Caleb Davenport on 8/12/11.
//  Copyright 2011 GUI Cocoa, LLC. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE

#import <objc/runtime.h>

#import "UIAlertView+Blocks.h"

// object keys
static NSString *UIAlertViewBlocksActionsKey = @"UIAlertViewBlocksActions";
static NSString *UIAlertViewBlocksWillPresentActionKey = @"UIAlertViewBlocksWillPresentAction";
static NSString *UIAlertViewBlocksDidPresentActionKey = @"UIAlertViewBlocksDidPresentAction";
static NSString *UIAlertViewBlocksWillDismissActionKey = @"UIAlertViewBlocksWillDismissAction";
static NSString *UIAlertViewBlocksDidDismissActionKey = @"UIAlertViewBlocksDidDismissAction";

@implementation UIAlertView (Blocks)

+ (void)initialize {
    if (self == [UIAlertView class]) {
        Method one = class_getInstanceMethod(self, @selector(dealloc));
        Method two = class_getInstanceMethod(self, @selector(categoryDealloc));
        method_exchangeImplementations(one, two);
    }
}
- (id)initWithTitle:(NSString *)title message:(NSString *)message {
    self = [self initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    if (self) {
        objc_setAssociatedObject(self, UIAlertViewBlocksActionsKey, [NSMutableDictionary dictionary], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return self;
}
- (void)categoryDealloc {
    objc_setAssociatedObject(self, UIAlertViewBlocksActionsKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, UIAlertViewBlocksWillPresentActionKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, UIAlertViewBlocksDidPresentActionKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, UIAlertViewBlocksWillDismissActionKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, UIAlertViewBlocksDidDismissActionKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self categoryDealloc];
}
- (void)addButtonWithTitle:(NSString *)title action:(void (^) (void))action {
    NSMutableDictionary *actions = objc_getAssociatedObject(self, UIAlertViewBlocksActionsKey);
    [self addButtonWithTitle:title];
    if (action) {
        void (^block) () = Block_copy(action);
        [actions setObject:block forKey:title];
        Block_release(block);
    }
}
- (void)setWillDismissAction:(void (^) (void))action {
    objc_setAssociatedObject(self, UIAlertViewBlocksWillDismissActionKey, action, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (void)setDidDismissAction:(void (^) (void))action {
    objc_setAssociatedObject(self, UIAlertViewBlocksDidDismissActionKey, action, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (void)setWillPresentAction:(void (^) (void))action {
    objc_setAssociatedObject(self, UIAlertViewBlocksWillPresentActionKey, action, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (void)setDidPresentAction:(void (^) (void))action {
    objc_setAssociatedObject(self, UIAlertViewBlocksDidPresentActionKey, action, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == self) {
        if (buttonIndex >= 0 && buttonIndex < alertView.numberOfButtons) {
            NSDictionary *actions = objc_getAssociatedObject(self, UIAlertViewBlocksActionsKey);
            NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
            void (^action) () = [actions objectForKey:title];
            if (action) { action(); }
        }
    }
}
- (void)willPresentAlertView:(UIAlertView *)alertView {
    void (^action) () = objc_getAssociatedObject(self, UIAlertViewBlocksWillPresentActionKey);
    if (action) { action(); }
}
- (void)didPresentAlertView:(UIAlertView *)alertView {
    void (^action) () = objc_getAssociatedObject(self, UIAlertViewBlocksDidPresentActionKey);
    if (action) { action(); }
}
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    void (^action) () = objc_getAssociatedObject(self, UIAlertViewBlocksWillDismissActionKey);
    if (action) { action(); }
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    void (^action) () = objc_getAssociatedObject(self, UIAlertViewBlocksDidDismissActionKey);
    if (action) { action(); }
}

@end

#endif
