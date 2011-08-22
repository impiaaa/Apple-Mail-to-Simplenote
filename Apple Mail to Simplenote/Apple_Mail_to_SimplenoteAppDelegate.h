//
//  Apple_Mail_to_SimplenoteAppDelegate.h
//  Apple Mail to Simplenote
//
//  Created by Spencer Alves on 8/22/11.
//  Copyright 2011 Spencer Alves. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Apple_Mail_to_SimplenoteAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
