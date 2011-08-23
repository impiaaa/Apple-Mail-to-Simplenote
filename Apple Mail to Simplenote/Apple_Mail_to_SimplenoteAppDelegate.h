//
//  Apple_Mail_to_SimplenoteAppDelegate.h
//  Apple Mail to Simplenote
//
//  Created by Spencer Alves on 8/22/11.
//  Copyright 2011 Spencer Alves. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Apple_Mail_to_SimplenoteAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate> {
@private
    NSWindow *window;
    NSTextField *emailField;
    NSTextField *passwordField;
    NSButton *importTrashedCheck;
    NSButton *importButton;
    NSProgressIndicator *uploadIndicator;
    NSTextField *loadingTextField;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *emailField;
@property (assign) IBOutlet NSTextField *passwordField;
@property (assign) IBOutlet NSButton *importTrashedCheck;
@property (assign) IBOutlet NSButton *importButton;
@property (assign) IBOutlet NSProgressIndicator *uploadIndicator;
@property (assign) IBOutlet NSTextField *loadingTextField;

@end
