//
//  UIImage+Ext.m
//  demo
//
//  Created by 张俊 on 21/07/2017.
//  Copyright © 2017 ksyun. All rights reserved.
//

#import "UIImage+Ext.h"

@implementation UIImage (Ext)


-(UIImage*)imageWithCornerRadius:(CGFloat)radius
{

    CGRect rect = CGRectMake(0, 0, radius*2, radius*2);
    
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(radius*2, radius*2), NO, 0);
    
    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius] addClip];
    
    [self drawInRect:rect];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

@end
