//
//  Apple_Mail_to_SimplenoteAppDelegate.m
//  Apple Mail to Simplenote
//
//  Created by Spencer Alves on 8/22/11.
//  Copyright 2011 Spencer Alves. All rights reserved.
//

#import "Apple_Mail_to_SimplenoteAppDelegate.h"
#import "SimplenoteHelper.h"

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

-(IBAction)start {
    [loadingTextField setStringValue:NSLocalizedString(@"Authorizing…", @"First step of the upload process")];
    simplenoteHelperCallbackObject = self;
    simplenoteHelperCallback = @selector(finishedAuth:);
    [SimplenoteHelper authorizeWithEmail:[emailField stringValue] password:[passwordField stringValue]];
}

#define catchErr(err) if (err) {\
    NSAlert *alert = [NSAlert alertWithError:err];\
    [alert beginSheetModalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];\
    [loadingTextField setStringValue:@""];\
    [uploadIndicator setDoubleValue:0.0];\
    return;\
}

-(void)finishedAuth:(id)sender {
    NSError *err = nil;
    messageFileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Mail/Mailboxes/Notes.mbox/Messages"] error:&err];
    catchErr(err);
    [uploadIndicator setMaxValue:[messageFileList count]];
    messageFileIndex = 0;
    [self finishedUpload:sender];
}

-(void)finishedUpload:(id)sender {
    // parse next message
    NSError *err = nil;
    NSString *path = [messageFileList objectAtIndex:messageFileIndex];
    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:path];
    if (stream == nil) {
        // this is just to find out *what* the error was
        [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&err];
        catchErr(err);
        // even if there was no second error, break anyway
        return;
    }
    NSMutableData *data = [NSMutableData dataWithCapacity:1];
    char c;
    while (TRUE) {
        [stream read:(uint8_t *)&c maxLength:1];
        if (c == 0x0A) {
            break;
        }
        [data appendBytes:&c length:1];
    }
    NSString *lengthStr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSInteger messageLength = [lengthStr integerValue];
    [lengthStr release];
    uint8_t *buffer = malloc(messageLength);
    [stream read:buffer maxLength:messageLength];
    NSString *rawMessage = [[NSString alloc] initWithBytes:buffer length:messageLength encoding:NSASCIIStringEncoding];
    free(buffer);
    NSString *key;
    NSString *value;
    NSRange splitRange;
    NSDate *createdDate;
    NSDate *modifiedDate;
    NSStringEncoding encoding;
    // parse header (HTTP-like)
    for (NSString *line in [rawMessage componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
        splitRange = [line rangeOfString:@":"];
        if ((splitRange.location == NSNotFound) || (splitRange.length == 0)) {
            splitRange = [line rangeOfString:@"="];
            if ((splitRange.location != NSNotFound) && (splitRange.length != 0)) {
                key = [line substringToIndex:splitRange.location];
                value = [line substringFromIndex:splitRange.location+1];
                if ([key rangeOfString:@"charset"].location != NSNotFound) {
                    if ([value rangeOfString:@"windows-1252" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                        encoding = NSWindowsCP1252StringEncoding;
                    }
                    else if ([value rangeOfString:@"us-ascii" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                        encoding = NSASCIIStringEncoding;
                    }
                    else if ([value rangeOfString:@"MACINTOSH" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                        encoding = NSMacOSRomanStringEncoding;
                    }
                    else if ([value rangeOfString:@"utf-8" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                        encoding = NSUTF8StringEncoding;
                    }
                    else {
                        [NSException exceptionWithName:@"Encoding not found" reason:[NSString stringWithFormat:@"Couldn't find encoding %@", value] userInfo:nil];
                    }
                }
            }
        }
        else {
            key = [line substringToIndex:splitRange.location];
            value = [line substringFromIndex:splitRange.location+1];
            if ([key isEqualToString:@"Content-Transfer-Encoding"]) {
                
            }
            else if ([key isEqualToString:@"X-Mail-Created-Date"]) {
                createdDate = [NSDate dateWithString:value];
            }
            else if ([key isEqualToString:@"Date"]) {
                modifiedDate = [NSDate dateWithString:value];
            }
        }
    }
}

@end
