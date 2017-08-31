//
//  ViewController.m
//  AgoraARTCDemo
//
//  Created by 张俊 on 11/07/2017.
//  Copyright © 2017 ksyun. All rights reserved.
//

#import "RootViewController.h"
#import <Masonry/Masonry.h>
#import "MBProgressHUD.h"
#import "KMCNetwork.h"
#import "AnchorViewController.h"
#import "SpectatorViewController.h"
#import "ChatViewController.h"
#import "UIColor+Expanded.h"
#import "NemoAboutView.h"
#import "KMCAgoraStreamerKit.h"


#define SCREEN_SIZE [[UIScreen mainScreen] bounds].size

#define kScreenSizeHeight (SCREEN_SIZE.height)
#define kScreenSizeWidth (SCREEN_SIZE.width)

@interface RootViewController ()<UITextFieldDelegate>{
    KSYReachability *_reach;
}

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UIButton * enterARtcLive;
@property (nonatomic, strong) UIButton * enterAChatLive;
@property (nonatomic, strong) UIButton * helpButton;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view).offset(116);
        make.centerX.mas_equalTo(self.view);
    }];
    
    [self.view addSubview:self.titleField];
    [self.titleField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(61);
        make.leading.mas_equalTo(self.view).offset(20);
        make.trailing.mas_equalTo(self.view).offset(-20);
        make.height.mas_equalTo(50);
    }];
    
    [self.view addSubview:self.enterAChatLive];
    [self.enterAChatLive mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleField.mas_bottom).offset(50);
        make.leading.mas_equalTo(self.view).offset(77);
        make.trailing.mas_equalTo(self.view).offset(-77);
        make.height.mas_equalTo(44);
    }];
    
    [self.view addSubview:self.enterARtcLive];
    [self.enterARtcLive mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.enterAChatLive.mas_bottom).offset(50);
        make.leading.mas_equalTo(self.view).offset(77);
        make.trailing.mas_equalTo(self.view).offset(-77);
        make.height.mas_equalTo(44);
    }];
    
    [self.view addSubview:self.helpButton];
    [self.helpButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-27);
        make.height.mas_equalTo(18);
        make.width.mas_equalTo(150);
    }];
    
    _reach = [KSYReachability reachabilityWithHostName:@"http://www.baidu.com"];
    //[_reach startNotifier];
}

-(UILabel *)titleLabel{
    if(!_titleLabel){
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"声网语音连麦demo";
        _titleLabel.font = [UIFont systemFontOfSize:20];
        _titleLabel.textColor = [UIColor whiteColor];
    }
    return _titleLabel;
}

- (UITextField *)titleField
{
    if (!_titleField){
        _titleField = [[UITextField alloc] init];
        _titleField.textColor = [UIColor whiteColor];
        _titleField.tintColor = [UIColor colorWithRed:0.431 green:0.471 blue:0.518 alpha:1.00];
        _titleField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"#多人输入相同标题即可进行语音连麦#" attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.431 green:0.471 blue:0.518 alpha:1.00]}];
        _titleField.layer.cornerRadius = 4;
        _titleField.backgroundColor = [UIColor colorWithRed:0.373 green:0.392 blue:0.624 alpha:.2];
        _titleField.font = [UIFont systemFontOfSize:16];
        _titleField.keyboardType = UIKeyboardTypeDefault;
        _titleField.leftViewMode = UITextFieldViewModeAlways;
        _titleField.delegate = self;
        [_titleField sizeToFit];
        UIView *padView = [[UIView alloc] init];
        CGRect frame = _titleField.frame;
        frame.size.width = 20;
        padView.frame = frame;
        _titleField.leftView = padView;
        
    }
    return _titleField;
}

-(UIButton*)helpButton{
    if(!_helpButton){
        _helpButton = [[UIButton alloc] init];
        [_helpButton setImage:[UIImage imageNamed:@"help"] forState:UIControlStateNormal];
        [_helpButton setTitle:@"Demo说明" forState:UIControlStateNormal];
        [_helpButton setTintColor:[UIColor whiteColor]];
        [_helpButton addTarget:self action:@selector(help) forControlEvents:UIControlEventTouchUpInside];
        _helpButton.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0);
    }
    return _helpButton;
}

- (UIButton *)enterARtcLive
{
    if (!_enterARtcLive){
        _enterARtcLive = [UIButton buttonWithType:UIButtonTypeCustom];
        _enterARtcLive.layer.cornerRadius = 20;
        _enterARtcLive.layer.borderWidth = 1;
        _enterARtcLive.layer.borderColor = [UIColor whiteColor].CGColor;
        [_enterARtcLive setTitle:@"进入直播语音连麦" forState:UIControlStateNormal];
        _enterARtcLive.titleLabel.font = [UIFont systemFontOfSize: 16.0];
        [_enterARtcLive addTarget:self action:@selector(onARTCClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _enterARtcLive;
}

- (UIButton *)enterAChatLive
{
    if (!_enterAChatLive){
        _enterAChatLive = [UIButton buttonWithType:UIButtonTypeCustom];
        _enterAChatLive.layer.cornerRadius = 20;
        _enterAChatLive.layer.borderWidth = 1;
        _enterAChatLive.layer.borderColor = [UIColor whiteColor].CGColor;
        [_enterAChatLive setTitle:@"进入聊天室语音连麦" forState:UIControlStateNormal];
        _enterAChatLive.titleLabel.font = [UIFont systemFontOfSize: 16.0];
        [_enterAChatLive addTarget:self action:@selector(onChatClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _enterAChatLive;
}

-(void)help{
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithFrame:CGRectMake(0, 0, kScreenSizeWidth, kScreenSizeHeight)];
    hud.color = [UIColor colorWithHexString:@"#18181d" alpha:0.4];
    [self.view.window addSubview:hud];
    hud.mode = MBProgressHUDModeCustomView;
    NemoAboutView *aboutView = [[NemoAboutView alloc] initWithFrame:self.view.window.bounds];
    aboutView.hud = hud;
    hud.customView = aboutView;
    [hud show:YES];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}


- (void)onARTCClick:(id)sender
{
    
    if (!self.titleField.text || self.titleField.text.length == 0){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"请输入标题" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        [alert show];
    }else{
        if([_reach currentReachabilityStatus] == KSYNotReachable){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"网络异常，请稍后重试" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        [[KMCNetwork sharedInst] joinRoom:@{@"roomName":self.titleField.text, @"userId":uuid} successBlk:^(NSDictionary *data) {
            id userType = [data valueForKey:@"userType"];
            if (userType){
                
                NSMutableDictionary *tmpData = [[NSMutableDictionary alloc] initWithDictionary:data];
                [tmpData setValue:self.titleField.text forKey:@"roomName"];
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:(BOOL)YES];
                    BaseViewController *vc = nil;
                    if ([userType integerValue] == 1){
                        NSLog(@"主播上线");
                        vc = [[AnchorViewController alloc] initWithData:tmpData];
                    }else{
                        NSLog(@"观众上线");
                        vc = [[SpectatorViewController alloc] initWithData:tmpData];
                    }
                    if (vc){
                        
                        [self presentViewController:vc animated:YES completion:nil];
                    }
                });
                
                
            }
        } OnFailure:^(NSError *error) {
            NSLog(@"join error:%@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:(BOOL)YES];
            });
            
        }];
        
        //        ChatViewController *vc = [[ChatViewController alloc] initWithRoomName:self.titleField.text];
        //        [self presentViewController:vc animated:YES completion:nil];
    }
    
}

- (void)onChatClick:(id)sender
{
    
    if (!self.titleField.text || self.titleField.text.length == 0){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"请输入标题" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        [alert show];
    }else{
        
        if([_reach currentReachabilityStatus] == KSYNotReachable){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"网络异常，请稍后重试" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        [[KMCNetwork sharedInst] joinMultiRoom:@{@"roomName":self.titleField.text, @"userId":uuid} successBlk:^(NSDictionary *data) {
            
            NSMutableDictionary *tmpData = [[NSMutableDictionary alloc] initWithDictionary:data];
            [tmpData setValue:self.titleField.text forKey:@"roomName"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [MBProgressHUD hideHUDForView:self.view animated:(BOOL)YES];
                
                ChatViewController *vc = [[ChatViewController alloc] initWithData:tmpData];
                [self presentViewController:vc animated:YES completion:nil];
            });
        } OnFailure:^(NSError *error) {
            NSLog(@"join error:%@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:(BOOL)YES];
            });
            
        }];
    }
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -- UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (range.length + range.location > textField.text.length) {
        return NO;
    }
    NSUInteger newLength = textField.text.length + string.length - range.length;
    return newLength<= 32;
}

@end
