//
//  SimplenoteHelper.m
//  Apple Mail to Simplenote
//
//  Created by Spencer Alves on 8/22/11.
//  Copyright 2011 Spencer Alves. All rights reserved.
//

#import "SimplenoteHelper.h"
#import "SBJson.h"
#import "Apple_Mail_to_SimplenoteAppDelegate.h"

@implementation SimplenoteHelper

+(void)authorizeWithEmail:(NSString *)anEmail password:(NSString *)password {
    simplenoteHelperEmail = [anEmail retain];
}

+(void)createNoteWithNoteObject:(NSDictionary *)noteObject {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?auth=%@&email=%@", @"https://simple-note.appspot.com/api2/data", simplenoteHelperAuthKey, simplenoteHelperEmail, nil]]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[noteObject JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"Apple-Mail-To-Simplenote-0.1" forHTTPHeaderField:@"User‐Agent"];
    simplenoteHelperFetcher = [[JSONFetcher alloc] initWithURLRequest:request
                                                             receiver:self
                                                               action:@selector(requestEndedWithFetcher:)];
    [simplenoteHelperFetcher start];
}

+(void)createNoteWithCreatedDate:(NSDate *)createdDate
                    modifiedDate:(NSDate *)modifiedDate
                         content:(NSString *)content
                          pinned:(BOOL)pinned
                         deleted:(BOOL)deleted
                            read:(BOOL)read {
    NSMutableArray *flagsArray = [NSMutableArray arrayWithCapacity:2];
    if (pinned) {
        [flagsArray addObject:@"pinned"];
    }
    if (!read) {
        [flagsArray addObject:@"unread"];
    }
    [flagsArray addObject:@"markdown"];
    return [self createNoteWithNoteObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithDouble:[createdDate timeIntervalSince1970]], @"createdate",
                                           [NSNumber numberWithDouble:[modifiedDate timeIntervalSince1970]], @"modifydate",
                                           content, @"content",
                                           [NSNumber numberWithChar:(signed char)deleted], @"deleted",
                                           flagsArray, @"systemtags",
                                           nil]];
}

+(void)requestEndedWithFetcher:(HTTPFetcher *)fetcher {
    if (fetcher.failureCode >= 400) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error", @"")
                                         defaultButton:NSLocalizedString(@"OK", @"")
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"Error %i: %@",
                          fetcher.failureCode,
                          [NSHTTPURLResponse localizedStringForStatusCode:fetcher.failureCode],
                          nil];
        [alert beginSheetModalForWindow:((Apple_Mail_to_SimplenoteAppDelegate *)[NSApplication sharedApplication]).window modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }
    if (fetcher.context == simplenoteHelperEmail) {
        simplenoteHelperAuthKey = [[NSString alloc] initWithData:fetcher.data encoding:NSUTF8StringEncoding];
    }
    [simplenoteHelperFetcher release];
}

@end
