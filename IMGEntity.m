//
//  IMGEntity.m
//  Qraved
//
//  Created by Jeff on 8/25/14.
//  Copyright (c) 2014 Imaginato. All rights reserved.
//

#import "IMGEntity.h"

@implementation IMGEntity
-(void)setValue:(id)value forUndefinedKey:(NSString *)key{
    if([key isEqualToString:@"id"]){
        [self setValue:value forKey:@"ID"];
    }
    if([key isEqualToString:@"class"]){
        [self setValue:value forKey:@"class_name"];
    }
}
@end
