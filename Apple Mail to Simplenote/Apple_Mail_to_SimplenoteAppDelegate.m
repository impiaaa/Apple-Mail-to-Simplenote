//
//  Apple_Mail_to_SimplenoteAppDelegate.m
//  Apple Mail to Simplenote
//
//  Created by Spencer Alves on 8/22/11.
//  Copyright 2011 Spencer Alves. All rights reserved.
//

#import "Apple_Mail_to_SimplenoteAppDelegate.h"

@implementation Apple_Mail_to_SimplenoteAppDelegate

@synthesize window, emailField, passwordField, importTrashedCheck, importButton, uploadIndicator, loadingTextField;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (NSSize)windowWillResize:(NSWindow *)theWindow toSize:(NSSize)proposedFrameSize {
    proposedFrameSize.height = theWindow.frame.size.height;
    return proposedFrameSize;
}

@end
