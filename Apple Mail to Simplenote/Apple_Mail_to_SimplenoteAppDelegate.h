//
//  Apple_Mail_to_SimplenoteAppDelegate.h
//  Apple Mail to Simplenote
//
//  Created by Spencer Alves on 8/22/11.
//  Copyright 2011 Spencer Alves. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum _ContentTransferEncoding {
    ContentTransferEncoding7Bit,
    ContentTransferEncodingQuotedPrintable,
    ContentTransferEncodingBase64
} ContentTransferEncoding;

@interface Apple_Mail_to_SimplenoteAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate> {
@private
    NSWindow *window;
    NSTextField *emailField;
    NSSecureTextField *passwordField;
    NSButton *importButton;
    NSProgressIndicator *uploadIndicator;
    NSTextField *loadingTextField;
    NSMutableArray *messageFileList;
    NSUInteger messageFileIndex;
    NSButton *stripHTMLCheckbox;

    NSStringEncoding encoding;
    ContentTransferEncoding transferEncoding;
    BOOL markdown;
    BOOL stripHTML;
    NSDate *createdDate;
    NSDate *modifiedDate;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *emailField;
@property (assign) IBOutlet NSSecureTextField *passwordField;
@property (assign) IBOutlet NSButton *importButton;
@property (assign) IBOutlet NSProgressIndicator *uploadIndicator;
@property (assign) IBOutlet NSTextField *loadingTextField;
@property (assign) IBOutlet NSButton *stripHTMLCheckbox;

-(IBAction)start:(id)sender;
-(void)finishedAuth:(id)sender;
-(void)requestFailed:(id)sender;
-(void)startNextUpload:(id)sender;
-(void)finishedUploadingAllNotes;

@end
