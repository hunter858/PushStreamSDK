 

/*
 GPUImage camera重载，获取音频数据。
 */

#import <GPUImage/GPUImageFramework.h>
#import <AVFoundation/AVFoundation.h>

@protocol AWGPUImageVideoCameraDelegate <NSObject>

- (void)processAudioSample:(CMSampleBufferRef)sampleBuffer;

@end

@interface AWGPUImageVideoCamera : GPUImageVideoCamera

@property (nonatomic, weak) id<AWGPUImageVideoCameraDelegate> awAudioDelegate;

- (void)setCaptureSessionPreset:(NSString *)captureSessionPreset;

@end
