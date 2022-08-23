 

#import "AWAudioEncoder.h"

@implementation AWAudioEncoder
- (aw_flv_audio_tag *) encodePCMDataToFlvTag:(NSData *)pcmData {
    return NULL;
}

- (aw_flv_audio_tag *) encodeAudioSampleBufToFlvTag:(CMSampleBufferRef)audioSample {
    
    return [self encodePCMDataToFlvTag:[self convertAudioSmapleBufferToPcmData:audioSample]];
}

- (aw_flv_audio_tag *)createAudioSpecificConfigFlvTag{
    return NULL;
}

- (NSData *) convertAudioSmapleBufferToPcmData:(CMSampleBufferRef)audioSample {
    //获取pcm数据大小
    NSInteger audioDataSize = CMSampleBufferGetTotalSampleSize(audioSample);
    
    //分配空间
    int8_t *audio_data = aw_alloc((int32_t)audioDataSize);
    
    //获取CMBlockBufferRef
    //这个结构里面就保存了 PCM数据
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(audioSample);
    //直接将数据copy至我们自己分配的内存中
    OSStatus status = CMBlockBufferCopyDataBytes(dataBuffer, 0, audioDataSize, audio_data);
    NSError *error = nil;
    if (status != kCMBlockBufferNoErr) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Error: ACC encode get data point error: %@",error);
        return nil;
    }
    //返回数据
    return [NSData dataWithBytesNoCopy:audio_data length:audioDataSize];
}

@end
