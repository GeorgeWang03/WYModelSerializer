//
//  WYModelSerialization.m
//  WYKitTDemo
//
//  Created by yingwang on 2017/6/29.
//  Copyright © 2017年 GeorgeWang03. All rights reserved.
//
//  <#文件功能#>
//

#import "WYModelSerialization.h"
#import "WYXMLParserManager.h"

NSString * const kWYModelSerializationNameKey = @"kWYModelSerializationNameKey";
NSString * const kWYModelSerializationRemarkKey = @"kWYModelSerializationRemarkKey";
NSString * const kWYModelSerializationTypeKey = @"kWYModelSerializationTypeKey";

NSString * const kWYModelSerializationPropertyTextKey = @"kWYModelSerializationPropertyTextKey";
NSString * const kWYModelSerializationSubpropertyArrayKey = @"kWYModelSerializationSubpropertyArrayKey";

@interface WYModelSerialization ()

@end


static NSString *propertyTextFromWYModelSerializerResult(NSArray<NSDictionary *> *nodes) {
    
    if (nodes.count == 0) {
        return nil;
    }
    
    NSMutableString *logString = [NSMutableString stringWithString:@"\n\n"];
    [nodes enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *remarkPrefix = [NSString stringWithFormat:@"/**\n %@\n */", obj[kWYModelSerializationRemarkKey]];
        NSString *propertyString = [NSString stringWithFormat:@"@property (nonatomic, strong) NSString *%@;", obj[kWYModelSerializationNameKey]];
        [logString appendFormat:@"%@\n%@\n\n", remarkPrefix, propertyString];
        
    }];
    
    return logString;
}

static NSArray *propertyModelFromWYXMLResult(NSArray<NSDictionary *> *result) {
    if (!result.count) {
        return @[];
    }
    
    NSMutableArray *properties = [NSMutableArray array];
    
    [result enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *nodeInfo = [NSMutableDictionary dictionary];
        
        NSString *nodeName = obj[kWYXMLDocumentNodeNameKey];
        if (![nodeName isEqualToString:@"attr"]) {
            nodeInfo[kWYModelSerializationNameKey] = nodeName;
            nodeInfo[kWYModelSerializationSubpropertyArrayKey] = propertyModelFromWYXMLResult(obj[kWYXMLDocumentChildNodeKey]);
            if (obj[kWYXMLDocumentPropertyKey][@"remark"]) nodeInfo[kWYModelSerializationRemarkKey] = obj[kWYXMLDocumentPropertyKey][@"remark"];
        } else {
            if (obj[kWYXMLDocumentPropertyKey][@"name"]) nodeInfo[kWYModelSerializationNameKey] = obj[kWYXMLDocumentPropertyKey][@"name"];
            if (obj[kWYXMLDocumentNodeContentKey]) nodeInfo[kWYModelSerializationRemarkKey] = obj[kWYXMLDocumentNodeContentKey];
        }
        
        
        NSString *propertyText = propertyTextFromWYModelSerializerResult(nodeInfo[kWYModelSerializationSubpropertyArrayKey]);
        if (propertyText) nodeInfo[kWYModelSerializationPropertyTextKey] = propertyText;
        [properties addObject:nodeInfo];
    }];
    
    return properties;
}


@implementation WYModelSerialization

+ (void)modelObjectWithData:(NSData *)data options:(WYModelReadingOptions)opt complete:(WYModelSerilizationCompletionBlock)block{
    
    WYXMLParserContext *ctx = [[WYXMLParserContext alloc] init];
    ctx.xpath = @"/areas";
    [[WYXMLParserManager manager] parseXMLWithData:data context:ctx completeBlock:^(BOOL isSuccess, id obj, NSError *error) {
        if (!obj || error) {
            block(nil,NO,error);
            return;
        }
        NSMutableDictionary *tpDic = [NSMutableDictionary dictionaryWithDictionary:obj];
        
        NSMutableArray *properties = [NSMutableArray array];
        NSArray *childNode = tpDic[kWYXMLDocumentChildNodeKey];
        for (NSDictionary *node in childNode) {
            NSMutableDictionary *nodeInfo = [NSMutableDictionary dictionary];
            if (node[kWYXMLDocumentNodeContentKey]) nodeInfo[kWYModelSerializationRemarkKey] = node[kWYXMLDocumentNodeContentKey];
            if (node[kWYXMLDocumentPropertyKey][@"name"]) nodeInfo[kWYModelSerializationNameKey] = node[kWYXMLDocumentPropertyKey][@"name"];
            [properties addObject:nodeInfo];
        }
        
        block(properties, isSuccess, error);
    }];
}

+ (void)modelPropertyListFromXMLTextString:(NSString *)xmlTextString complete:(WYModelSerilizationCompletionBlock)block {
    
    const char *uString = [xmlTextString UTF8String];
    NSData *data = [NSData dataWithBytes:uString length:strlen(uString)];
    
    WYXMLParserContext *ctx = [[WYXMLParserContext alloc] init];
    ctx.xpath = @"";
    [[WYXMLParserManager manager] parseXMLWithData:data context:ctx completeBlock:^(BOOL isSuccess, id obj, NSError *error) {
        if (!obj || error) {
            block(nil,NO,error);
            return;
        }
        
        id result;
        if ([obj isKindOfClass:[NSArray class]]) {
            result = obj;
        } else {
            result = @[obj];
        }
        
        NSArray *properties = propertyModelFromWYXMLResult(result);
        
        block(properties, isSuccess, error);
    }];
}

@end
