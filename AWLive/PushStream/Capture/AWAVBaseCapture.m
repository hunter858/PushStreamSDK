 

#import "AWAVBaseCapture.h"
#import "AWEncoderManager.h"

__weak static AWAVBaseCapture *sAWAVCapture = nil;

extern void aw_rtmp_state_changed_cb_in_oc(aw_rtmp_state old_state, aw_rtmp_state new_state){
    NSLog(@"[OC] rtmp state changed from(%s), to(%s)", aw_rtmp_state_description(old_state), aw_rtmp_state_description(new_state));
    dispatch_async(dispatch_get_main_queue(), ^{
        [sAWAVCapture.stateDelegate avCapture:sAWAVCapture stateChangeFrom:old_state toState:new_state];
    });
}

@interface AWAVBaseCapture()
{
    dispatch_queue_t _writeFileQueue;                                               /// 写队列
}
@property (nonatomic, strong) NSOperationQueue *encodeSampleOpQueue;                /// 编码队列，发送队列
@property (nonatomic, strong) NSOperationQueue *sendSampleOpQueue;
@property (nonatomic, unsafe_unretained) BOOL isSpsPpsAndAudioSpecificConfigSent;   /// 是否已发送了sps/pps
@property (nonatomic, strong) AWEncoderManager *encoderManager;                     /// 编码管理
@property (nonatomic, unsafe_unretained) BOOL inBackground;                         /// 进入后台后，不推视频流
@property (nonatomic ,assign) BOOL isAlreadyWriteSPS_PPS;
@property (nonatomic ,strong) NSLock *lock;
@end

@implementation AWAVBaseCapture

- (NSOperationQueue *)encodeSampleOpQueue {
    if (!_encodeSampleOpQueue) {
        _encodeSampleOpQueue = [[NSOperationQueue alloc] init];
        _encodeSampleOpQueue.maxConcurrentOperationCount = 1;
    }
    return _encodeSampleOpQueue;
}

- (NSOperationQueue *)sendSampleOpQueue {
    if (!_sendSampleOpQueue) {
        _sendSampleOpQueue = [[NSOperationQueue alloc] init];
        _sendSampleOpQueue.maxConcurrentOperationCount = 1;
    }
    return _sendSampleOpQueue;
}

- (AWEncoderManager *)encoderManager {
    if (!_encoderManager) {
        _encoderManager = [[AWEncoderManager alloc] init];
        //设置编码器类型
        _encoderManager.audioEncoderType = self.audioEncoderType;
        _encoderManager.videoEncoderType = self.videoEncoderType;
    }
    return _encoderManager;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"please call initWithVideoConfig:audioConfig to init" reason:nil userInfo:nil];
    _writeFileQueue = dispatch_queue_create("sync.write.auido.queue", DISPATCH_QUEUE_SERIAL);
}

- (instancetype) initWithVideoConfig:(AWVideoConfig *)videoConfig audioConfig:(AWAudioConfig *)audioConfig {
    self = [super init];
    if (self) {
        self.videoConfig = videoConfig;
        self.audioConfig = audioConfig;
        sAWAVCapture = self;
        self.isAlreadyWriteSPS_PPS = NO;
        self.lock = [[NSLock alloc]init];
        [self onInit];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void) onInit{}

- (void) willEnterForeground {
    self.inBackground = NO;
}

- (void) didEnterBackground {
    self.inBackground = YES;
}

- (AWFileManager *)fileManager {
    if (!_fileManager) {
        _fileManager = [[AWFileManager alloc]init];
    }
    return _fileManager;
}

- (NSData *)adts_headerWithLength:(int)data_length profile:(int)profile sampleRate:(int)sampleRate channles:(int)channles {
    
    int adtsLength = 7;
    profile = 2;  /// AAC LC
    int chanCfg = 1;
    char *adts_header = malloc(sizeof(char) * adtsLength);
    int fullLength = adtsLength + data_length;
    int freqIdx = [self fregWithSampleBuffer:sampleRate];    //对应44100采样率；
    /*
    A 12 syncword 0xFFF, all bits must be 1
    //  11111111
    */
    adts_header[0] = 0xFF;
    /*
    B 1 MPEG Version: 0 for MPEG-4, 1 for MPEG-2
    C 2 Layer: always 0
    D 1 protection absent, Warning, set to 1 if there is no CRC and 0 if there is CRC
    ///  1111 1001
    */
    adts_header[1] = 0xF9;
    /*
    E 2 profile, the MPEG-4 Audio Object Type minus 1
    F 4 MPEG-4 Sampling Frequency Index (15 is forbidden)
    G 1 private bit, guaranteed never to be used by MPEG, set to 0 when encoding, ignore when decoding
    H 3 MPEG-4 Channel Configuration (in the case of 0, the channel configuration is sent via an inband
     11
    */
    adts_header[2] = (char)(((profile-1) << 6));
    adts_header[2] |= (char)(freqIdx << 2);
    adts_header[2] |= (char)(chanCfg >> 2);
    
    /*
      前两位已经被H占了
     I 1 originality, set to 0 when encoding, ignore when decoding
     J 1 home, set to 0 when encoding, ignore when decoding
     K 1 copyrighted id bit, the next bit of a centrally registered copyright identifier, set to 0 when encoding, ignore when decoding
     L 1 copyright id start, signals that this frame's copyright id bit is the first bit of the copyright id, set to 0 when encoding, ignore when decoding

     xx0000xx
     */
    adts_header[3] = (char)((chanCfg & 3) <<6); //chanCfg 的2bit
    
    /*
     M 13 frame length, this value must include 7 or 9 bytes of header length: FrameLength = (ProtectionAbsent == 1 ? 7 : 9) + size(AACFrame)
     0x7FF = 11111111111
     */
    adts_header[3]  |= (char)((fullLength & 0x18) >> 11);//这里只占了2bit 所以，13bit 又移11位
    adts_header[4] = (char)((fullLength &0x7FF) >> 3);
   
    //前3bit 是fulllength 的低位
    adts_header[5] =  (char)((fullLength & 7) << 5);
    /*
     O 11 Buffer fullness
     */
    adts_header[5] |= 0x1f;
    /*
     Q 16 CRC if protection absent is 0
     */
    adts_header[6] = (char)0xFC;
    
    NSData *data = [[NSData alloc] initWithBytes:adts_header length:adtsLength];
    return data;
}

- (int)fregWithSampleBuffer:(NSUInteger)sampelBuffer {
    char value = 0x0;
    if (sampelBuffer == 96000) {
        value = 0x0;
    }
    else if(sampelBuffer == 88200){
        value = 0x1;
    }
    else if(sampelBuffer == 64000){
        value = 0x2;
    }
    else if(sampelBuffer == 48000){
        value = 0x3;
    }
    else if(sampelBuffer == 44100){
        value = 0x4;
    }
    else if(sampelBuffer == 32000){
        value = 0x5;
    }
    else if(sampelBuffer == 24000){
        value = 0x6;
    }
    else if(sampelBuffer == 22050){
        value = 0x7;
    }
    else if(sampelBuffer == 16000){
        value = 0x8;
    }
    else if(sampelBuffer == 12000){
        value = 0x9;
    }
    else if(sampelBuffer == 11025){
        value = 0xa;
    }
    else if(sampelBuffer == 8000){
        value = 0xb;
    }
    
    return value;
}

- (void)updateFps:(NSInteger)fps {
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *vDevice in videoDevices) {
        float maxRate = [(AVFrameRateRange *)[vDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0] maxFrameRate];
        if (maxRate >= fps) {
            if ([vDevice lockForConfiguration:NULL]) {
                vDevice.activeVideoMinFrameDuration = CMTimeMake(10, (int)(fps * 10));
                vDevice.activeVideoMaxFrameDuration = vDevice.activeVideoMinFrameDuration;
                [vDevice unlockForConfiguration];
            }
        }
    }
}

- (void)updatePresent:(AVCaptureSessionPreset)present {}

- (BOOL)startCaptureWithRtmpUrl:(NSString *)rtmpUrl {
    if (!rtmpUrl || rtmpUrl.length < 8) {
        NSLog(@"rtmpUrl is nil when start capture");
        return NO;
    }
    
    if (!self.videoConfig && !self.audioConfig) {
        NSLog(@"one of videoConfig and audioConfig must be NON-NULL");
        return NO;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //先开启encoder
        [weakSelf.encoderManager openWithAudioConfig:weakSelf.audioConfig videoConfig:weakSelf.videoConfig];
        //再打开rtmp
        int retcode = aw_streamer_open(rtmpUrl.UTF8String, aw_rtmp_state_changed_cb_in_oc);
        
        if (retcode) {
            weakSelf.isCapturing = YES;
        } else {
            NSLog(@"startCapture rtmpOpen error!!! retcode=%d", retcode);
            [weakSelf stopCapture];
        }
    });
    return YES;
}

- (void)stopCapture {
    self.isCapturing = NO;
    self.isSpsPpsAndAudioSpecificConfigSent = NO;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //关闭编码器
        [self.encodeSampleOpQueue cancelAllOperations];
        [self.encodeSampleOpQueue waitUntilAllOperationsAreFinished];
        
        [self.encoderManager close];
        
        //关闭流
        [self.sendSampleOpQueue cancelAllOperations];
        [self.sendSampleOpQueue waitUntilAllOperationsAreFinished];
        
        aw_streamer_close();
    });
    
    self.isAlreadyWriteSPS_PPS = NO;
    
}

- (void)switchCamera{}

- (void)onStopCapture{}

- (void)onStartCapture{}

- (void)setisCapturing:(BOOL)isCapturing {
    if (_isCapturing == isCapturing) {
        return;
    }
    
    if (!isCapturing) {
        [self onStopCapture];
    } else{
        [self onStartCapture];
    }
    
    _isCapturing = isCapturing;
}

- (UIView *)preview {
    if (!_preview) {
        _preview = [UIView new];
        _preview.bounds = [UIScreen mainScreen].bounds;
    }
    return _preview;
}

- (void)sendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer toEncodeQueue:(NSOperationQueue *)encodeQueue toSendQueue:(NSOperationQueue *)sendQueue {
    if (_inBackground)  return;
    __weak typeof(self) weakSelf = self;
    aw_flv_video_tag *video_tag = [weakSelf.encoderManager.videoEncoder encodeVideoSampleBufToFlvTag:sampleBuffer];

    if (video_tag) {    /// dump Video
        [weakSelf _writeVideoFrame:video_tag file:self.fileManager.video_file];
    }
    [encodeQueue addOperationWithBlock:^{
        if (weakSelf.isCapturing) {
            [weakSelf sendFlvVideoTag:video_tag toSendQueue:sendQueue];
        }
    }];
}

- (void)sendAudioSampleBuffer:(CMSampleBufferRef) sampleBuffer toEncodeQueue:(NSOperationQueue *)encodeQueue toSendQueue:(NSOperationQueue *)sendQueue {
    if (_inBackground)  return;
    __weak typeof(self) weakSelf = self;
    aw_flv_audio_tag *audio_tag = [weakSelf.encoderManager.audioEncoder encodeAudioSampleBufToFlvTag:sampleBuffer];
    [encodeQueue addOperationWithBlock:^{
        if (weakSelf.isCapturing) {
            [weakSelf _writeAudioFrame:audio_tag file:self.fileManager.audio_file];
            [weakSelf sendFlvAudioTag:audio_tag toSendQueue:sendQueue];
        }
    }];
}

- (void)sendVideoYuvData:(CVPixelBufferRef)pixelBuffer toEncodeQueue:(NSOperationQueue *)encodeQueue toSendQueue:(NSOperationQueue *)sendQueue {
    if (_inBackground) return;
    __weak typeof(self) weakSelf = self;
    CVPixelBufferRetain(pixelBuffer);
    [encodeQueue addOperationWithBlock:^{
        if (weakSelf.isCapturing) {
            aw_flv_video_tag *video_tag = [weakSelf.encoderManager.videoEncoder encodeYUVWithPixelBuffer:pixelBuffer];
            [weakSelf sendFlvVideoTag:video_tag toSendQueue:sendQueue];
        }
        CVPixelBufferRelease(pixelBuffer);
    }];
}

- (void)sendAudioPcmData:(NSData *)pcmData toEncodeQueue:(NSOperationQueue *)encodeQueue toSendQueue:(NSOperationQueue *)sendQueue {
    __weak typeof(self) weakSelf = self;
    [encodeQueue addOperationWithBlock:^{
        if (weakSelf.isCapturing) {
            aw_flv_audio_tag *audio_tag = [weakSelf.encoderManager.audioEncoder encodePCMDataToFlvTag:pcmData];
            [weakSelf sendFlvAudioTag:audio_tag toSendQueue:sendQueue];
        }
    }];
}

- (void)sendFlvVideoTag:(aw_flv_video_tag *)video_tag toSendQueue:(NSOperationQueue *)sendQueue {
    if (_inBackground) return;
    __weak typeof(self) weakSelf = self;
    if (video_tag) {
        [sendQueue addOperationWithBlock:^{
            if(weakSelf.isCapturing){
                if (!weakSelf.isSpsPpsAndAudioSpecificConfigSent) {
                    [weakSelf sendSpsPpsAndAudioSpecificConfigTagToSendQueue:sendQueue];
                    free_aw_flv_video_tag((aw_flv_video_tag **)&video_tag);
                } else {
                    aw_streamer_send_video_data(video_tag);
                }
            } else {
                free_aw_flv_video_tag((aw_flv_video_tag **)(&video_tag));
            }
        }];
    }
}

- (void)sendFlvAudioTag:(aw_flv_audio_tag *)audio_tag toSendQueue:(NSOperationQueue *)sendQueue {
    __weak typeof(self) weakSelf = self;
    if(audio_tag) {
        [sendQueue addOperationWithBlock:^{
            if(weakSelf.isCapturing){
                if (!weakSelf.isSpsPpsAndAudioSpecificConfigSent) {
                    [weakSelf sendSpsPpsAndAudioSpecificConfigTagToSendQueue:sendQueue];
                    free_aw_flv_audio_tag((aw_flv_audio_tag **)&audio_tag);
                } else {
                    aw_streamer_send_audio_data(audio_tag);
                }
            } else {
                free_aw_flv_audio_tag((aw_flv_audio_tag **)&audio_tag);
            }
        }];
    }
}

- (void)sendSpsPpsAndAudioSpecificConfigTagToSendQueue:(NSOperationQueue *)sendQueue {
    if (self.isSpsPpsAndAudioSpecificConfigSent) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [sendQueue addOperationWithBlock:^{
        if (!weakSelf.isCapturing || weakSelf.isSpsPpsAndAudioSpecificConfigSent) {
            return;
        }
        //video sps pps tag
        aw_flv_video_tag *spsPpsTag = [weakSelf.encoderManager.videoEncoder createSpsPpsFlvTag];
        if (spsPpsTag) {
            aw_streamer_send_video_sps_pps_tag(spsPpsTag);
        }
        //audio specific config tag
        aw_flv_audio_tag *audioSpecificConfigTag = [weakSelf.encoderManager.audioEncoder createAudioSpecificConfigFlvTag];
        if (audioSpecificConfigTag) {
            aw_streamer_send_audio_specific_config_tag(audioSpecificConfigTag);
        }
        weakSelf.isSpsPpsAndAudioSpecificConfigSent = spsPpsTag || audioSpecificConfigTag;
        
        aw_log("[D] is sps pps and audio sepcific config sent=%d", weakSelf.isSpsPpsAndAudioSpecificConfigSent);
    }];
}

/// 使用rtmp协议发送数据
- (void)sendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self sendVideoSampleBuffer:sampleBuffer toEncodeQueue:self.encodeSampleOpQueue toSendQueue:self.sendSampleOpQueue];
}

- (void)sendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self sendAudioSampleBuffer:sampleBuffer toEncodeQueue:self.encodeSampleOpQueue toSendQueue:self.sendSampleOpQueue];
}

- (void)sendVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [self sendVideoYuvData:pixelBuffer toEncodeQueue:self.encodeSampleOpQueue toSendQueue:self.sendSampleOpQueue];
}

- (void)sendAudioPcmData:(NSData *)audioData {
    [self sendAudioPcmData:audioData toEncodeQueue:self.encodeSampleOpQueue toSendQueue:self.sendSampleOpQueue];
}

- (void)sendFlvVideoTag:(aw_flv_video_tag *)flvVideoTag {
    [self sendFlvVideoTag:flvVideoTag toSendQueue:self.sendSampleOpQueue];
}

- (void)sendFlvAudioTag:(aw_flv_audio_tag *)flvAudioTag {
    [self sendFlvAudioTag:flvAudioTag toSendQueue:self.sendSampleOpQueue];
}

- (NSString *)captureSessionPreset {
    NSString *captureSessionPreset = nil;
    if (self.videoConfig.width == 288 && self.videoConfig.height == 352) {
        captureSessionPreset = AVCaptureSessionPreset352x288;
    } else if (self.videoConfig.width == 480 && self.videoConfig.height == 640) {
        captureSessionPreset = AVCaptureSessionPreset640x480;
    } else if (self.videoConfig.width == 540 && self.videoConfig.height == 960) {
        captureSessionPreset = AVCaptureSessionPresetiFrame960x540;
    } else if (self.videoConfig.width == 720 && self.videoConfig.height == 1280) {
        captureSessionPreset = AVCaptureSessionPreset1280x720;
    } else if (self.videoConfig.width == 1080 && self.videoConfig.height == 1920) {
        captureSessionPreset = AVCaptureSessionPreset1920x1080;
    } else if (self.videoConfig.width == 2160 && self.videoConfig.height == 3840) {
        captureSessionPreset = AVCaptureSessionPreset3840x2160;
    }
    return captureSessionPreset;
}

- (NSData *)getPCMDataWithSampelBuffer:(CMSampleBufferRef)sampleBuffer {
    //获取pcm数据大小
    NSInteger audioDataSize = CMSampleBufferGetTotalSampleSize(sampleBuffer);
    //分配空间
    int8_t *audio_data = aw_alloc((int32_t)audioDataSize);
    //获取CMBlockBufferRef
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    //直接将数据copy至我们自己分配的内存中
    CMBlockBufferCopyDataBytes(dataBuffer, 0, audioDataSize, audio_data);
    
    //返回数据
    return [NSData dataWithBytesNoCopy:audio_data length:audioDataSize];
}

#pragma mark Private

/// dump H264/H265 Data
- (void)_writeVideoFrame:(aw_flv_video_tag *)videFrame file:(FILE *)file{
        if (!file) return;
        if (self.isAlreadyWriteSPS_PPS == NO) {
            /// sps pps
            NSData *spsData = self.encoderManager.videoEncoder.spsData;
            NSData *ppsData = self.encoderManager.videoEncoder.ppsData;
            
            size_t sps_size = fwrite(spsData.bytes, 1, spsData.length, file);
            if (sps_size != spsData.length) {
                NSLog(@"write sps file error;");
            }
            size_t pps_size = fwrite(ppsData.bytes, 1, ppsData.length, file);
            if (pps_size != ppsData.length) {
                NSLog(@"write pps file error;");
            }
            
            [_lock lock];
            self.isAlreadyWriteSPS_PPS = YES;
            [_lock unlock];
            
        } else {
            /// normal nalu
            if (self.isAlreadyWriteSPS_PPS == YES) {
                /// 这里保存需要删掉前面的4字节 大端长度；
                size_t nalue_size  = videFrame->frame_data->size - 4;
                size_t write_nalue_size = fwrite(videFrame->frame_data->data + 4 , 1, nalue_size, file);
                if (write_nalue_size != nalue_size) {
                    NSLog(@"write nalu file error;");
                }
            }
        }
}

/// dump PCM Data
- (void)_writePcmAudioData:(NSData *)pcmData file:(FILE *)file {
    if(!pcmData || !file ){ return; }
    size_t pcmLength = pcmData.length;
    size_t pkt_size = fwrite(pcmData.bytes, 1, pcmLength, file);
    if (pkt_size != pcmLength ) {
        NSLog(@"write aac file faild;");
    }
}

/// dump AAC Data
- (void)_writeAudioFrame:(aw_flv_audio_tag *)audioFrame file:(FILE *)file {
    if(!audioFrame || !file){return;}
        
    aw_flv_tag_type tag_type = audioFrame->common_tag.tag_type;
    if (tag_type == aw_flv_tag_type_audio) {
      
        if (!file) {
            NSLog(@"open aac file failed;");
            return;
        }
        //写adts头
        size_t aac_length = audioFrame->frame_data->size;
        NSInteger profile = 2;
        NSInteger sample_rate = self.audioConfig.sampleRate;
        NSInteger channles = self.audioConfig.channelCount;
        NSData *adts_header = [self adts_headerWithLength:aac_length profile:profile sampleRate:sample_rate channles:(int)channles];
        fwrite(adts_header.bytes, 1, 7, file);
        //写数据
        size_t pkt_size = fwrite(audioFrame->frame_data->data, 1, aac_length, file);
        if (pkt_size != aac_length ) {
            NSLog(@"write aac file faild;");
        }
        
    }
}

@end
