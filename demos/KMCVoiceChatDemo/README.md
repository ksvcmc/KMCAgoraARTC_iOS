# 金山云魔方连麦API文档
## 项目背景
金山魔方是一个多媒体能力提供平台，通过统一接入API、统一鉴权、统一计费等多种手段，降低客户接入多媒体处理能力的代价，提供多媒体能力供应商的效率。 本文档主要针对多人语音连麦功能而说明。
***本demo演示了使用金山魔方语音连麦sdk进行多人语音通话的应用场景***
## 集成
下载demo, 执行
```
pod install
```
打开KMCAgoraVRTCDemo.xcworkspace演示demo查看效果

将KMCAgoraVRTC.framework添加进自己的工程用于集成


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


远端音频数据回调

``` objective-c
@property (nonatomic, copy)RTCAudioDataBlock remoteAudioDataCallback;
```


本地音频数据回调

``` objective-c
@property (nonatomic, copy)RTCAudioDataBlock localAudioDataCallback;
```



## 接入指南

## 反馈与建议  
主页：https://docs.ksyun.com/read/latest/142/_book/index.html  
邮箱：ksc-vbu-kmc-dev@kingsoft.com    
QQ讨论群：574179720 [视频云技术交流群]  
