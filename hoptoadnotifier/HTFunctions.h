//
//  HTHandler.h
//  CrashPhone
//
//  Created by Caleb Davenport on 12/15/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NSArray * HTHandledSignals();
void HTRegisterHandler();
void HTRemoveHandler();
NSArray * HTCallStackSymbolsFromReturnAddresses(NSArray *);
