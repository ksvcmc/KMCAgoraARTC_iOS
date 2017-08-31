//
//  ChatViewController.m
//  demo
//
//  Created by 张俊 on 13/07/2017.
//  Copyright © 2017 ksyun. All rights reserved.
//

#import "AnchorViewController.h"
#import "MBProgressHUD.h"
#import <KMCAgoraARTC/KMCAgoraARTC.h>
#import "KMCAgoraStreamerKit.h"
#import "KMCNetwork.h"



@interface AnchorViewController ()<KMCRtcDelegate>
{
    NSString *_roomName;
    NSString       * _streamId;
    NSNumber * _roomId;
    BOOL      _isStreamStarted;
}


@property KMCAgoraStreamerKit * kit;


@end

@implementation AnchorViewController

- (instancetype)initWithData:(NSDictionary *)data
{
    self = [super initWithData:data];
    if (self){
        _kit = [[KMCAgoraStreamerKit alloc] initWithDefaultCfg:self];
        NSLog(@"version:%@", [_kit getKSYVersion]);
        _roomName = [data valueForKey:@"roomName"];
        _roomId = [data valueForKey:@"roomId"];
        NSNumber* streamID =[data valueForKey:@"streamId"];
        _streamId = [NSString stringWithFormat:@"%ld",(long)streamID.integerValue];
        self.streamUrl = [NSURL URLWithString:[NSString stringWithFormat:@"rtmp://test.uplive.ks-cdn.com/live/%@", _streamId]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.callBtn.hidden = YES;
    [self registerNotifications];
    
    
}

//创建一个上麦头像
- (CallInButton *)createCallInIcon:(NSString *)userId
{
    CallInButton *btn = [[CallInButton alloc] initWithFrame:CGRectMake(kScreenWidth - 78,
                                                                       kScreenHeight/2 - 23 + (self.onCallBtns.count*(46+30)),
                                                                       46, 46) canHangUp:YES];
    //btn.layer.cornerRadius = 23;
    //btn.clipsToBounds = YES;
    btn.extra = userId;
    [btn setImage:[UIImage imageNamed:@"header_default"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(kickTarget:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)onClose
{
    //TODO  release resources
    [self stopStream];
    [super  onClose];
}

- (void)kickTarget:(UIButton *)sender
{
    __weak typeof(self) weakSelf = self;
    NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [[KMCNetwork sharedInst] kickUser:@{@"roomName":_roomName,
                                       @"userId":sender.extra,
                                       @"anchorId":uuid,
                                        @"roomId":_roomId
                                       }
    successBlk:^(NSDictionary *data) {
                                           //
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
                                           //
    }];
}

#pragma AgoraRtcEngineDelegate

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason
{
    if(_kit.callstarted){
        [_kit stopRTCView];
        if(_kit.onCallStop)
            _kit.onCallStop(reason);
        _kit.callstarted = NO;
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
    if(!_kit.callstarted)
    {
        [_kit startRtcView];
        if(_kit.onCallStart)
            _kit.onCallStart(200);
        _kit.callstarted = YES;
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraRtcErrorCode)errorCode
{
    NSString * errorMessage = [[NSString alloc]initWithFormat:@"出错了,错误码:%@", @(errorCode)];
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:(BOOL)YES];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:errorMessage delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        [alert show];
    });
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine remoteVideoStats:(AgoraRtcRemoteVideoStats*)stats
{
    //    NSLog(@"remotestats,width:%lu,height:%lu,fps:%lu,receivedBitrate:%lu",(unsigned long)stats.width,(unsigned long)stats.height,(unsigned long)stats.receivedFrameRate,(unsigned long)stats.receivedBitrate);
    //
}

- (void)authSuccess:(KMCAgoraARTC *)sender
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:(BOOL)YES];
    });
    //only kmc auth success can we start
    
    [self startStream];

}

- (void)authFailure:(AuthorizeError)iErrorCode
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:(BOOL)YES];
        
        NSString * errorMessage = [[NSString alloc]initWithFormat:@"鉴权失败，错误码:%@", @(iErrorCode)];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:errorMessage delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        [alert show];
    });
    
}

#pragma mark -- streamer settings
- (void)startStream
{
    //ksylive streamer related
    _kit.streamerBase.bWithVideo = NO;
    _kit.streamerBase.audioCodec = KSYAudioCodec_AAC_HE;
    _kit.streamerBase.audiokBPS = 48;
    
    
    //[_kit.aCapDev startCapture];
    [_kit.streamerBase startStream:self.streamUrl];
    _isStreamStarted = TRUE;
    
    //start to create a rtc room
    [_kit joinChannel:_streamId];
    
}

- (void)stopStream
{
    if (!_isStreamStarted) return ;
    //推流相关
    //[_kit.aCapDev stopCapture];
    
    [_kit.streamerBase stopStream];
    //连麦相关
    [_kit leaveChannel];
    
    _kit = nil; 
    
}

#pragma mark - 通知相关

- (void)registerNotifications{
    // 网络状态
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNetStateEvent:)
                                                 name:KSYNetStateEventNotification
                                               object:nil];
//    // 采集状态
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(onCaptureStateChange:)
//                                                 name:KSYCaptureStateDidChangeNotification
//                                               object:nil];
    
    // 推流状态
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onStreamStateChange:)
                                                 name:KSYStreamStateDidChangeNotification
                                               object:nil];
    
    // active状态监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becameActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
}



- (void) onStreamStateChange:(NSNotification *)notification {
    NSLog(@"onStreamStateChange:%@", @(_kit.streamerBase.streamState));
    if ( _kit.streamerBase.streamState == KSYStreamStateIdle) {
        NSLog(@"idle");
    }
    else if ( _kit.streamerBase.streamState == KSYStreamStateConnected){
        NSLog(@"connected");

    }
    else if (_kit.streamerBase.streamState == KSYStreamStateConnecting ) {
        NSLog(@"kit connecting");
    }
    else if (_kit.streamerBase.streamState == KSYStreamStateDisconnecting ) {
        NSLog(@"disconnecting");
    }
    else if (_kit.streamerBase.streamState == KSYStreamStateError ) {
        [self onStreamError:_kit.streamerBase.streamErrorCode];
    }
}


- (void) onNetStateEvent:(NSNotification *)notification {
    KSYNetStateCode netEvent = _kit.streamerBase.netStateCode;
    NSLog(@"net state:%@", @(netEvent));
    if ( netEvent == KSYNetStateCode_SEND_PACKET_SLOW ) {
        NSLog(@"bad network" );
    }
    else if ( netEvent == KSYNetStateCode_EST_BW_RAISE ) {
        NSLog(@"bitrate raising" );
    }
    else if ( netEvent == KSYNetStateCode_EST_BW_DROP ) {
        NSLog(@"bitrate dropping" );
    }
}

/**
 推流错误
 */
- (void)onStreamError:(KSYStreamErrorCode)errCode{
    NSLog(@"stream error:%@", @(errCode));
    switch (errCode) {
        case KSYStreamErrorCode_CODEC_OPEN_FAILED:  // 无法打开配置指示的CODEC
        case KSYStreamErrorCode_AV_SYNC_ERROR:      // 音视频同步失败 (输入的音频和视频的时间戳的差值超过5s)
        case KSYStreamErrorCode_CONNECT_BREAK:      // 网络中断
            [self tryReconnect];
            return;
        case KSYStreamErrorCode_CONNECT_FAILED:
            // 链接出错
            break;
        default:
            break;
    }
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//         [_kit.streamerBase stopStream];
//        _kit = nil;
//    });
}

// 重新推流
- (void)tryReconnect{
    // 网络状态可以等到网络切换至有网状态下再进行尝试，且长时间无网络则关闭推流，不再重试
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC));
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        [_kit.streamerBase startStream:self.streamUrl];
    });
}

- (void)becameActive{
    //[self enableAudioToSpeaker];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopStream];
}



@end
