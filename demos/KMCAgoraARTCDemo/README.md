# 金山魔方语音连麦API文档
## 项目背景
金山魔方是一个多媒体能力提供平台，通过统一接入API、统一鉴权、统一计费等多种手段，降低客户接入多媒体处理能力的代价，提供多媒体能力供应商的效率。 本文档主要针对多人语音连麦功能而说明。
**本demo演示了使用金山魔方语音连麦sdk进行直播连麦的应用场景**


## 集成

客户可以先行下载demo, 执行
```
pod install
```
打开KMCAgoraARTCDemo.xcworkspace演示demo查看效果

- 手动集成
将KMCAgoraARTC.framework拖进工程，切换到xcode的**General**->**Embedded Binaries**位置，添加KMCAgoraARTC.framework即可

- Cocoapod集成
```
pod 'KMCAgoraARTC'
```

## SDK使用指南  

本sdk使用简单，初次使用需要在魔方服务后台申请token，用于客户鉴权，使用下面的接口鉴权
``` objective-c

-(instancetype)initWithToken:(NSString *)token
                    delegate:(id<KMCRtcDelegate>)delegate;
```

加入一个Channel

``` objective-c
-(void)joinChannel:(NSString *)channelName uid:(NSUInteger)uid;
```

离开一个Channel

``` objective-c
-(void)leaveChannel;
```

视频前处理后使用下面的接口送入sdk

``` objective-c
-(void)ProcessVideo:(CVPixelBufferRef)buf timeInfo:(CMTime)pts;
```

远端视频数据回调

``` objective-c
@property (nonatomic, copy)RTCVideoDataBlock videoDataCallback;
``` 

远端音频数据回调

``` objective-c
@property (nonatomic, copy)RTCAudioDataBlock remoteAudioDataCallback;
```


本地音频数据回调

``` objective-c
@property (nonatomic, copy)RTCAudioDataBlock localAudioDataCallback;
```

本sdk需结合金山云推流sdk融合版使用，音视频的合成操作封装在KSYAgoraStreamerKit类中，已经开源，使用者可以参考KSYAgoraStreamerKit类的用法


## 接入指南

## 反馈与建议  
主页：https://docs.ksyun.com/read/latest/142/_book/index.html  
邮箱：ksc-vbu-kmc-dev@kingsoft.com    
QQ讨论群：574179720 [视频云技术交流群]  
