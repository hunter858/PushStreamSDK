 

#import "AWAVCaptureManager.h"
#import "AWGPUImageAVCapture.h"
#import "AWSystemAVCapture.h"

@interface AWAVCaptureManager()
@property (nonatomic, strong) AWGPUImageAVCapture *gpuImageAvCapture;
@property (nonatomic, strong) AWSystemAVCapture *systemAvCapture;
@end

@implementation AWAVCaptureManager

- (AWGPUImageAVCapture *)gpuImageAvCapture {
    if (!_gpuImageAvCapture) {
        _gpuImageAvCapture = [[AWGPUImageAVCapture alloc] initWithVideoConfig:self.videoConfig audioConfig:self.audioConfig];
    }
    return _gpuImageAvCapture;
}

- (AWSystemAVCapture *)systemAvCapture {
    if (!_systemAvCapture) {
        _systemAvCapture = [[AWSystemAVCapture alloc] initWithVideoConfig:self.videoConfig audioConfig:self.audioConfig];
    }
    return _systemAvCapture;
}

- (AWAVBaseCapture *)avCapture {
    if (!self.audioEncoderType) {
        NSLog(@"[E] AVAVCaptureManager 未设置audioEncoderType");
        return nil;
    }
    
    if (!self.videoEncoderType) {
        NSLog(@"[E] AVAVCaptureManager 未设置videoEncoderType");
        return nil;
    }
    
    if (!self.videoConfig) {
        NSLog(@"[E] AWAVCaptureManager 未设置videoConfig");
        return nil;
    }
    if (!self.audioConfig) {
        NSLog(@"[E] AWAVCaptureManager 未设置audioConfig");
        return nil;
    }
    
    AWAVBaseCapture *capture = nil;
    switch (self.captureType) {
        case AWAVCaptureTypeGPUImage:
            capture = self.gpuImageAvCapture;
            break;
        case AWAVCaptureTypeSystem:
            capture = self.systemAvCapture;
            break;
        default:
            NSLog(@"[E] AWAVCaptureManager 未设置captureType");
            break;
    }
    
    if (capture) {
        capture.audioEncoderType = self.audioEncoderType;
        capture.videoEncoderType = self.videoEncoderType;
    }
    
    return capture;
}


@end
