//
//  ViewController.m
//  AgoraARTCDemo
//
//  Created by 张俊 on 11/07/2017.
//  Copyright © 2017 ksyun. All rights reserved.
//

#import "RootViewController.h"
#import "ChatViewController.h"
#import <Masonry/Masonry.h>
#import <MBProgressHUD.h>
#import "KMCNetwork.h"


@interface RootViewController ()

@property (nonatomic, strong) UIButton *enterLive;

@property (nonatomic, strong) UITextField *titleField;

@property (nonatomic, strong) UILabel     *tipLabel;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIImage *image = [UIImage imageNamed:@"root_bg"];
    UIImageView *bgView = [[UIImageView alloc] initWithImage:image];
    [self.view addSubview:bgView];
    [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    [bgView setContentScaleFactor:[[UIScreen mainScreen] scale]];
    bgView.contentMode =  UIViewContentModeScaleToFill;
    bgView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.titleField];
    [_titleField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(@20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(@50);
        make.top.mas_equalTo(215);
        make.centerX.mas_equalTo(self.view);
    }];

    [self.view  addSubview:self.enterLive];
    [_enterLive mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(200);
        make.height.mas_equalTo(40);
        make.top.mas_equalTo(_titleField.mas_bottom).offset(50);
        make.centerX.mas_equalTo(self.view);
    }];
    
    [self.view addSubview:self.tipLabel];
    [_tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(40);
        make.bottom.mas_equalTo(-53);
    }];
    
}

- (UIButton *)enterLive
{
    if (!_enterLive){
        _enterLive = [UIButton buttonWithType:UIButtonTypeCustom];
        _enterLive.backgroundColor = [UIColor colorWithRed:0.494 green:0.827 blue:0.129 alpha:1.00];
        _enterLive.layer.cornerRadius = 20;
        [_enterLive setTitle:@"进入直播" forState:UIControlStateNormal];
        _enterLive.titleLabel.font = [UIFont systemFontOfSize: 16.0];
        [_enterLive addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _enterLive;
}


- (UITextField *)titleField
{
    if (!_titleField){
        _titleField = [[UITextField alloc] init];
        _titleField.textColor = [UIColor whiteColor];
        _titleField.tintColor = [UIColor colorWithRed:0.431 green:0.471 blue:0.518 alpha:1.00];
        _titleField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"#取个拉风的标题吧#" attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.431 green:0.471 blue:0.518 alpha:1.00]}];
        _titleField.layer.cornerRadius = 4;
        _titleField.backgroundColor = [UIColor colorWithRed:0.373 green:0.392 blue:0.624 alpha:.2];
        _titleField.font = [UIFont systemFontOfSize:16];
        _titleField.leftViewMode = UITextFieldViewModeAlways;
        _titleField.keyboardType = UIKeyboardTypeASCIICapable;
        [_titleField sizeToFit];
        UIView *padView = [[UIView alloc] init];
        CGRect frame = _titleField.frame;
        frame.size.width = 20;
        padView.frame = frame;
        _titleField.leftView = padView;
    
    }
    return _titleField;
}

- (UILabel *)tipLabel
{
    if (!_tipLabel){
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.font = [UIFont systemFontOfSize:14];
        _tipLabel.text = @"Tips:\n多人输入相同标题即可进行连麦";
        _tipLabel.textColor = [UIColor colorWithRed:0.431 green:0.471 blue:0.518 alpha:1.00];
        _tipLabel.numberOfLines = 0;
    }
    return _tipLabel;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

- (void)onClick:(id)sender
{
    if (!self.titleField.text || self.titleField.text.length == 0){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"请输入标题" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        [alert show];
    }else{
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        [[KMCNetwork sharedInst] joinRoom:@{@"roomName":self.titleField.text, @"userId":uuid} successBlk:^(NSDictionary *data) {
            
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


@end
