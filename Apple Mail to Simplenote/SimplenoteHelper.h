//
//  SimplenoteHelper.h
//  Apple Mail to Simplenote
//
//  Created by Spencer Alves on 8/22/11.
//  Copyright 2011 Spencer Alves. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONFetcher.h"

NSString *simplenoteHelperAuthKey;
NSString *simplenoteHelperEmail;
HTTPFetcher *simplenoteHelperFetcher;

@interface SimplenoteHelper : NSObject {
}

+(void)authorizeWithEmail:(NSString *)anEmail password:(NSString *)password;
+(void)createNoteWithNoteObject:(NSDictionary *)noteObject;
+(void)createNoteWithCreatedDate:(NSDate *)createdDate
                    modifiedDate:(NSDate *)modifiedDate
                         content:(NSString *)content
                          pinned:(BOOL)pinned
                         deleted:(BOOL)deleted
                            read:(BOOL)read;
+(void)requestEndedWithFetcher:(HTTPFetcher *)fetcher;
+(void)authRequestEndedWithFetcher:(HTTPFetcher *)fetcher;

@end
