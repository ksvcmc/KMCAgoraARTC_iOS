//
//  ChatViewController.m
//  demo
//
//  Created by 张俊 on 13/07/2017.
//  Copyright © 2017 ksyun. All rights reserved.
//

#import "ChatViewController.h"
#import "KMCNetwork.h"
#import <KMCAgoraARTC/KMCAgoraARTC.h>
#import "MBProgressHUD.h"
#import "UIView+Ext.h"
#import <Masonry/Masonry.h>

#define kScreenWidth   [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight   [[UIScreen mainScreen] bounds].size.height

@interface ChatViewController ()<KMCRtcDelegate>
{
    NSString       *_strRoomName;

    NSTimer        *_timer;
    
    KMCAgoraARTC   *_aRtcKit;
    
    NSMutableArray *_headerSizeArray;
}

@property(nonatomic, strong)UILabel         *roomName;

@property (nonatomic, strong)UIButton       *closeBtn;

//挂断
@property (nonatomic, strong)UIButton       *hangupBtn;

//房间人数
@property (nonatomic, strong)NSMutableArray *roomArray;

//cache header imageview
@property (nonatomic, strong)NSMutableArray *arrayListView;



@end

@implementation ChatViewController

- (instancetype)initWithData:(NSDictionary *)info;
{
    if (self = [super init]){
        _strRoomName = [info valueForKey:@"roomName"];
        self.data = info;
        if (!_headerSizeArray){
            _headerSizeArray = [[NSMutableArray alloc] initWithArray:@[@(300), @(225), @(135), @(135),@(135), @(135), @(100), @(100)]];
        
        }
        if (!_aRtcKit){
            _aRtcKit = [[KMCAgoraARTC alloc] initWithToken:@"4b76ca649544360020b1ad1670e9861c" delegate:self];
        }
        
    }
    return self;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIImage *image = [UIImage imageNamed:@"root_bg"];
    UIImageView *bgView = [[UIImageView alloc] initWithImage:image];
    [self.view addSubview:bgView];
    [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    [bgView setContentScaleFactor:[[UIScreen mainScreen] scale]];
    bgView.contentMode =  UIViewContentModeScaleToFill;
    bgView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:self.roomName];
    [_roomName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(22);
        make.top.mas_equalTo(39);
    }];
    
    [self.view addSubview:self.closeBtn];
    [_closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-22);
        make.centerY.mas_equalTo(_roomName);
    }];
    [self.view addSubview:self.hangupBtn];
    [self.hangupBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.view.mas_bottom).offset(-24);
        make.centerX.mas_equalTo(self.view);
    }];
    
    if (!_timer){
        _timer =  [NSTimer scheduledTimerWithTimeInterval:2.5
                                                   target:self
                                                 selector:@selector(onQueryChatList:)
                                                 userInfo:nil
                                                  repeats:YES];
    }
    
    //show room list
    NSArray *array = [self.data valueForKey:@"chatIdList"];
    [self updateRoomList:array];
    
}


- (NSMutableArray *)arrayListView
{
    if (!_arrayListView){
        _arrayListView = [[NSMutableArray alloc] init];
    }
    return _arrayListView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onClose
{
    //stop timer
    if (_timer && [_timer isValid]){
        [_timer invalidate];
    }
    NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *roomName = [self.data valueForKey:@"roomName"];
    [[KMCNetwork sharedInst] leaveRoom:@{@"roomName":roomName, @"userId":uuid} successBlk:^(NSDictionary *data) {
    
    } OnFailure:^(NSError *error) {
        
        NSLog(@"leave room error:%@", error.localizedDescription);
    }];
    
    [_aRtcKit leaveChannel];
    [self dismissViewControllerAnimated:YES completion:nil];

    
}

- (void)onQueryChatList:(NSTimer *)timer
{
    NSString *roomName = [self.data valueForKey:@"roomName"];
    if (roomName && roomName.length > 0){
        __weak typeof(self) weakSelf = self;
        [[KMCNetwork sharedInst] fetchChatListWithRoomName:roomName successBlk:^(NSDictionary *data) {
            NSArray *array = [data valueForKey:@"chatIdList"];
            if (array){
                NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
                [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    //NSDictionary *tmpItem = [NSJSONSerialization JSONObjectWithData:obj options:kNilOptions error:nil];
                    
                    
                    [tmpArray addObject:obj];
                }];
                
                [weakSelf updateRoomList:tmpArray];
            }
            
        } OnFailure:^(NSError *error) {
            NSLog(@"fetch chat list error :%@", error.localizedDescription);
        }];
    }

}

- (UILabel *)roomName
{
    if (!_roomName){
        _roomName = [[UILabel alloc] init];
        _roomName.font = [UIFont systemFontOfSize:18];
        _roomName.text = [NSString stringWithFormat:@"房间名：%@", _strRoomName] ;
        _roomName.textColor = [UIColor  whiteColor];
    }
    return _roomName;
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


- (UIButton *)hangupBtn
{
    if (!_hangupBtn){
        _hangupBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_hangupBtn setImage:[UIImage imageNamed:@"hangup_btn"] forState:UIControlStateNormal];
        [_hangupBtn addTarget:self action:@selector(onClose) forControlEvents:UIControlEventTouchUpInside];
    }
    return _hangupBtn;
}

//更新房间头像
- (void)updateRoomList:(NSArray *)data
{
    //to be removed
    NSMutableArray *array0 = [[NSMutableArray alloc] init];
    
    //to be refresh
    NSMutableArray *array1 = [[NSMutableArray alloc] init];
    
    [self.arrayListView enumerateObjectsUsingBlock:^(UIImageView *item, NSUInteger idx, BOOL * _Nonnull stop) {
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
    
    NSInteger cnt = data.count;
    CGFloat width = 0;
    if (cnt > 0){
        width  = [_headerSizeArray[cnt-1] integerValue];
    }
    
    [data enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *userId = [obj valueForKey:@"userId"];
        bool isExits = false;
        for (UIImageView *view in self.arrayListView) {
            if ([userId isEqualToString:view.extra]){
                //[array1 addObject:btn];
                isExits = true;
            }
        }
        if (!isExits){
            NSString *thumbUrl = [obj valueForKey:@"headUrl"];
            UIImage *image = [UIImage imageNamed:@"video_header"];
            if (thumbUrl && thumbUrl.length > 0){
                
                NSURL *url = [NSURL URLWithString:thumbUrl];
                if (url){
                    NSData *thumbData = [NSData dataWithContentsOfURL:url];
                    if (thumbData){
                        image = [UIImage imageWithData:thumbData];
                    }
                }
            }
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.frame = CGRectMake(0, 64, width, width);
            imageView.center = self.view.center;
            imageView.extra = userId;
            [array1 addObject:imageView];
        }
        
    }];
    
    dispatch_block_t block = ^{
        [array0 enumerateObjectsUsingBlock:^(UIButton  *  obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
        [self.arrayListView removeObjectsInArray:array0];
        [self.arrayListView addObjectsFromArray:array1];
        
        [UIView animateWithDuration:0.4 animations:^{
            //only one
            if (cnt == 1){
                
                UIImageView *imageView = self.arrayListView[0];
                if (![self.view.subviews containsObject:imageView]){
                    [self.view addSubview:imageView];
                }
                
                imageView.frame =  CGRectMake(0, 180, width, width);
                imageView.center = CGPointMake(kScreenWidth/2, width/2 + 184);
                
            }
            //two
            else if (cnt == 2){
                UIImageView *imageView0 = self.arrayListView[0];
                if (![self.view.subviews containsObject:imageView0]){
                    [self.view addSubview:imageView0];
                }
                imageView0.frame =  CGRectMake(0, 90, width, width);
                imageView0.center = CGPointMake(kScreenWidth/2, width/2 + 90);
                
                UIImageView *imageView1 = self.arrayListView[1];
                if (![self.view.subviews containsObject:imageView1]){
                    [self.view addSubview:imageView1];
                }
                imageView1.frame =  CGRectMake(0, 180, width, width);
                imageView1.center = CGPointMake(kScreenWidth/2, 90 + width + 25 + width/2);
            }
            else{
                //over two
                int padding = (kScreenWidth - 2*width - 25)/2;
                bool isOdd = (cnt%2==1);
                
                for (int i = 0, j = 0 ; i < ceil(self.arrayListView.count*1.0/2); i++) {
                    
                    CGFloat offset_w = padding + width/2;
                    CGFloat offset_h = 90 + width/2 + (width + 25)*i;
                    
                    UIImageView *imageView0, *imageView1;
                    imageView0 = self.arrayListView[j++];
                    if (![self.view.subviews containsObject:imageView0]){
                        [self.view addSubview:imageView0];
                    }
                    imageView0.frame =  CGRectMake(0, 0, width, width);
                    if (isOdd && j >= cnt - 1 ){
                        imageView0.center = CGPointMake(kScreenWidth/2, offset_h);
                        break;
                    }else{
                        
                        imageView0.center = CGPointMake(offset_w, offset_h);
                        imageView1        = self.arrayListView[j++];
                        if (![self.view.subviews containsObject:imageView1]){
                            [self.view addSubview:imageView1];
                        }
                        imageView1.frame  = CGRectMake(0, 0, width, width);
                        imageView1.center = CGPointMake(offset_w + 25 + width, offset_h);
                        
                    }
                    
                }
            }
            
            
        }];
    };
    if ([NSThread isMainThread]){
        block();
    }else{
        dispatch_sync(dispatch_get_main_queue(), block);
    }
    
    
}

- (void)authSuccess:(KMCAgoraARTC *)sender
{
    //join
    if (sender){
        [sender joinChannel:_strRoomName uid:0];
    }
}

- (void)authFailure:(AuthorizeError)iErrorCode
{
    [self toast:[NSString stringWithFormat:@"出错了, 错误码:%@", @(iErrorCode)]];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraRtcErrorCode)errorCode
{
    //TODO FIXME
}

- (void)toast:(NSString *)msg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = msg;
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:2.f];
    });
}



@end
