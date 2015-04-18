//
//  ViewController.m
//  Airbrake
//
//  Created by Jocelyn Harrington on 4/17/15.
//  Copyright (c) 2015 cleanmicro. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)exception {
    NSArray *array = [NSArray array];
    [array objectAtIndex:NSUIntegerMax];
}
- (IBAction)signal {
    raise(SIGSEGV);
}

- (IBAction)customLog:(id)sender {
    @try {
        [NSException raise:@"custom method name" format:@"custom method error!"];
    } @catch (NSException *exception) {
        [ABNotifier logException:exception parameters: @{@"version": @"4.2", @"status":@"testing"}];
    }
}

@end
