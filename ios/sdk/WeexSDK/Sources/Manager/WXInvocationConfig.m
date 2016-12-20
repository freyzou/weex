/**
 * Created by Weex.
 * Copyright (c) 2016, Alibaba, Inc. All rights reserved.
 *
 * This source code is licensed under the Apache Licence 2.0.
 * For the full copyright and license information,please view the LICENSE file in the root directory of this source tree.
 */

#import "WXInvocationConfig.h"
#import "WXLog.h"
#import "WXSDKInstance.h"
#import "WXSDKManager.h"
#import "WXSDKInstance_private.h"
#import "WXMonitor.h"
#import "WXSDKError.h"
#import "WXComponentFactory.h"
#import "WXModuleFactory.h"
#import "WXUtility.h"

#import <objc/runtime.h>

@interface WXInvocationConfig()
@end

@implementation WXInvocationConfig

+ (instancetype)sharedInstance
{
    static id _sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (instancetype)init
{
    
    if (self = [super init]) {
        _methods = [NSMutableDictionary new];
    }
    
    return self;
}

- (instancetype)initWithName:(NSString *)name class:(NSString *)clazz
{
    if (self = [super init]) {
        _methods = [NSMutableDictionary new];
        _name = name;
        _clazz = clazz;
    }
    return self;
}

- (void)registerMethods
{
    Class currentClass = NSClassFromString(_clazz);
    
    if (!currentClass) {
        WXLogWarning(@"The module class [%@] doesn't exit！", _clazz);
        return;
    }
    
    while (currentClass != [NSObject class]) {
        unsigned int methodCount = 0;
        Method *methodList = class_copyMethodList(object_getClass(currentClass), &methodCount);
        for (unsigned int i = 0; i < methodCount; i++) {
            NSString *selStr = [NSString stringWithCString:sel_getName(method_getName(methodList[i])) encoding:NSUTF8StringEncoding];
            
            if (![selStr hasPrefix:@"wx_export_method_"]) continue;
            
            NSString *name = nil, *method = nil;
            SEL selector = NSSelectorFromString(selStr);
            if ([currentClass respondsToSelector:selector]) {
                method = ((NSString* (*)(id, SEL))[currentClass methodForSelector:selector])(currentClass, selector);
            }
            
            if (method.length <= 0) {
                WXLogWarning(@"The module class [%@] doesn't has any method！", _clazz);
                continue;
            }
            
            NSRange range = [method rangeOfString:@":"];
            if (range.location != NSNotFound) {
                name = [method substringToIndex:range.location];
            } else {
                name = method;
            }
            
            [_methods setObject:method forKey:name];
        }
        
        free(methodList);
        currentClass = class_getSuperclass(currentClass);
    }
    
}


@end
