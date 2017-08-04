//
//  BaseViewController.h
//  demo
//
//  Created by 张俊 on 19/07/2017.
//  Copyright © 2017 ksyun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CallInButton.h"
#import "UIView+Ext.h"
#define kScreenWidth    [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight   [[UIScreen mainScreen] bounds].size.height


@interface BaseViewController : UIViewController

- (instancetype)initWithData:(NSDictionary *)data;

//更新连麦列表
- (void)updateRoom:(NSArray *)data;

//方法类创建上麦的图标
- (CallInButton *)createCallInIcon:(NSString *)userId;

- (void)onClose;

@property (nonatomic, strong)NSDictionary  *data;

@property (nonatomic, strong)UIImageView   *headerView;

@property (nonatomic, strong)UILabel       *nickName;

@property (nonatomic, strong)UIButton      *closeBtn;

@property (nonatomic, strong)UIButton      *callBtn;

@property (nonatomic, strong)NSURL         *streamUrl;

//连麦控件
@property(nonatomic, strong)NSMutableArray *onCallBtns;

@end
