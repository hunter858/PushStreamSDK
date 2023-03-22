 

#import "AWSWX264Encoder.h"
#import "AWEncoderManager.h"

@implementation AWSWX264Encoder
/// 废弃，
- (aw_flv_video_tag *)encodeYUVWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    NSData *yuvData = [self convertVideoSmapleBufferToYuvData:pixelBuffer];
    long y_stride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    return aw_sw_encoder_encode_x264_data((int8_t *)yuvData.bytes, yuvData.length, y_stride,  self.manager.timestamp + 1);
}
 
- (aw_flv_video_tag *)createSpsPpsFlvTag {
    return aw_sw_encoder_create_x264_sps_pps_tag();
}

- (void)open {
    aw_x264_config x264_config = self.videoConfig.x264Config;
    aw_sw_encoder_open_x264_encoder(&x264_config);
}

- (void)close {
    aw_sw_encoder_close_x264_encoder();
}

@end
