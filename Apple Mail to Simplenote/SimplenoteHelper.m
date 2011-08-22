//
//  SimplenoteHelper.m
//  Apple Mail to Simplenote
//
//  Created by Spencer Alves on 8/22/11.
//  Copyright 2011 Spencer Alves. All rights reserved.
//

#import "SimplenoteHelper.h"


@implementation SimplenoteHelper

+(void)authorizeWithEmail:(NSString *)anEmail password:(NSString *)password {
    simplenoteHelperEmail = [anEmail retain];
}

+(void)createNoteWithNoteObject:(NSDictionary *)noteObject {
    
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

@end
