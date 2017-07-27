//
//  WYModelSerialization.h
//  WYKitTDemo
//
//  Created by yingwang on 2017/6/29.
//  Copyright © 2017年 GeorgeWang03. All rights reserved.
//
//  <#文件功能#>
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const kWYModelSerializationNameKey;
FOUNDATION_EXPORT NSString * const kWYModelSerializationRemarkKey;
FOUNDATION_EXPORT NSString * const kWYModelSerializationTypeKey;

FOUNDATION_EXPORT NSString * const kWYModelSerializationPropertyTextKey;
FOUNDATION_EXPORT NSString * const kWYModelSerializationSubpropertyArrayKey;

typedef NS_OPTIONS(NSInteger, WYModelReadingOptions) {
    WYModelReadingDefault = (1UL << 0)
};
typedef void(^WYModelSerilizationCompletionBlock)(id obj, BOOL success, NSError *error);

@interface WYModelSerialization : NSObject

+ (void)modelPropertyListFromXMLTextString:(NSString *)xmlTextString complete:(WYModelSerilizationCompletionBlock)block;

@end
