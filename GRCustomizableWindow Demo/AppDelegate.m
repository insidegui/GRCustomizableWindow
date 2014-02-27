//
//  AppDelegate.m
//  GRCustomizableWindow Demo
//
//  Created by Guilherme Rambo on 26/02/14.
//  Copyright (c) 2014 Guilherme Rambo. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (unsafe_unretained) IBOutlet GRCustomizableWindow *texturedWindow;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.window.titlebarHeight = @40;
    self.window.titlebarColor = [NSColor colorWithCalibratedRed:0.110 green:0.281 blue:0.998 alpha:1.000];
    self.window.titleColor = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
    self.window.backgroundColor = [NSColor colorWithCalibratedRed:0.642 green:0.795 blue:0.985 alpha:1.000];
    self.window.centerControls = YES;
    
    [self.textView.textStorage readFromURL:[[NSBundle mainBundle] URLForResource:@"Info" withExtension:@"rtf"] options:nil documentAttributes:nil];
    
    self.texturedWindow.titlebarColor = [NSColor colorWithCalibratedRed:0.433 green:0.902 blue:0.213 alpha:1.000];
    self.texturedWindow.titleColor = [NSColor colorWithCalibratedRed:0.165 green:0.322 blue:0.090 alpha:1.000];
}

@end
