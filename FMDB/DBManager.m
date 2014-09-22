//
//  CityManager.m
//  FMDB_AFNETWORKING
//
//  Created by Olaf on 14-9-9.
//  Copyright (c) 2014年 Olaf. All rights reserved.
//

#import "DBManager.h"
#import "FMDatabase.h"
#import "ModelToSQLProtrol.h"

#define ERROR_DOMAIN @"ERROR.MAIN"

#define defaultDataBaseFilePath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"qraved.sqlite"]

@interface DBManager ()

-(void)openDataBaseFailure;
-(void)initAllTables;
@end

@implementation DBManager

+(instancetype)manager{
    static DBManager * manager = nil;
    static dispatch_once_t one;
    dispatch_once(&one, ^{
        manager=[[DBManager alloc]initWithBasePath:defaultDataBaseFilePath];
    });
    return  manager;
}
//manager初始化函数
-(instancetype)initWithBasePath:(NSString *)filePath{
    if(self=[super init]){
        _basePath = filePath;
        _fmdb=[[FMDatabase alloc]initWithPath:_basePath];
        [_fmdb setLogsErrors:YES];
        [_fmdb open];
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:_basePath];
    }
    return self;
}
//打开数据库
-(BOOL)openDataBase
{
    NSAssert(_fmdb!=nil, @"dataBase is nil");
    if ([_fmdb open]) {
        return YES;
    }else{
        [self openDataBaseFailure];
    }
    return NO;
}

//数据库打开错误是 的解决方法
-(void)openDataBaseFailure{

}
//初始化所有的数据表
-(void)initAllTables{



}
#pragma mark - create
-(void)createTableWithSql:(NSString *)sql{
    if([self.fmdb executeUpdate:sql]){
        DDBLog(@"create success");
        return ;
    }
    DDBLog(@"create failure");
}
-(void)createTableWithModel:(id<IMGModelProtrol>)model{
    if([model respondsToSelector:@selector(createTable)]){
        NSString * sql=[model createTable];
        [self createTableWithSql:sql];
    }
}
//为 某个 模型创建 对应的数据表
-(void)createTableWithClass:(Class) clazz{
    [self createTableByClassName:NSStringFromClass(clazz)];
}

-(BOOL)createTableByClassName:(NSString *)classname{
    if ([self isExistsTable:classname]) {
        return YES;
    }
    NSString *sql = [self tableSql:classname];
    NSLog(@"%@",sql);
    return [_fmdb executeUpdate:sql];
}


#pragma mark -insert
-(void)insertWithSql:(NSString *)sql{
    [self.fmdb executeUpdate:sql];
}

-(void)insertModel:(IMGEntity *)model{
    NSString * insertSQL=[self insertSql:model];
    [_fmdb executeUpdate:insertSQL];
}
-(void)insertModel:(IMGEntity *)model update:(BOOL) update{
    if(update){
        [self updateModel:model params:@{@"ID":[NSNumber numberWithInt:model.ID]}];
    }else{
        [self insertModel:model];
    }
}

-(void)deleteModel:(IMGEntity *)model withID:(NSInteger)ID{
    NSString * deleteSQL = [NSString stringWithFormat:@"delete from %@ where ID = %d",NSStringFromClass([model class]),model.ID];
    bool resu= [_fmdb executeUpdate:deleteSQL];
    printf("%d",resu);
}
#pragma mark -delete
-(void)deleteWithSql:(NSString *)sql{
    [_dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:sql];
    }];

}

-(void)deleteWithModel:(id<IMGModelProtrol>)model{
    if([model respondsToSelector:@selector(deleteSQL)]){
        [self deleteWithSql:[model deleteSQL]];
    }
}
#pragma mark -update
-(void)updateModel:(IMGEntity * )model params:(NSDictionary *)params{
    u_int count;
    objc_property_t * properties  = class_copyPropertyList([model class], &count);
    NSMutableString * updateSQL=[NSMutableString  stringWithFormat:@"update %@ set ",NSStringFromClass([model class])];
    for (int i=0; i<count; i++) {
        if(i!=0){
            [updateSQL appendString:@","];
        }
        const char * pro_name = property_getName(properties[i]);
        NSString * proKey=[[NSString alloc]initWithCString: pro_name encoding:NSUTF8StringEncoding];
        [updateSQL appendFormat:@"%@",proKey];
        [updateSQL appendString:@" = "];
        if ([[model valueForKey:proKey] isKindOfClass:[NSString class]]) {
            [updateSQL appendFormat:@"'%@'",[model valueForKey:proKey]];
        }else{
            [updateSQL appendFormat:@"%@",[model valueForKey:proKey]];
        }
    }
    if(params!=nil){
        [updateSQL appendString:@" where "];
    }
    NSArray * allkeys=[params allKeys];
    for (int i=0; i < allkeys.count; i++) {
        if(i!=0){
            [updateSQL appendFormat:@"and"];
        }
        if([[params objectForKey:allkeys[i]] isKindOfClass:[NSString class]]){
            [updateSQL appendFormat:@"%@ = '%@'",allkeys[i],[params objectForKey:allkeys[i]]];
        }else{
            [updateSQL appendFormat:@"%@ = %@",allkeys[i],[params objectForKey:allkeys[i]]];
        }
    }
    NSLog(@"%@",updateSQL);
}

#pragma mark - select
-(void)selectWithSql:(NSString *)sql successBlock:(void (^)(FMResultSet * result))success failureBlock:(void (^)(NSError * error))failure{

    NSAssert(sql!=nil, @"SQL IS NIL");

    NSDictionary * userInfo=@{NSLocalizedDescriptionKey:self.fmdb.debugDescription};

    NSError * error=[[NSError alloc]initWithDomain:ERROR_DOMAIN code:1000 userInfo:userInfo];


    FMResultSet * rs =  [self.fmdb executeQuery:sql];
    if (!rs) {
        DDBLog(@"result is nil");
        return ;
    }

    if(success){
        success(rs);
        return;
    }
    if(failure){
        failure(error);
    }
}


-(void)selectWithModel:(id<IMGModelProtrol>)model successBlock:(void (^)(FMResultSet * result))success failureBlock:(void (^)(NSError *))failure{
    NSString * sql = nil;
    if([model respondsToSelector:@selector(selectSql)]){
        sql= [model selectSql];
    }
    [self selectWithSql:sql successBlock:success failureBlock:failure];
}

-(void)selectWithClass:(Class)clazz successBlock:(void (^)(FMResultSet *))success failureBlock:(void (^)(NSError *))failure{
    id <IMGModelProtrol> obj= [[clazz alloc]init];
    [self selectWithModel:obj successBlock:success failureBlock:failure];
}
-(void)selectArrayWithClass:(Class)clazz successBlock:(void (^)(NSArray * array))success failureBlock:(void (^)(NSError * error))failure{
    NSString * selectSql=[self selectSql:clazz];
    __block  NSMutableArray * array=[[NSMutableArray alloc]initWithCapacity:0];
    [self selectWithSql:selectSql successBlock:^(FMResultSet * resultSet) {
        while([resultSet next]){
            [array addObject:[self setValueWithResult:resultSet forClass:clazz]];

        }
        success(array);
    } failureBlock:^(NSError *error) {

    }];
}

#pragma mark --private

-(BOOL)isExistsTable:(NSString *)tablename{
    FMResultSet *rs = [_fmdb executeQuery:@"select count(*) as 'count' from sqlite_master where type ='table' and name = ?", tablename];
    BOOL ret = NO;
    while ([rs next])
    {

        NSInteger count = [rs intForColumn:@"count"];

        if (0 == count)
        {
            ret = NO;
        }
        else
        {
            ret = YES;
        }
    }
    return ret;
}
//drop exists table
-(BOOL)DropExistsTable:(NSString*)tableName{
    if(![self isExistsTable:tableName]){
        return YES;
    }
    NSString *sql = [NSString stringWithFormat:@"drop table %@",tableName];
    BOOL ret = [_fmdb executeUpdate:sql];
    return ret;
}

- (NSString *)tableSql:(NSString *)tablename{

    NSMutableString *sql = [[NSMutableString alloc] init];
    u_int count;
    objc_property_t * properties  = class_copyPropertyList(NSClassFromString(tablename), &count);

    [sql appendFormat:@"create table %@ (",tablename] ;
    for (int i=0; i<count; i++) {
        if (i>0) {
            [sql appendString:@","];
        }
       // u_int outCount;
      //  objc_property_attribute_t * attribute= property_copyAttributeList(properties[i],&outCount);

        const char * propertyName = property_getName(properties[i]);

      //  const char * attributeInfor = property_getAttributes(properties[i]);
        const char * attributeValue = property_copyAttributeValue(properties[i], "T");

        if(strcmp(attributeValue,"i")==0){
            [sql appendFormat:@"%s int",propertyName];
        }else if(strcmp(attributeValue, "f")==0){
            [sql appendFormat:@"%s double",propertyName];
        }else if(strcmp(attributeValue, "@\"NSString\"")==0){
            [sql appendFormat:@"%s text",propertyName];
        }else if (strcmp(attributeValue, "@\"NSNumber\"")==0){
            [sql appendFormat:@"%s text",propertyName];
        }else{
            [sql appendFormat:@"%s text",propertyName];
        }

      //  free(attribute);
    }
    [sql appendString:@")"];
    free(properties);
    return sql;
}
- (NSString * )getValueOfProperty:(objc_property_t ) property  withModel:(id)model{
    const char * propertyInfo= property_getAttributes(property);

    NSArray  * arr          =   [[NSString stringWithUTF8String:propertyInfo] componentsSeparatedByString:@","];
    NSString * att          =   [arr objectAtIndex:0];
    NSString * propertyName =   [NSString stringWithUTF8String:property_getName(property)];

    id value=[model valueForKey:propertyName];
    if([att isEqualToString:@"T@\"NSString\""]){
        return [NSString stringWithFormat:@"'%@'",value];
    }
    if([att isEqualToString:@"T@\"NSNumber\""]){
        return value;
    }
    return value;
}

- (NSString * )getInsertValue:(id )value type:(NSString * )type{

    if([type isEqualToString:@"i"]){

    }else if([type isEqualToString:@"f"]){

    }else if([type isEqualToString:@"@\"NSString\""]){
        return [NSString stringWithFormat:@"'%@'",value];
    }else if ([type isEqualToString:@"@\"NSNumber\""]){
        return  [((NSNumber *)value) stringValue];
    }
    return value;
}
-(NSString *) insertSql:(id)model{

    NSMutableString *sql = [[NSMutableString alloc] init];
    u_int count;

    objc_property_t * properties  = class_copyPropertyList([model class], &count);

    NSString * tablename=NSStringFromClass([model class]);

    [sql appendFormat:@"insert into %@ (",tablename] ;

    for (int i=0; i<count; i++) {
        if (i>0) {
            [sql appendString:@","];
        }
        const char * propertyName = property_getName(properties[i]);
        [sql appendFormat:@"%s",propertyName];
    }

    [sql appendString:@") values ("];

    for (int i=0; i < count; i++) {
        if (i>0) {
            [sql appendString:@","];
        }
        [sql appendFormat:@"%@",[self getValueOfProperty:properties[i] withModel:model]];
    }
    [sql appendString:@")"];

    free(properties);
    return sql;
}

-(NSString *)selectSql:(Class) clazz{

    NSString * tablename=NSStringFromClass(clazz);

    NSMutableString * string=[NSMutableString stringWithFormat:@"select * from %@",tablename];

    return  string;
}
-(id)setValueWithResult:(FMResultSet *)result forClass:(Class)clazz{
    id  model=[[clazz alloc]init];
    int columnCount= [result columnCount];

    for (int i=0; i<columnCount; i++) {
        
        NSString * columnName=[result columnNameForIndex:i];
        
        [model setValue:[result objectForColumnName:columnName] forKey:columnName];

    }
    return  model;
}

-(BOOL)executeSQL:(NSString*)sql{
    [_fmdb executeUpdate:sql withParameterDictionary:nil];
}
@end
