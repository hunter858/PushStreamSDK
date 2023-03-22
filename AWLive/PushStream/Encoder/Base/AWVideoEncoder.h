 

/*
 视频编码器基类，只声明接口，和一些公共转换数据函数。
 */

#import "AWEncoder.h"

@interface AWVideoEncoder : AWEncoder

/// 临时加的
@property (nonatomic, copy) NSMutableData *spsData;
@property (nonatomic, copy) NSMutableData *ppsData;

@property (nonatomic, copy) AWVideoConfig *videoConfig;

/// 旋转
- (NSData *)rotateNV12Data:(NSData *)nv12Data;

/// 编码
- (aw_flv_video_tag *)encodeYUVWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (aw_flv_video_tag *)encodeVideoSampleBufToFlvTag:(CMSampleBufferRef)videoSample;

/// 根据flv，h264，aac协议，提供首帧需要发送的tag
/// 创建sps pps
- (aw_flv_video_tag *)createSpsPpsFlvTag;

/// 转换
- (NSData *)convertVideoSmapleBufferToYuvData:(CVPixelBufferRef)pixelBuffer;


@end
