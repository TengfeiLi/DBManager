//
//  CityManager.h
//  FMDB_AFNETWORKING
//
//  Created by Olaf on 14-9-9.
//  Copyright (c) 2014年 Olaf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>


#import "FMDataBase.h"
#import "FMDatabaseQueue.h"


#import "IMGEntity.h"

#define DDBLog(vags) NSLog(vags);

typedef NSString IMGSQL;

@interface DBManager : NSObject


@property (nonatomic,retain,readonly) FMDatabaseQueue * dbQueue;
@property (nonatomic,retain,readonly) FMDatabase * fmdb; //将所有的数据库 操作 封装到 Manager中

@property (nonatomic,copy,readonly) NSString * basePath; //数据库 存储路径

//creator
+(instancetype)manager;
-(instancetype)initWithBasePath:(NSString *)basePath;

//init operation
-(BOOL)openDataBase;

//base operation

//创建表
-(void)createTableWithSql:(IMGSQL *)sql;
-(void)createTableWithModel:(id<IMGModelProtrol>)model;
-(void)createTableWithClass:(Class<IMGModelProtrol>)model;
//插入语句
-(void)insertWithSql:(IMGSQL *)sql;
-(void)insertModel:(IMGEntity *)model;
-(void)insertModel:(IMGEntity *)model update:(BOOL) update;
//删除语句
-(void)deleteWithSql:(IMGSQL *)sql;
-(void)deleteWithModel:(id<IMGModelProtrol>)model;
//查找
-(void)selectWithSql:(IMGSQL *)sql successBlock:(void (^)(FMResultSet * resultSet)) success failureBlock:(void(^)(NSError *error)) failure;
-(void)selectWithClass:(Class)clazz successBlock:(void (^)(FMResultSet * resultSet))success failureBlock:(void (^)(NSError * error))failure;;
-(void)selectArrayWithClass:(Class)clazz successBlock:(void (^)(NSArray * array))success failureBlock:(void (^)(NSError * error))failure;


-(void)updateModel:(IMGEntity * )model params:(NSDictionary *)params;



-(BOOL)executeSQL:(NSString*)sql;
@end
