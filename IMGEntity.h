//
//  IMGEntity.h
//  Qraved
//
//  Created by Jeff on 8/25/14.
//  Copyright (c) 2014 Imaginato. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"
@protocol IMGModelProtrol <NSObject>
@optional
-(NSString *)createTable;
-(NSString *)insertSQL;
-(NSString *)selectSql;
-(NSString *)deleteSQL;
+(NSString *)createTableWithModel;
@end


@class FMResultSet;
@protocol ResultSetToObject <NSObject>

@optional

+(instancetype)objectWithResult:(FMResultSet * ) resultSet;
-(instancetype)initWithResult:(FMResultSet *)resultSet;

@end

@interface IMGEntity : NSObject

@property (nonatomic, retain)  NSNumber * entityId;
@property (nonatomic, copy)    NSString * title;
@property (nonatomic, copy)    NSString * imageUrl;

@property (nonatomic, copy)    NSString * class_name;
@property (nonatomic,assign)   NSInteger ID;
@end
