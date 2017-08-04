
#import <libksygpulive/KSYGPUPicOutput.h>
#import <libksygpulive/libksystreamerengine.h>
#import <KMCAgoraARTC/KMCAgoraARTC.h>
#import <GPUImage/GPUImage.h>
#import "KMCAgoraStreamerKit.h"
#import <mach/mach_time.h>

static inline void fillAsbd(AudioStreamBasicDescription*asbd,BOOL bFloat, UInt32 size) {
    bzero(asbd, sizeof(AudioStreamBasicDescription));
    asbd->mSampleRate       = 44100;
    asbd->mFormatID         = kAudioFormatLinearPCM;
    if (bFloat) {
        asbd->mFormatFlags      = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    }
    else {
        asbd->mFormatFlags      = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    }
    asbd->mBitsPerChannel   = 8 * size;
    asbd->mBytesPerFrame    = size;
    asbd->mBytesPerPacket   = size;
    asbd->mFramesPerPacket  = 1;
    asbd->mChannelsPerFrame = 1;
}

@interface KMCAgoraStreamerKit() {
    AudioStreamBasicDescription _asbd;  // format description for audio data

}

@property KSYGPUPicOutput *     beautyOutput;
@property KSYGPUYUVInput  *     rtcYuvInput;
@property GPUImageUIElement *   uiElementInput;
@property GPUImageMaskFilter *  maskingFilter;
@property GPUImageFilter *  maskingShieldFilter;//用于mask隔离，防止残影发生
@property CMTime localAudioPts;
@property CMTime videoPts;

@end

@implementation KMCAgoraStreamerKit

/**
 @abstract 初始化方法
 @discussion 初始化，创建带有默认参数的 KSYStreamerBase
 
 @warning KSYStreamer只支持单实例推流，构造多个实例会出现异常
 */
- (instancetype) initWithDefaultCfg:(id<KMCRtcDelegate>)delegate
{
    self = [super initWithDefaultCfg];
    __weak typeof(self) weakSelf = self;

    
    self.streamerBase.bWithVideo = NO;
    self.streamerBase.bWithAudio = YES;
    
    _beautyOutput = nil;
    _callstarted = NO;
    _maskPicture = nil;
    _maskingShieldFilter = [[GPUImageFilter alloc]init];
    _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];
    _contentView.backgroundColor = [UIColor clearColor];
    _curfilter = self.filter;
    _localAudioPts = kCMTimeInvalid;
    
    fillAsbd(&_asbd, YES, sizeof(Float32));
    
    self.videoProcessingCallback = ^(CMSampleBufferRef buf){
        weakSelf.videoPts= CMSampleBufferGetPresentationTimeStamp(buf);
    };

    __weak KMCAgoraStreamerKit * weak_kit = self;
    
    _agoraKit = [[KMCAgoraARTC alloc] initWithToken:@"648e6ec7f957aabde391ebba7f43c1fa" delegate:delegate];
    //加入channel成功回调,开始发送数据
    _agoraKit.joinChannelBlock = ^(NSString* channel, NSUInteger uid, NSInteger elapsed){
        if(channel)
        {
            if(!weak_kit.beautyOutput)
            {
                [weak_kit setupBeautyOutput];
                [weak_kit setupRtcFilter:weak_kit.curfilter];
            }
            
            if(weak_kit.onChannelJoin)
                weak_kit.onChannelJoin(200);
        }
    };
   
    //离开channel成功回调
    _agoraKit.leaveChannelBlock = ^(AgoraRtcStats* stat){
        NSLog(@"local leave channel");
        if(weak_kit.callstarted){
            [weak_kit stopRTCView];
            if(weak_kit.onCallStop)
                weak_kit.onCallStop(200);
             weak_kit.callstarted = NO;
        }
        
        
        /*
         Comment out by Noiled, as a anchor, streamer status should keep up with agora chat status
         that is  if stream start agora should join, else agora should leave
         */
        
        //[weak_kit.aCapDev stopCapture];
        //[weak_kit.aCapDev startCapture];
    };

    //音频回调，放入amixer里面
    _agoraKit.remoteAudioDataCallback=^(void* buffer,int sampleRate,int len,int bytesPerSample,int channels,int64_t pts)
    {
        [weak_kit defaultRtcVoiceCallback:buffer len:len pts:CMTimeMake(0, 0) channel:channels sampleRate:sampleRate sampleBytes:bytesPerSample trackId:1];
    };
    //本地音频回调
    _agoraKit.localAudioDataCallback=^(void* buffer,int sampleRate,int len,int bytesPerSample,int channels,int64_t pts)
    {
        if(CMTIME_IS_INVALID(weak_kit.localAudioPts)){
            _localAudioPts = CMTimeMake(0, 1000000000);
        }else{
            int nb_sample = len/bytesPerSample;
            int64_t timescale = 1000000000;
            int64_t dur =(nb_sample*timescale)/sampleRate;
            _localAudioPts.value +=dur;
        }
        [weak_kit defaultRtcVoiceCallback:buffer len:len pts:weak_kit.localAudioPts channel:channels sampleRate:sampleRate sampleBytes:bytesPerSample trackId:0];
    };

    return self;
}

- (instancetype)init
{
    return [self initWithDefaultCfg];
}


- (void)dealloc
{
    NSLog(@"kit dealloc ");
    if(_agoraKit){
        [_agoraKit leaveChannel];
        _agoraKit = nil;
    }
    
    if(_beautyOutput){
        _beautyOutput = nil;
    }
    
    if(_rtcYuvInput){
        _rtcYuvInput = nil;
    }
    
    if(_contentView)
    {
        _contentView = nil;
    }
}


- (void) setupRtcFilter:(GPUImageOutput<GPUImageInput> *) filter {
    _curfilter = filter;
    if (self.vCapDev  == nil) {
        return;
    }
    // 采集的图像先经过前处理
    [self.capToGpu     removeAllTargets];
    GPUImageOutput* src = self.capToGpu;
    
    if(filter)
    {
        [self.filter removeAllTargets];
        [src addTarget:self.filter];
        src = self.filter;
    }
    // 组装图层
    if(_rtcYuvInput)
    {
        [_rtcYuvInput removeAllTargets];
        if(!_selfInFront)//主播
        {
            [self setMixerMasterLayer:self.cameraLayer];
            [self addInput:src ToMixerAt:self.cameraLayer];
            if(_maskPicture){
                [self Maskwith:_rtcYuvInput];
                [self addInput:_maskingFilter ToMixerAt:_rtcLayer Rect:_winRect];
            }else{
                [self addInput:_rtcYuvInput ToMixerAt:_rtcLayer Rect:_winRect];
            }
        }
        else{//辅播
            [self setMixerMasterLayer:self.rtcLayer];
            [self addInput:_rtcYuvInput  ToMixerAt:self.cameraLayer];
            if(_maskPicture){
                [self Maskwith:src];
                [self addInput:_maskingFilter ToMixerAt:_rtcLayer Rect:_winRect];
            }else{
                [self addInput:src ToMixerAt:_rtcLayer Rect:_winRect];
            }
        }
    }else{
        [self clearMixerLayer:self.rtcLayer];
        [self clearMixerLayer:self.cameraLayer];
        [self setMixerMasterLayer:self.cameraLayer];
        [self addInput:src       ToMixerAt:self.cameraLayer];
    }
    
    //美颜后的图像，用于rtc发送
    if(_beautyOutput)
    {
        [src addTarget:_beautyOutput];
    }
    
    //组装自定义view
    if(_uiElementInput){
        [self addElementInput:_uiElementInput callbackOutput:src];
    }
    else{
        [self removeElementInput:_uiElementInput callbackOutput:src];
    }
    
    // 混合后的图像输出到预览和推流
    [self.vPreviewMixer removeAllTargets];
    [self.vPreviewMixer addTarget:self.preview];
    
    [self.vStreamMixer  removeAllTargets];
    [self.vStreamMixer  addTarget:self.gpuToStr];
    // 设置镜像
    [self setPreviewMirrored:self.previewMirrored];
    [self setStreamerMirrored:self.streamerMirrored];
}

-(void) addElementInput:(GPUImageUIElement *)input
         callbackOutput:(GPUImageOutput*)callbackOutput
{
    __weak GPUImageUIElement *weakUIEle = self.uiElementInput;
    [callbackOutput setFrameProcessingCompletionBlock:^(GPUImageOutput * f, CMTime fT){
        NSArray* subviews = [_contentView subviews];
        for(int i = 0;i<subviews.count;i++)
        {
            UIView* subview = (UIView*)[subviews objectAtIndex:i];
            if(subview)
                subview.hidden = NO;
        }
        if(subviews.count > 0)
        {
            [weakUIEle update];
        }
    }];
    [self addInput:_uiElementInput ToMixerAt:_customViewLayer Rect:_customViewRect];
}

- (void) addPic:(GPUImageOutput*)pic ToMixerAt: (NSInteger)idx{
    if (pic == nil){
        return;
    }
    [pic removeAllTargets];
    KSYGPUPicMixer * vMixer[2] = {self.vPreviewMixer, self.vStreamMixer};
    for (int i = 0; i<2; ++i) {
        [vMixer[i]  clearPicOfLayer:idx];
        [pic addTarget:vMixer[i] atTextureLocation:idx];
    }
}

-(void)Maskwith:(GPUImageOutput *)input
{
    [input removeAllTargets];
    [_maskPicture removeAllTargets];
    [_maskingFilter removeAllTargets];
    [_maskingShieldFilter removeAllTargets];
    
    [input addTarget:_maskingShieldFilter];
    [_maskingShieldFilter addTarget:_maskingFilter];
    [_maskPicture addTarget:_maskingFilter];
    [_maskPicture processImage];
}


-(void) setMixerMasterLayer:(NSInteger)idx
{
    KSYGPUPicMixer * vMixer[2] = {self.vPreviewMixer, self.vStreamMixer};
    for (int i = 0; i<2; ++i) {
        [vMixer[i]  setMasterLayer:idx];
    }
}


- (void) addPic:(GPUImageOutput*)pic
      ToMixerAt: (NSInteger)idx
           Rect:(CGRect)rect{
    if (pic == nil){
        return;
    }
    [pic removeAllTargets];
    KSYGPUPicMixer * vMixer[2] = {self.vPreviewMixer, self.vStreamMixer};
    for (int i = 0; i<2; ++i) {
        [vMixer[i]  clearPicOfLayer:idx];
        [pic addTarget:vMixer[i] atTextureLocation:idx];
        [vMixer[i] setPicRect:rect ofLayer:idx];
        [vMixer[i] setPicAlpha:1.0f ofLayer:idx];
    }
}


- (void) addInput:(GPUImageOutput*)pic
        ToMixerAt:(NSInteger)idx{
    if (pic == nil){
        return;
    }
    [pic removeAllTargets];
    KSYGPUPicMixer * vMixer[2] = {self.vPreviewMixer, self.vStreamMixer};
    for (int i = 0; i<2; ++i) {
        [vMixer[i]  clearPicOfLayer:idx];
        [pic addTarget:vMixer[i] atTextureLocation:idx];
    }
}


-(void) removeElementInput:(GPUImageUIElement *)input
            callbackOutput:(GPUImageOutput *)callbackOutput
{
    [self clearMixerLayer:_customViewLayer];
    [callbackOutput setFrameProcessingCompletionBlock:nil];
}

-(void) clearMixerLayer:(NSInteger)idx
{
    KSYGPUPicMixer * vMixer[2] = {self.vPreviewMixer, self.vStreamMixer};
    for (int i = 0; i<2; ++i) {
        [vMixer[i]  clearPicOfLayer:idx];
    }
}


- (void) addInput:(GPUImageOutput*)pic
        ToMixerAt:(NSInteger)idx
             Rect:(CGRect)rect{
    
    [self addInput:pic ToMixerAt:idx];
    KSYGPUPicMixer * vMixer[2] = {self.vPreviewMixer, self.vStreamMixer};
    for (int i = 0; i<2; ++i) {
        [vMixer[i] setPicRect:rect ofLayer:idx];
        [vMixer[i] setPicAlpha:1.0f ofLayer:idx];
    }
}

#pragma mark -rtc
-(void)joinChannel:(NSString *)channelName
{
    [_agoraKit joinChannel:channelName uid:0];
    
}
-(void)leaveChannel
{
    [self.aCapDev stopCapture];
    [_agoraKit leaveChannel];
}

-(void)setupBeautyOutput
{
//    __weak KMCAgoraStreamerKit * weak_kit = self;
//    _beautyOutput  =  [[KSYGPUPicOutput alloc] init];
//    _beautyOutput.bCustomOutputSize = YES;
//    _beautyOutput.outputSize = [self adjustVideoProfile:_agoraKit.videoProfile];//发送size需要和videoprofile匹配
//    _beautyOutput.videoProcessingCallback = ^(CVPixelBufferRef pixelBuffer, CMTime timeInfo ){
//            [weak_kit.agoraKit ProcessVideo:pixelBuffer timeInfo:timeInfo];
//    };
}

-(void)startRtcVideoView{
    _rtcYuvInput =    [[KSYGPUYUVInput alloc] init];
    if(_contentView.subviews.count != 0)
        _uiElementInput = [[GPUImageUIElement alloc] initWithView:_contentView];
    if(!_beautyOutput)
    {
        [self setupBeautyOutput];
    }
    _maskingFilter = [[GPUImageMaskFilter alloc] init];
    [self setupRtcFilter:_curfilter];
}

-(void)startRtcView
{
    [self startRtcVideoView];
    //音频混音
    [self.aCapDev stopCapture];
    [self.aMixer processAudioData:NULL nbSample:0 withFormat:&(_asbd) timeinfo:(CMTimeMake(0, 0)) of:0];
    
    [self.aMixer setTrack:1 enable:YES];
    [self.aMixer setMixVolume:1 of:1];
    _localAudioPts = kCMTimeInvalid;
}

-(void)stopRTCVideoView{
    _rtcYuvInput = nil;
    _beautyOutput = nil;
    _uiElementInput = nil;
    _maskingFilter = nil;
    [self setupRtcFilter:_curfilter];
    
}

-(void)stopRTCView
{
    [self stopRTCVideoView];
    [self.aCapDev startCapture];
    [self.aMixer setTrack:1 enable:NO];
}

-(void) defaultRtcVideoCallback:(CVPixelBufferRef)buf
{
    //NSLog(@"width:%zu,height:%zu",CVPixelBufferGetWidth(buf),CVPixelBufferGetHeight(buf));
    [self.rtcYuvInput processPixelBuffer:buf time:CMTimeMake(2, 10)];
}

-(void) defaultRtcVoiceCallback:(uint8_t*)buf
                            len:(int)len
                            pts:(CMTime)pts
                        channel:(uint32_t)channels
                     sampleRate:(uint32_t)sampleRate
                    sampleBytes:(uint32_t)bytesPerSample
                        trackId:(int)trackId
{
    AudioStreamBasicDescription asbd;
    asbd.mSampleRate       = sampleRate;
    asbd.mFormatID         = kAudioFormatLinearPCM;
    asbd.mFormatFlags      = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    asbd.mBitsPerChannel   = 8 * bytesPerSample;
    asbd.mBytesPerFrame    = bytesPerSample;
    asbd.mBytesPerPacket   = bytesPerSample;
    asbd.mFramesPerPacket  = 1;
    asbd.mChannelsPerFrame = 1;

    if([self.streamerBase isStreaming])
    {
        [self.aMixer processAudioData:&buf nbSample:len/bytesPerSample withFormat:&asbd timeinfo:pts of:trackId];
    }
}

-(void) setWinRect:(CGRect)rect
{
    _winRect = rect;
    if(_callstarted)
    {
        KSYGPUPicMixer * vMixer[2] = {self.vPreviewMixer, self.vStreamMixer};
        for (int i = 0; i<2; ++i) {
            [vMixer[i]  removeAllTargets];
            [vMixer[i] setPicRect:rect ofLayer:self.rtcLayer];
        }
        [self.vPreviewMixer addTarget:self.preview];
        [self.vStreamMixer  addTarget:self.gpuToStr];
    }
}

-(void)setSelfInFront:(BOOL)selfInFront
{
    _selfInFront = selfInFront;
    [self setupRtcFilter:_curfilter];
}

@end


