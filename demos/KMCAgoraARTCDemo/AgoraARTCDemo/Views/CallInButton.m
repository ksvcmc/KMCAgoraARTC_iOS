//
//  CallInButton.m
//  demo
//
//  Created by 张俊 on 21/07/2017.
//  Copyright © 2017 ksyun. All rights reserved.
//

#import "CallInButton.h"
#import "UIImage+Ext.h"

@interface CallInButton(){

}

@property (nonatomic, strong)UIImageView *badgeView;

@end

@implementation CallInButton

//+ (CallInButton *)create
//{
//    CallInButton *btn = [[CallInButton alloc] initWithFrame:CGRectMake(0, 0, 46, 46)];
//    [btn setImage:[UIImage imageNamed:@"close_btn"] forState:UIControlStateNormal];
//    [btn addTarget:self action:@selector(onEvent:) forControlEvents:UIControlEventTouchUpInside];
//    
//    return btn;
//}

- (instancetype)initWithFrame:(CGRect)frame canHangUp:(BOOL)canHangUp
{
    if (self = [super initWithFrame:frame]){
        //add badge
        if (canHangUp){
            [self.badgeView setImage:[UIImage imageNamed:@"hangupicon"]];
        }else{
            [self.badgeView setImage:[UIImage imageNamed:@"callinicon"]];
        }
        
        CGRect tmpFrame = CGRectMake(26, 26, 27, 27);
        self.badgeView.frame = tmpFrame;
        [self addSubview:self.badgeView];
        
    }
    return self;
}

- (void)setImage:(nullable UIImage *)image forState:(UIControlState)state
{
    UIImage *dstImage = [image imageWithCornerRadius:23];
    
    [super setImage:dstImage forState:state];
    
}

- (UIImageView *)badgeView
{
    if (!_badgeView){
        _badgeView = [[UIImageView alloc] init];
    }
    return _badgeView;
}


@end
