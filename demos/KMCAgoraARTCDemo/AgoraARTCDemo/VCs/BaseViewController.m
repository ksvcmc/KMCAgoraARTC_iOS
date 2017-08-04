//
//  BaseViewController.m
//  demo
//
//  Created by 张俊 on 19/07/2017.
//  Copyright © 2017 ksyun. All rights reserved.
//

#import "BaseViewController.h"
#import <Masonry/Masonry.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "KMCNetwork.h"
#import "NSString+Add.h"
@interface BaseViewController ()
{
    NSTimer *_timer;
    
    //直播时长
    NSTimer *_liveTimer;
    
    UInt64   _enterTs;
}

//直播时长
@property (nonatomic, strong)UILabel       *liveTimeLabel;

@end

@implementation BaseViewController


- (instancetype)initWithData:(NSDictionary *)data
{
    if (self = [super init]){
        self.data = data;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIImage *image = [UIImage imageNamed:@"chatroom_bg"];
    UIImageView *bgView = [[UIImageView alloc] initWithImage:image];
    
    [bgView setContentScaleFactor:[[UIScreen mainScreen] scale]];
    bgView.contentMode =  UIViewContentModeScaleToFill;
    bgView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:bgView];
    [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    
    //头像
    [self.view addSubview:self.headerView];
    [self.view addSubview:self.nickName];
    
    [_headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(22);
        make.top.mas_equalTo(45);
        make.width.height.mas_equalTo(40);
    }];
    
    [_nickName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(_headerView.mas_right).offset(12);
        make.centerY.mas_equalTo(_headerView);
    }];
    
    
    [self.view addSubview:self.closeBtn];
    [_closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-22);
        make.centerY.mas_equalTo(_headerView);
    }];
    
    
    UIImage *anchor = [UIImage imageNamed:@"living"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:anchor];
    [self.view addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(22);
        make.top.mas_equalTo(self.view).offset(108);
    }];
    [self.view addSubview:self.liveTimeLabel];
    [_liveTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(imageView.mas_right).offset(10);
        make.centerY.mas_equalTo(imageView);
    }];
    
    [self.view addSubview:self.callBtn];
    [self.callBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.view.mas_bottom).offset(-15);
        make.right.mas_equalTo(self.view.mas_right).offset(-23);
    }];
    
    if (!_timer){
        _timer =  [NSTimer scheduledTimerWithTimeInterval:2.5
                                                   target:self
                                                 selector:@selector(onQueryChatList:)
                                                 userInfo:nil
                                                  repeats:YES];
    }
    
    if (!_liveTimer){
        _liveTimer =  [NSTimer scheduledTimerWithTimeInterval:0.3
                                                   target:self
                                                 selector:@selector(onLiveCount:)
                                                 userInfo:nil
                                                  repeats:YES];
    }
    
    
    
    NSString *anchorNickname = [self.data valueForKey:@"anchorNickname"];
    if (anchorNickname && anchorNickname.length > 0){
        _nickName.text = anchorNickname;
    }
    
    NSString *thumbUrl = [self.data valueForKey:@"anchorHeadUrl"];
    if (thumbUrl && thumbUrl.length > 0){
    
        NSURL *url = [NSURL URLWithString:thumbUrl];
        if (url){
            NSData *thumbData = [NSData dataWithContentsOfURL:url];
            if (thumbData){
                _headerView.image = [UIImage imageWithData:thumbData];
            }
        }
    }
    
    
    _enterTs = [[NSDate date] timeIntervalSince1970];
    
}

- (UIImageView *)headerView
{
    if (!_headerView){
        _headerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"header_default"]];
        _headerView.layer.cornerRadius = 20;
        _headerView.clipsToBounds = YES;
    }
    return _headerView;
}


- (UILabel *)nickName
{
    if (!_nickName){
        _nickName = [[UILabel alloc] init];
        _nickName.font = [UIFont systemFontOfSize:18];
        _nickName.text = @"微微一笑满天花";
        _nickName.textColor = [UIColor  whiteColor];
    }
    return _nickName;
}

- (UIButton *)closeBtn
{
    if (!_closeBtn){
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeBtn setImage:[UIImage imageNamed:@"close_btn"] forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(onClose) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}


- (UILabel *)liveTimeLabel
{
    if (!_liveTimeLabel){
        _liveTimeLabel = [[UILabel alloc] init];
        _liveTimeLabel.textColor = [UIColor whiteColor];
        _liveTimeLabel.font = [UIFont systemFontOfSize:14];
        _liveTimeLabel.text = @"正在直播  00:00:00";
    }
    return _liveTimeLabel;
}


- (UIButton *)callBtn
{
    if (!_callBtn){
        _callBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_callBtn setImage:[UIImage imageNamed:@"call_btn"] forState:UIControlStateNormal];
        [_callBtn addTarget:self action:@selector(onCall:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _callBtn;
}

- (NSMutableArray *)onCallBtns
{
    if (!_onCallBtns){
        _onCallBtns = [[NSMutableArray alloc] init];
    }
    return _onCallBtns;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)onClose
{
    if (_timer && [_timer isValid]){
        [_timer invalidate];
        _timer = nil;
    }
    if (_liveTimer && [_liveTimer isValid]){
        [_liveTimer invalidate];
        _liveTimer = nil;
    }
    
    //leave room
    NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *roomName = [self.data valueForKey:@"roomName"];
    [[KMCNetwork sharedInst] leaveRoom:@{@"roomName":roomName, @"userId":uuid} successBlk:^(NSDictionary *data) {
        
    } OnFailure:^(NSError *error) {
        //TODO
        NSLog(@"leave error:%@", error.localizedDescription);
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
    
}

- (void)onLiveCount:(NSTimer *)timer
{
    UInt64 ts = [[NSDate date] timeIntervalSince1970];
    UInt64 duration = [[self.data valueForKey:@"createTime"] longLongValue];
    _liveTimeLabel.text = [NSString stringWithFormat:@"正在直播  %@",[NSString stringWithHMS:(int)(ts - _enterTs + duration/1000)]];

}

- (void)onQueryChatList:(NSTimer *)timer
{
    NSString *roomName = [self.data valueForKey:@"roomName"];
    if (roomName && roomName.length > 0){
        __weak typeof(self) weakSelf = self;
        [[KMCNetwork sharedInst] fetchChatListWithRoomName:roomName successBlk:^(NSDictionary *data) {
            if ([[data valueForKey:@"isClose"] integerValue]){
                //room not exist, all viewers should be kicked out
                [weakSelf onClose];
                
            }else{
                
                NSArray *array = [data valueForKey:@"chatIdList"];
                if (array){
                    NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
                    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        //NSDictionary *tmpItem = [NSJSONSerialization JSONObjectWithData:obj options:kNilOptions error:nil];
                        [tmpArray addObject:obj];
                    }];
                    
                    [weakSelf updateRoom:tmpArray];
                }
                
            }
            
        } OnFailure:^(NSError *error) {
            NSLog(@"fetch chat list error :%@", error.localizedDescription);
        }];
    }

}
//
//- (void)updateRoom:(NSArray *)data
//{
//    
//}

- (void)updateRoom:(NSArray *)data
{
    //tobe del
    NSMutableArray *array0 = [[NSMutableArray alloc] init];
    NSMutableArray *array1 = [[NSMutableArray alloc] init];
    
    [self.onCallBtns enumerateObjectsUsingBlock:^(UIButton *item, NSUInteger idx, BOOL * _Nonnull stop) {
        __block bool isExits = false;
        [data enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *userId = [dict valueForKey:@"userId"];
            if ([userId isEqualToString:item.extra]){
                isExits = TRUE;
                //exist
                //[unionArray addObject:item];
            }
            
        }];
        if (!isExits){
            [array0 addObject:item];
            
        }
    }];
    
    [data enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *userId = [obj valueForKey:@"userId"];
        bool isExits = false;
        for (UIButton *btn in self.onCallBtns) {
            if ([userId isEqualToString:btn.extra]){
                //[array1 addObject:btn];
                isExits = true;
            }
        }
        if (!isExits){
            UIButton *btn = [self createCallInIcon:userId];
            
            NSString *headerUrl = [obj valueForKey:@"headUrl"];
            
            if (headerUrl && headerUrl.length > 0){
                
                NSURL *url = [NSURL URLWithString:headerUrl];
                if (url){
                    NSData *thumbData = [NSData dataWithContentsOfURL:url];
                    if (thumbData){
                        [btn setImage:[UIImage imageWithData:thumbData] forState:UIControlStateNormal];
                    }
                }
            }
            [array1 addObject:btn];
        }
        
    }];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        [array0 enumerateObjectsUsingBlock:^(UIButton  *  obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
        [self.onCallBtns removeObjectsInArray:array0];
        
        //        if (self.onCallBtns.count > 0) {
        //            if (array1.count == 0){
        //
        //                [self.onCallBtns enumerateObjectsUsingBlock:^(CallInButton  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //                    [obj removeFromSuperview];
        //                }];
        //                return ;
        //            }else{
        //                [self.onCallBtns removeAllObjects];
        //            }
        //
        //        }
        
        
        [self.onCallBtns addObjectsFromArray:array1];
        
        
        [_onCallBtns enumerateObjectsUsingBlock:^(UIButton  * _Nonnull btn, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (![self.view.subviews containsObject:btn]){
                [self.view addSubview:btn];
            }
            [UIView animateWithDuration:0.5 animations:^{
                btn.center = CGPointMake(kScreenWidth - 55, kScreenHeight/2 + idx*(46+30));
            }];
        }];
        
    });
    
    
    
}




@end
