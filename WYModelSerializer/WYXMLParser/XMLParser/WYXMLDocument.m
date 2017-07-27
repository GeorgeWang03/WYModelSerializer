//
//  WYXMLDocument.m
//  WYKitTDemo
//
//  Created by yingwang on 16/1/3.
//  Copyright © 2016年 GeorgeWang03. All rights reserved.
//

#import "WYXMLDocument.h"
#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/xpath.h>
#import <libxml/xmlreader.h>

static NSString * const kWYXMLDocumentErrorDomain = @"kWYXMLDocumentErrorDomain";
NSString * const kWYXMLDocumentNodeNameKey = @"kWYXMLDocumentNodeNameKey";
NSString * const kWYXMLDocumentNodeContentKey = @"kWYXMLDocumentNodeContentKey";
NSString * const kWYXMLDocumentChildNodeKey = @"kWYXMLDocumentChildNodeKey";
NSString * const kWYXMLDocumentPropertyKey = @"kWYXMLDocumentPropertyKey";
NSString * const kWYXMLDocumentNameSpaceKey = @"kWYXMLDocumentNameSpaceKey";

@interface WYXMLDocument ()
{
    xmlDocPtr _privateDoc;
}


@end

@implementation WYXMLDocument

- (instancetype)initWithData:(NSData *)xmlData {
    self = [super init];
    if (self) {
        _privateDoc = xmlParseMemory((const char*)xmlData.bytes, (int)xmlData.length);
        
        NSAssert(_privateDoc!=NULL, @"WYXMLDocument: parse xml data failed");
        if (!_privateDoc) {
            return nil;
        }
    }
    return self;
}

- (NSArray *)readAllElementWithBaseXPath:(NSString *)xpath {
    return [self readElement:nil baseXPath:xpath];
}

- (NSArray *)readElement:(NSDictionary *)element baseXPath:(NSString *)xpath {
    
    NSMutableArray *elements;
    NSDictionary *eleDic;
    
    CFDictionaryRef desElementDictionary;
    
    xmlXPathContextPtr pathCtxt;
    xmlXPathObjectPtr pathObj;
    
    NSError *error;
    
    elements = [NSMutableArray array];
    pathCtxt = xmlXPathNewContext(_privateDoc);
    NSAssert(pathCtxt!=NULL, @"WYXMLDocument: craete xpath context failed");
    if (!pathCtxt) {
        return nil;
    }
    
    if (xpath.length == 0) xpath = @"/";
    pathObj = xmlXPathEvalExpression((const xmlChar*)[xpath UTF8String], pathCtxt);
    NSAssert(pathObj!=NULL, @"WYXMLDocument: craete xpath object failed");
    if (!pathObj) {
        return nil;
    }
    //put elements in a dictionary as a hash table, which more effectively than array when searching
    desElementDictionary = NULL;
    if (element&&element.count) {
        desElementDictionary = _getCFDictionaryFromNSDictionary(element, &error);
    }
    
    if (!error) {
        //enumerate result elements base on the xpath
        
        //if xpath begin at root, the first nodeTab is a node without name
        //we ignore it, and visit its children
        if ([xpath isEqualToString:@"/"] && pathObj->nodesetval->nodeNr) {
            xmlNodePtr childNode = (xmlNodePtr)pathObj->nodesetval->nodeTab[0]->children;
            while (childNode != NULL) {
                eleDic = [self _getDestinationElements:desElementDictionary
                                              baseNode:childNode
                                      includeChildNode:YES];
                [elements addObject:eleDic];
                childNode = childNode->next;
            }
            
        } else {
            for (int i=0; i<pathObj->nodesetval->nodeNr; i++) {
                eleDic = [self _getDestinationElements:desElementDictionary
                                              baseNode:(xmlNodePtr)pathObj->nodesetval->nodeTab[i]
                                      includeChildNode:YES];
                [elements addObject:eleDic];
            }
        }
    }
    
    xmlXPathFreeContext(pathCtxt);
    xmlXPathFreeObject(pathObj);
    return elements;
}

static WYXMLParseElementOption _getElementOption(CFTypeRef obj) {
    
    if (!obj) {
        return kWYXMLParseElementUnknow;
    }
    
    CFTypeID objType = CFGetTypeID(obj);
    if (CFNumberGetTypeID()==objType) {
        WYXMLParseElementOption option;
        CFNumberGetValue(obj, kCFNumberIntType, &option);
        return option;
    } else if(CFDictionaryGetTypeID()==objType) {
        return kWYXMLParseElementSubelement;
    }
    return kWYXMLParseElementUnknow;
}

static CFDictionaryRef _getCFDictionaryFromNSDictionary(NSDictionary *originDictionary,__autoreleasing NSError **error) {
    
    if (!originDictionary) {
        return NULL;
    }
    __block CFMutableDictionaryRef resultDictionary = NULL;
    
    resultDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, (CFIndex)originDictionary.count, &kCFTypeDictionaryKeyCallBacks, NULL);
    
    [originDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSNumber class]]) {
            CFNumberRef num = (__bridge void*)obj;
            CFDictionarySetValue(resultDictionary, (__bridge CFStringRef)key, num);
        } else if([obj isKindOfClass:[NSDictionary class]]) {
            
            CFDictionarySetValue(resultDictionary, (__bridge CFStringRef)key, _getCFDictionaryFromNSDictionary(obj,error));
            if (*error) {
                resultDictionary = NULL;
                *stop = YES;
            }
        } else {
            static NSString *errormsg = @"Can not parse a value unless NSString or NSDictionary";
            NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:errormsg, NSLocalizedDescriptionKey, nil];
            *error = [NSError errorWithDomain:kWYXMLDocumentErrorDomain code:-1 userInfo:errorInfo];
            *stop = YES;
            resultDictionary = NULL;
        }
    }];
    
    return resultDictionary;
}

- (id)_getDestinationElements:(CFDictionaryRef)elements
                     baseNode:(xmlNodePtr)node
             includeChildNode:(BOOL)includeChildNode {
    
    if(!node||!node->children)
        return nil;
    //if the cur node just contained a text node or a cdata node,
    //that means it is a element without any children but a seq of text,
    //so return the text
//    if(node->children->type==XML_TEXT_NODE&&!node->children->next) {
//        return [NSString stringWithUTF8String:(const char*)xmlNodeGetContent(node->children)];
//    }
//    if(node->children->type==XML_CDATA_SECTION_NODE&&!node->children->next) {
//        return [NSString stringWithUTF8String:(const char*)xmlNodeGetContent(node->children)];
//    }
    
    NSMutableDictionary *nodeInfo = [NSMutableDictionary dictionary];
    
    NSString *nodeName = [NSString stringWithUTF8String:(const char*)node->name];;
    if (nodeName) nodeInfo[kWYXMLDocumentNodeNameKey] = nodeName;
    
    // get properties
    id properties;
    if (node->properties != NULL) {
        properties = [self _getPropertiesWithAttrNode:node->properties];
        nodeInfo[kWYXMLDocumentPropertyKey] = properties;
    }
    
    xmlNodePtr childNode = node->children;
    
    id value;
    id childNodeArray;
    
    while (includeChildNode && childNode) {
        
        ///////////
        // fetch data //////////
        ///////////
        const xmlChar* elementName = childNode->name;
        //a cdata node only return the cdata text
        if(childNode->type==XML_TEXT_NODE
           ||childNode->type==XML_CDATA_SECTION_NODE) {
            elementName = (const xmlChar*)"text";
            value = [NSString stringWithUTF8String:(const char*)childNode->content];
        }
        else if (childNode->type==XML_ELEMENT_NODE) {
            if (!childNodeArray) childNodeArray = [NSMutableArray array];
            
            // get child node
            
            if(elements == NULL) {
                id node = [self _getDestinationElements:NULL
                                             baseNode:childNode
                                       includeChildNode:YES];
                [childNodeArray addObject:node];
            } else {
                CFStringRef str = CFStringCreateWithCString(kCFAllocatorDefault, (const char*)elementName, kCFStringEncodingUTF8);
                CFTypeRef obj = CFDictionaryGetValue(elements, str);
                WYXMLParseElementOption opt = _getElementOption(obj);
                switch (opt) {
                    case kWYXMLParseElementSubelement:{
                        id node = [self _getDestinationElements:obj
                                                     baseNode:childNode
                                               includeChildNode:YES];
                        [childNodeArray addObject:node];
                    }
                        break;
                    case kWYXMLParseElementAll:
                    case kWYXMLParseElementText:{
                        obj = NULL;
                        id node = [self _getDestinationElements:obj
                                                     baseNode:childNode
                                             includeChildNode:NO];
                        [childNodeArray addObject:node];
                    }
                        break;
                    default:
                        break;
                }
            }
            
            
        }
        
        
        childNode = childNode->next;
    }
    
    ///////////
    // save data //////////
    ///////////
    
    if (value) {
        [nodeInfo setObject:value forKey:kWYXMLDocumentNodeContentKey];
        
    }
    
    if (childNodeArray) {
        [nodeInfo setObject:childNodeArray forKey:kWYXMLDocumentChildNodeKey];
    }
    
    return nodeInfo;
}

- (id)_getPropertiesWithAttrNode:(xmlAttrPtr)attrNode {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    
    while (attrNode != NULL && attrNode->type == XML_ATTRIBUTE_NODE) {
        NSString *attrName = [NSString stringWithUTF8String:(const char*)attrNode->name];
        NSString *content;
        
        xmlNodePtr textNode = attrNode->children;
        if (textNode != NULL && textNode->type == XML_TEXT_NODE) {
            content = [NSString stringWithUTF8String:(const char*)textNode->content];
        }
        
        if (content && attrName) {
            properties[attrName] = content;
        }
        
        attrNode = attrNode->next;
    }
    
    return properties;
}

//构建字符串哈希表优化
//- (BOOL)_isElement:(const char*)name memberOfElements:(NSDictionary *)elements {
//   
//    if (!elements||elements.count<1) {
//        return NO;
//    }
//    __block BOOL result = NO;
//    [elements enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        const char* givenName = [(NSString *)obj UTF8String];
//        if (!strcmp(givenName, name)) {
//            result = YES;
//            *stop = YES;
//        }
//    }];
//    return result;
//}

- (void)dealloc {
    _privateDoc!=NULL?:xmlFreeDoc(_privateDoc);
}

@end
