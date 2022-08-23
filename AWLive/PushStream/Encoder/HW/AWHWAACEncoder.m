 

#import "AWHWAACEncoder.h"
#import <VideoToolbox/VideoToolbox.h>
#import "AWEncoderManager.h"


#define AWBytesPerPacket 2
#define AWAACFramePerPacket 1024

static int pcmBufferSize = 0;
static uint8_t pcmBuffer[AWBytesPerPacket * AWAACFramePerPacket * 8];

@interface AWHWAACEncoder()

{
    UInt8 *_aacBuffer;
}
//audio params
@property (nonatomic, strong) NSData *curFramePcmData;



@property (nonatomic, unsafe_unretained) AudioConverterRef aConverter;
@property (nonatomic, unsafe_unretained) uint32_t aMaxOutputFrameSize;

@property (nonatomic, unsafe_unretained) aw_faac_config faacConfig;
@end

@implementation AWHWAACEncoder

static OSStatus aacEncodeInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData){
    AudioBufferList bufferList = *(AudioBufferList *)inUserData;
    ioData->mNumberBuffers = bufferList.mNumberBuffers;
    ioData->mBuffers[0].mNumberChannels = bufferList.mBuffers->mNumberChannels;
    ioData->mBuffers[0].mData = bufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = bufferList.mBuffers[0].mDataByteSize;
    return noErr;
}

- (aw_flv_audio_tag *)encodePCMDataToFlvTag:(NSData *)pcmData {
    self.curFramePcmData = pcmData;
    
    NSMutableData *aacData = [NSMutableData new];
    
    UInt32 maxBufferSize = (UInt32)AWBytesPerPacket * AWAACFramePerPacket * self.audioConfig.channelCount;
    memcpy(pcmBuffer + pcmBufferSize, pcmData.bytes, pcmData.length);
    pcmBufferSize += pcmData.length;
    
    if (pcmBufferSize >= maxBufferSize) {
        NSUInteger count = pcmBufferSize / maxBufferSize;
        for (NSInteger index = 0; index < count; index++) {
            if (!_aacBuffer) {
                _aacBuffer = malloc(maxBufferSize);
                
            }else {
                memset(_aacBuffer, 0, maxBufferSize);
            }
         
            AudioBufferList inputBufferlist ;
            inputBufferlist.mNumberBuffers = 1;
            inputBufferlist.mBuffers ->mNumberChannels = (UInt32) self.audioConfig.channelCount;
            inputBufferlist.mBuffers->mDataByteSize = maxBufferSize;
            inputBufferlist.mBuffers->mData = pcmBuffer;
            
            AudioBufferList outputBufferlist ;
            outputBufferlist.mNumberBuffers = 1;
            outputBufferlist.mBuffers ->mNumberChannels = inputBufferlist.mBuffers->mNumberChannels;
            outputBufferlist.mBuffers->mDataByteSize = maxBufferSize;
            outputBufferlist.mBuffers->mData = _aacBuffer;
            
            UInt32 outputNumPackets = 1;
            OSStatus status = AudioConverterFillComplexBuffer(_aConverter, aacEncodeInputDataProc, &inputBufferlist, &outputNumPackets, &outputBufferlist, NULL);
            if (status != noErr) {
                NSLog(@"audio converter fillComplexBuffer error %d",status);
            }
            [aacData appendBytes:outputBufferlist.mBuffers[0].mData length:outputBufferlist.mBuffers[0].mDataByteSize];
            NSUInteger leftBufferSize = pcmBufferSize - maxBufferSize;
            if (leftBufferSize) {
                memcpy(pcmBuffer, pcmBuffer + maxBufferSize, leftBufferSize);
            }
            pcmBufferSize -= maxBufferSize;
        }
        self.manager.timestamp += 1024 * 1000 / self.audioConfig.sampleRate;
        return aw_encoder_create_audio_tag((int8_t *)aacData.bytes, aacData.length, (uint32_t)self.manager.timestamp, &_faacConfig);
    } else {
        return NULL;
        
    }
}

- (aw_flv_audio_tag *)createAudioSpecificConfigFlvTag {
    uint8_t profile = kMPEG4Object_AAC_LC;
    uint8_t sampleRate = 4;
    uint8_t chanCfg = 1;
    uint8_t config1 = (profile << 3) | ((sampleRate & 0xe) >> 1);
    uint8_t config2 = ((sampleRate & 0x1) << 7) | (chanCfg << 3);
    
    aw_data *config_data = NULL;
    data_writer.write_uint8(&config_data, config1);
    data_writer.write_uint8(&config_data, config2);
    
    aw_flv_audio_tag *audio_specific_config_tag = aw_encoder_create_audio_specific_config_tag(config_data, &_faacConfig);
    
    free_aw_data(&config_data);
    
    return audio_specific_config_tag;
}

- (void)open {
    //创建audio encode converter
    AudioStreamBasicDescription inputAudioDes = {0};
    inputAudioDes.mSampleRate = self.audioConfig.sampleRate;
    inputAudioDes.mFormatID = kAudioFormatLinearPCM;
    inputAudioDes.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    inputAudioDes.mChannelsPerFrame = (uint32_t)self.audioConfig.channelCount;
    inputAudioDes.mBitsPerChannel = (uint32_t)self.audioConfig.sampleSize;
    inputAudioDes.mFramesPerPacket = 1;
    inputAudioDes.mBitsPerChannel = 16;
    inputAudioDes.mBytesPerFrame = inputAudioDes.mBitsPerChannel / 8 * inputAudioDes.mChannelsPerFrame;
    inputAudioDes.mBytesPerPacket = inputAudioDes.mBytesPerFrame * inputAudioDes.mFramesPerPacket;;
    
    AudioStreamBasicDescription outputAudioDes = {0};
    outputAudioDes.mFormatID = kAudioFormatMPEG4AAC;
    outputAudioDes.mFormatFlags = kMPEG4Object_AAC_LC;
    outputAudioDes.mSampleRate = self.audioConfig.sampleRate;
    outputAudioDes.mChannelsPerFrame = (uint32_t)self.audioConfig.channelCount;  ///声道数
    outputAudioDes.mFramesPerPacket = 1024;///每个packet 的帧数 ，这是一个比较大的固定数值
    outputAudioDes.mBytesPerFrame = 0; //每帧的大小  如果是压缩格式设置为0
    outputAudioDes.mReserved = 0; // 8字节对齐，填0;
    

    
    uint32_t outDesSize = sizeof(outputAudioDes);
    AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &outDesSize, &outputAudioDes);
    OSStatus status = AudioConverterNew(&inputAudioDes, &outputAudioDes, &_aConverter);
    if (status != noErr) {
        [self onErrorWithCode:AWEncoderErrorCodeCreateAudioConverterFailed des:@"硬编码AAC创建失败"];
    }
    
    //设置码率
    uint32_t aBitrate = (uint32_t)self.audioConfig.bitrate;
    uint32_t aBitrateSize = sizeof(aBitrate);
    status = AudioConverterSetProperty(_aConverter, kAudioConverterEncodeBitRate, aBitrateSize, &aBitrate);
    
    //查询最大输出
    uint32_t aMaxOutput = 0;
    uint32_t aMaxOutputSize = sizeof(aMaxOutput);
    AudioConverterGetProperty(_aConverter, kAudioConverterPropertyMaximumOutputPacketSize, &aMaxOutputSize, &aMaxOutput);
    self.aMaxOutputFrameSize = aMaxOutput;
    if (aMaxOutput == 0) {
        [self onErrorWithCode:AWEncoderErrorCodeAudioConverterGetMaxFrameSizeFailed des:@"AAC 获取最大frame size失败"];
    }
    
    pcmBufferSize = 0;
}

- (void)close {
    AudioConverterDispose(_aConverter);
    _aConverter = nil;
    self.curFramePcmData = nil;
    self.aMaxOutputFrameSize = 0;
    pcmBufferSize = 0;
}

@end
