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

-(IBAction)start:(id)sender {
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
    NSMutableArray *pathList = [NSMutableArray arrayWithCapacity:1];
    NSArray *mailboxPathList;
    for (NSString *libraryPath in NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)) {
        mailboxPathList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[libraryPath stringByAppendingPathComponent:@"Mail"] error:&err];
        catchErr(err);
        for (NSString *mailboxPath in mailboxPathList) {
            BOOL directory;
            if ([[NSFileManager defaultManager] fileExistsAtPath:mailboxPath isDirectory:&directory] && directory) {
                [pathList addObject:[mailboxPath stringByAppendingPathComponent:@"Notes.mbox/Messages"]];
                [pathList addObject:[mailboxPath stringByAppendingPathComponent:@"Notes.imapbox/Messages"]];
            }
        }
    }
    for (NSString *notesBoxPath in pathList) {
        BOOL directory;
        if ([[NSFileManager defaultManager] fileExistsAtPath:notesBoxPath isDirectory:&directory] && directory) {
            [messageFileList addObjectsFromArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:notesBoxPath error:&err]];
            catchErr(err);
        }
    }
    [uploadIndicator setMaxValue:[messageFileList count]];
    messageFileIndex = 0;
    simplenoteHelperCallback = @selector(startNextUpload:);
    [self startNextUpload:sender];
}

typedef enum _ContentTransferEncoding {
    ContentTransferEncoding7Bit,
    ContentTransferEncodingQuotedPrintable,
    ContentTransferEncodingBase64
} ContentTransferEncoding;

-(void)startNextUpload:(id)sender {
    [uploadIndicator setDoubleValue:messageFileIndex];
    if (messageFileIndex >= [messageFileList count]) {
        [self finishedUploadingAllNotes];
        return;
    }
    [loadingTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Uploading %u of %u", @"Upload progress descriptor"), messageFileIndex+1, [messageFileList count], nil]];
    // parse next message
    // Special thanks to this blog post:
    // http://mike.laiosa.org/2009/03/01/emlx.html
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
    ContentTransferEncoding transferEncoding;
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
                if ([value rangeOfString:@"7bit" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    transferEncoding = ContentTransferEncoding7Bit;
                }
                else if ([value rangeOfString:@"Quoted-Printable" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    transferEncoding = ContentTransferEncodingQuotedPrintable;
                }
                else {
                    [NSException exceptionWithName:@"Encoding not found" reason:[NSString stringWithFormat:@"Couldn't find transfer encoding %@", value] userInfo:nil];
                }
            }
            else if ([key isEqualToString:@"X-Mail-Created-Date"]) {
                createdDate = [NSDate dateWithString:value];
            }
            else if ([key isEqualToString:@"Date"]) {
                modifiedDate = [NSDate dateWithString:value];
            }
        }
    }
    
    splitRange = [rawMessage rangeOfString:@"\n\n"];
    NSMutableData *newMessageData = [NSMutableData dataWithCapacity:messageLength/2];
    NSUInteger index;
    for (index = splitRange.location+splitRange.length; index < [rawMessage length]; index++) {
        unichar uc = [rawMessage characterAtIndex:index];
        switch (transferEncoding) {
            case ContentTransferEncoding7Bit:
                [newMessageData appendBytes:&uc length:1];
                break;
            case ContentTransferEncodingQuotedPrintable:
                if (uc == '=') {
                    NSString *hexStr = [rawMessage substringWithRange:NSMakeRange(index+1, 2)];
                    unsigned char hex;
                    sscanf([hexStr UTF8String], "%x", &hex);
                    [newMessageData appendBytes:&hex length:1];
                }
                else {
                    [newMessageData appendBytes:&uc length:1];
                }
                break;
                
            default:
                [newMessageData appendBytes:&uc length:1];
                break;
        }
    }
    NSString *newMessage = [[NSString alloc] initWithData:newMessageData encoding:encoding];
    
    [stream setProperty:[NSNumber numberWithInteger:[[stream propertyForKey:NSStreamFileCurrentOffsetKey] integerValue]+messageLength] forKey:NSStreamFileCurrentOffsetKey];
    [data resetBytesInRange:NSMakeRange(0, [data length])];
    [data setLength:0];
    while (TRUE) {
        if ([stream read:(uint8_t *)&c maxLength:1] == 0) {
            break;
        }
        [data appendBytes:&c length:1];
    }
    NSDictionary *metaDict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&err];
    catchErr(err);
    NSInteger flags = [[metaDict valueForKey:@"flags"] integerValue];
    messageFileIndex++;
    [SimplenoteHelper createNoteWithCreatedDate:createdDate modifiedDate:modifiedDate content:newMessage pinned:(flags & 0x10) deleted:((flags & 0x02) && [importTrashedCheck integerValue]) read:(flags & 0x01)];
    [newMessage release];
}

-(void)finishedUploadingAllNotes {
    
}

@end
