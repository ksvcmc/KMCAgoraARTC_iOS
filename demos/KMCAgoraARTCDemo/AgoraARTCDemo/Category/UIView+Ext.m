//
//  UIView+Ext.m
//  demo
//
//  Created by 张俊 on 21/07/2017.
//  Copyright © 2017 ksyun. All rights reserved.
//

#import "UIView+Ext.h"
#import <objc/runtime.h>


@implementation UIView (Ext)


- (NSString *)extra
{
    return objc_getAssociatedObject(self, @selector(extra));
}

- (void)setExtra:(NSString *)extra
{
    objc_setAssociatedObject(self, @selector(extra), extra, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
