/*
 
 Copyright (C) 2011 GUI Cocoa, LLC.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "GCActionSheet.h"

#if TARGET_OS_IPHONE

static NSString *GCActionSheetWillPresentKey = @"GCActionSheetWillPresentAction";
static NSString *GCActionSheetDidPresentKey = @"GCActionSheetDidPresentAction";
static NSString *GCActionSheetWillDismissKey = @"GCActionSheetWillDismissAction";
static NSString *GCActionSheetDidDismissKey = @"GCActionSheetDidDismissAction";

@implementation GCActionSheet
- (id)initWithTitle:(NSString *)title {
    self = [super initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    if (self) {
        actions = [[NSMutableDictionary alloc] init];
    }
    return self;
}
- (void)dealloc {
    [actions release];
    actions = nil;
    [super dealloc];
}
- (void)addButtonWithTitle:(NSString *)title block:(void (^) (void))block {
    if ([actions objectForKey:title]) { return; }
    [self addButtonWithTitle:title];
    if (block) {
        void (^action) () = Block_copy(block);
        [actions setObject:action forKey:title];
        Block_release(action);
    }
}
- (void)setWillPresentBlock:(void (^) (void))block {
    if (block) {
        void (^action) () = Block_copy(block);
        [actions setObject:action forKey:GCActionSheetWillPresentKey];
        Block_release(action);
    }
    else {
        [actions removeObjectForKey:GCActionSheetWillPresentKey];
    }
}
- (void)setDidPresentBlock:(void (^) (void))block {
    if (block) {
        void (^action) () = Block_copy(block);
        [actions setObject:action forKey:GCActionSheetDidPresentKey];
        Block_release(action);
    }
    else {
        [actions removeObjectForKey:GCActionSheetDidPresentKey];
    }
}
- (void)setWillDismissBlock:(void (^) (void))block {
    if (block) {
        void (^action) () = Block_copy(block);
        [actions setObject:action forKey:GCActionSheetWillDismissKey];
        Block_release(action);
    }
    else {
        [actions removeObjectForKey:GCActionSheetWillDismissKey];
    }
}
- (void)setDidDismissBlock:(void (^) (void))block {
    if (block) {
        void (^action) () = Block_copy(block);
        [actions setObject:action forKey:GCActionSheetDidDismissKey];
        Block_release(action);
    }
    else {
        [actions removeObjectForKey:GCActionSheetDidDismissKey];
    }
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex >= 0 && buttonIndex < actionSheet.numberOfButtons) {
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        void (^action) () = [actions objectForKey:title];
        if (action) { action(); }
    }
}
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    void (^action) () = [actions objectForKey:GCActionSheetWillPresentKey];
    if (action) { action(); }
}
- (void)didPresentActionSheet:(UIActionSheet *)actionSheet {
    void (^action) () = [actions objectForKey:GCActionSheetDidPresentKey];
    if (action) { action(); }
}
- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    void (^action) () = [actions objectForKey:GCActionSheetWillDismissKey];
    if (action) { action(); }
}
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    void (^action) () = [actions objectForKey:GCActionSheetDidDismissKey];
    if (action) { action(); }
}

@end

#endif
