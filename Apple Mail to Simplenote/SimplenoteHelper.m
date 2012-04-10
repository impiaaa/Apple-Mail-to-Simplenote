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

static char base64EncodingTable[64] = {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
};

// from http://stackoverflow.com/questions/392464/any-base64-library-on-iphone-sdk/800976#800976
+ (NSString *)base64StringFromData:(NSData *)data length:(NSUInteger)length {
    unsigned long ixtext, lentext;
    long ctremaining;
    unsigned char input[3], output[4];
    short i, charsonline = 0, ctcopy;
    const unsigned char *raw;
    NSMutableString *result;

    lentext = [data length];
    if (lentext < 1)
        return @"";
    result = [NSMutableString stringWithCapacity: lentext];
    raw = [data bytes];
    ixtext = 0;

    while (true) {
        ctremaining = lentext - ixtext;
        if (ctremaining <= 0)
            break;
        for (i = 0; i < 3; i++) {
            unsigned long ix = ixtext + i;
            if (ix < lentext)
                input[i] = raw[ix];
            else
                input[i] = 0;
        }
        output[0] = (input[0] & 0xFC) >> 2;
        output[1] = ((input[0] & 0x03) << 4) | ((input[1] & 0xF0) >> 4);
        output[2] = ((input[1] & 0x0F) << 2) | ((input[2] & 0xC0) >> 6);
        output[3] = input[2] & 0x3F;
        ctcopy = 4;
        switch (ctremaining) {
            case 1:
                ctcopy = 2;
                break;
            case 2:
                ctcopy = 3;
                break;
        }

        for (i = 0; i < ctcopy; i++)
            [result appendString: [NSString stringWithFormat: @"%c", base64EncodingTable[output[i]]]];

        for (i = ctcopy; i < 4; i++)
            [result appendString: @"="];

        ixtext += 3;
        charsonline += 4;

        if ((length > 0) && (charsonline >= length))
            charsonline = 0;
    }
    return result;
}

+(void)authorizeWithEmail:(NSString *)anEmail password:(NSString *)password {
    if (simplenoteHelperEmail != nil) {
        [simplenoteHelperEmail release];
    }
    simplenoteHelperEmail = [anEmail retain];
    NSString *urlBody = [NSString stringWithFormat:@"email=%@&password=%@", anEmail, password];
    NSURL *url = [NSURL URLWithString:@"https://simple-note.appspot.com/api/login"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSData *httpBody = [[self base64StringFromData:[urlBody dataUsingEncoding:NSASCIIStringEncoding] length:[urlBody length]] dataUsingEncoding:NSASCIIStringEncoding];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:httpBody];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:@"Apple-Mail-To-Simplenote-0.1" forHTTPHeaderField:@"User-Agent"];
    simplenoteHelperFetcher = [[HTTPFetcher alloc] initWithURLRequest:request
                                                             receiver:self
                                                               action:@selector(authRequestEndedWithFetcher:)];
    [simplenoteHelperFetcher start];
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
                            read:(BOOL)read
                        markdown:(BOOL)markdown {
    NSMutableArray *flagsArray = [NSMutableArray arrayWithCapacity:2];
    if (pinned) {
        [flagsArray addObject:@"pinned"];
    }
    if (!read) {
        [flagsArray addObject:@"unread"];
    }
    if (markdown) {
        [flagsArray addObject:@"markdown"];
    }
    return [self createNoteWithNoteObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithDouble:[createdDate timeIntervalSince1970]], @"createdate",
                                           [NSNumber numberWithDouble:[modifiedDate timeIntervalSince1970]], @"modifydate",
                                           content, @"content",
                                           [NSNumber numberWithChar:(signed char)deleted], @"deleted",
                                           flagsArray, @"systemtags",
                                           nil]];
}

+(void)authRequestEndedWithFetcher:(HTTPFetcher *)fetcher {
    if (fetcher.data) {
        simplenoteHelperAuthKey = [[NSString alloc] initWithData:fetcher.data encoding:NSUTF8StringEncoding];
    }
    [self requestEndedWithFetcher:fetcher];
}

+(void)requestEndedWithFetcher:(HTTPFetcher *)fetcher {
    if (fetcher.failureCode >= 400) {
        [simplenoteHelperCallbackObject performSelector:simplenoteHelperFailCallback withObject:fetcher];
    }
    else {
        [simplenoteHelperCallbackObject performSelector:simplenoteHelperCallback withObject:fetcher];
    }
}

@end
