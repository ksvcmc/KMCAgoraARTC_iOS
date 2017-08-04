//
//  SpectatorViewController.m
//  demo
//
//  Created by 张俊 on 19/07/2017.
//  Copyright © 2017 ksyun. All rights reserved.
//

#import "SpectatorViewController.h"
#import <KSYMoviePlayerController.h>
#import <KMCAgoraARTC/KMCAgoraARTC.h>
#import "KMCNetwork.h"
#import "CallInButton.h"
#import <MBProgressHUD.h>

@interface SpectatorViewController ()<KMCRtcDelegate>
{
    NSString *_strUrl;
    BOOL     _isOnCall;
    BOOL     _isKMCAuthSuccess;
    
    KSYMoviePlayerController *_player;
    
    KMCAgoraARTC             *_aRtcKit;

}

@end

@implementation SpectatorViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self p_initPlayer];
    float outputVolume = [[AVAudioSession sharedInstance] outputVolume];
    NSLog(@"outputVolume:%f", outputVolume);
    if (!_aRtcKit){
        _aRtcKit = [[KMCAgoraARTC alloc] initWithToken:@"648e6ec7f957aabde391ebba7f43c1fa" delegate:self];
        
        __weak typeof(self) weakSelf = self;
        _aRtcKit.leaveChannelBlock = ^(AgoraRtcStats* stat){
            NSLog(@"local leave channel volume:%f", [[AVAudioSession sharedInstance] outputVolume]);
            __strong typeof(self) strongSelf = weakSelf;
            
            if (strongSelf && strongSelf->_player){
                
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                                         error:nil];
                
                [strongSelf->_player setVolume:1.0 rigthVolume:1.0];
                [strongSelf->_player play];
            }
        };
        _aRtcKit.joinChannelBlock = ^(NSString *channel, NSUInteger uid, NSInteger elapsed) {
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf && strongSelf->_player && strongSelf->_player.isPlaying){
                [strongSelf->_player pause];
            }
        };
    }
}


- (void)p_initPlayer
{
    NSArray<AVAudioSessionPortDescription *> *outputs = [[[AVAudioSession sharedInstance] currentRoute] outputs];
    for (AVAudioSessionPortDescription * desc in outputs) {
        NSLog(@"portType:%@", [desc portType]);
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
            });
        }
    }
    NSString *roomName = [self.data valueForKey:@"roomName"];
    _strUrl = [NSString stringWithFormat:@"rtmp://test.live.ks-cdn.com/live/%@", roomName];
    _player = [[KSYMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:_strUrl]];
    
    _player.shouldAutoplay = YES;
    [_player setTimeout:30 readTimeout:60];
    _player.bInterruptOtherAudio = YES;
    
    [_player prepareToPlay];


}

- (void)onClose
{
    //TODO if oncall , leave channel first
    if (_isOnCall){
        [self offCallNow];
    }

    //stop player
    if (_player){
        [_player stop];
        _player = nil;
    }
    
    [super  onClose];
}

- (void)updateRoom:(NSArray *)data
{
    [super updateRoom:data];
    if (_isOnCall){
        NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        __block BOOL isExist = FALSE;
        if(self.onCallBtns.count > 0){
            [self.onCallBtns enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.extra isEqualToString:uuid]){
                    isExist = TRUE;
                }
            }];
        }

        if (!isExist){
            _isOnCall = NO;
            [self offCallNow];
        }
    }

}

//创建一个上麦头像
- (CallInButton *)createCallInIcon:(NSString *)userId
{
    BOOL isOwner = FALSE;
    NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    if ([uuid isEqualToString:userId]){
        isOwner = YES;
    }else{
        isOwner = NO;
    }
    
    CallInButton *btn = [[CallInButton alloc] initWithFrame:CGRectMake(kScreenWidth - 78,
                                                                       kScreenHeight/2 - 23 + (self.onCallBtns.count*(46+30)),
                                                                       46, 46) canHangUp:isOwner];
    
    btn.extra = userId;
    btn.layer.cornerRadius = 23;
    [btn setImage:[UIImage imageNamed:@"header_default"] forState:UIControlStateNormal];
    if (isOwner){
        [btn addTarget:self action:@selector(offCall:) forControlEvents:UIControlEventTouchUpInside];
    }
    return btn;
}

- (void)onCall:(UIButton *)sender
{
    if(!_isKMCAuthSuccess){
        [self toast:@"魔方鉴权未通过，不能连麦"];
        return;
    }
    
    
    NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *roomName = [self.data valueForKey:@"roomName"];
    __weak typeof(self) weakSelf = self;
    [[KMCNetwork sharedInst] joinChat:@{@"roomName":roomName, @"userId":uuid} successBlk:^(NSDictionary *data) {
        if ([[data valueForKey:@"isClose"] integerValue]){
            //room not exist, all viewers should be kicked out
            [weakSelf onClose];
            
        }else{
            id chatList = [data valueForKey:@"chatIdList"];
            if ([chatList isKindOfClass:[NSArray class]]){
                [weakSelf updateRoom:chatList];
            }else{
                NSAssert(false, @"malformed data");
            }
            
        }
        [_aRtcKit joinChannel:roomName uid:0];
        //FIXME
        _isOnCall = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = NO;
        });

        
    } OnFailure:^(NSError *error) {
        [weakSelf toast:error.localizedDescription];
    }];
    
}

- (void)offCall:(CallInButton *)sender
{

    NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *roomName = [self.data valueForKey:@"roomName"];
    __weak typeof(self) weakSelf = self;
    
    [[KMCNetwork sharedInst] leaveChat:@{@"roomName":roomName, @"userId":uuid} successBlk:^(NSDictionary *data) {
        //
        [_aRtcKit leaveChannel];
        _isOnCall = NO;
        //refresh chat list
        if ([[data valueForKey:@"isClose"] integerValue]){
            //room not exist, all viewers should be kicked out
            [weakSelf onClose];
            
        }else{
            id chatList = [data valueForKey:@"chatIdList"];
            if ([chatList isKindOfClass:[NSArray class]]){
                [weakSelf updateRoom:chatList];
            }else{
                NSAssert(false, @"malformed data");
            }
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.callBtn.enabled = YES;
        });
        
        
    } OnFailure:^(NSError *error) {
        //
        [self toast:[NSString stringWithFormat:@"出错了:%@", error.localizedDescription]];
    }];
}

//immediately offcall
- (void)offCallNow
{
    
    [_aRtcKit leaveChannel];
    _isOnCall = NO;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.callBtn.enabled = YES;
    });

}

- (void)authSuccess:(KMCAgoraARTC *)sender
{
    _isKMCAuthSuccess = YES;
}

- (void)authFailure:(AuthorizeError)iErrorCode
{
    [self toast:[NSString stringWithFormat:@"出错了, 错误码:%@", @(iErrorCode)]];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraRtcErrorCode)errorCode
{
    
    //TODO FIXME
    
    _isOnCall = NO;
    if (errorCode == AgoraRtc_Error_JoinChannelRejected){
//        if (_player){
//            [_player play];
//        }
    }
    
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
