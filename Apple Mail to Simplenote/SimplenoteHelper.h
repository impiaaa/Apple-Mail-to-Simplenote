//
//  SimplenoteHelper.h
//  Apple Mail to Simplenote
//
//  Created by Spencer Alves on 8/22/11.
//  Copyright 2011 Spencer Alves. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SimplenoteHelper : NSObject {
@private
    NSString *authKey;
    NSString *email;
}

+(void)authorizeWithEmail:(NSString *)anEmail password:(NSString *)password;
+(void)createNoteWithNoteObject:(NSDictionary *)noteObject;
+(void)createNoteWithCreatedDate:(NSDate *)createdDate modifiedDate:(NSDate *)modifiedDate content:(NSString *)content;

@end
