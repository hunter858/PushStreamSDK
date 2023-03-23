 

#import "AWSystemAVCapture.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AWSystemPreview.h"

@interface AWSystemAVCapture ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate,AWSystemPreviewDelegate>
/// 前后摄像头
@property (nonatomic, strong) AVCaptureDeviceInput *frontCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *backCamera;
/// 当前使用的视频设备
@property (nonatomic,   weak) AVCaptureDeviceInput *videoInputDevice;
/// 音频设备
@property (nonatomic, strong) AVCaptureDeviceInput *audioInputDevice;
/// 输出数据接收
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
/// 会话
@property (nonatomic, strong) AVCaptureSession *captureSession;
/// 预览
@property (nonatomic, strong) AWSystemPreview *systemPreview;

@end

@implementation AWSystemAVCapture

- (void)switchCamera {
    if ([self.videoInputDevice isEqual:self.frontCamera]) {
        self.videoInputDevice = self.backCamera;
    } else {
        self.videoInputDevice = self.frontCamera;
    }
    //更新fps
    [self updateFps: self.videoConfig.fps];
}

- (void)onInit {
    [self createCaptureDevice];
    [self createOutput];
    [self createCaptureSession];
    [self createPreviewLayer];
    [self updateFps:self.videoConfig.fps];
}

/// 初始化视频设备
- (void)createCaptureDevice {
    //创建视频设备
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //初始化摄像头
    self.frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.firstObject error:nil];
    self.backCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.lastObject error:nil];
    
    //麦克风
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    self.audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    self.videoInputDevice = self.frontCamera;
}

/// 切换摄像头
- (void)setVideoInputDevice:(AVCaptureDeviceInput *)videoInputDevice {
    if ([videoInputDevice isEqual:_videoInputDevice]) {
        return;
    }
    //modifyinput
    [self.captureSession beginConfiguration];
    if (_videoInputDevice) {
        [self.captureSession removeInput:_videoInputDevice];
    }
    if (videoInputDevice) {
        [self.captureSession addInput:videoInputDevice];
    }
    
    [self setVideoOutConfig];
    
    [self.captureSession commitConfiguration];
    
    _videoInputDevice = videoInputDevice;
}

- (AVCaptureDevice *)currentDevice {
    return _videoInputDevice.device;
}


/// 创建预览
- (void)createPreviewLayer {
    self.systemPreview = [[AWSystemPreview alloc]init];
    self.systemPreview.frame = self.preview.bounds;
    self.systemPreview.session = self.captureSession;
    self.systemPreview.delegate = self;
    [self.preview addSubview:self.systemPreview];
}

- (void)setVideoOutConfig {
    for (AVCaptureConnection *conn in self.videoDataOutput.connections) {
        if (conn.isVideoStabilizationSupported) {
            [conn setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
        }
        if (conn.isVideoOrientationSupported) {
            [conn setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
        if (conn.isVideoMirrored) {
            [conn setVideoMirrored: YES];
        }
    }
}

/// 创建会话
-(void) createCaptureSession {
    self.captureSession = [AVCaptureSession new];
    
    [self.captureSession beginConfiguration];
    
    if ([self.captureSession canAddInput:self.videoInputDevice]) {
        [self.captureSession addInput:self.videoInputDevice];
    }
    
    if ([self.captureSession canAddInput:self.audioInputDevice]) {
        [self.captureSession addInput:self.audioInputDevice];
    }
    
    if([self.captureSession canAddOutput:self.videoDataOutput]) {
        [self.captureSession addOutput:self.videoDataOutput];
        [self setVideoOutConfig];
    }
    
    if([self.captureSession canAddOutput:self.audioDataOutput]) {
        [self.captureSession addOutput:self.audioDataOutput];
    }
    
    if (![self.captureSession canSetSessionPreset:self.captureSessionPreset]) {
        @throw [NSException exceptionWithName:@"Not supported captureSessionPreset" reason:[NSString stringWithFormat:@"captureSessionPreset is [%@]", self.captureSessionPreset] userInfo:nil];
    }
    
    AVCaptureDevice *activeDevice = [self currentDevice];
    [activeDevice lockForConfiguration:NULL];
    CMTime maxFrameDuration = CMTimeMake(1, (int32_t)self.videoConfig.fps);
    CMTime minFrameDuration = CMTimeMake(1, (int32_t)self.videoConfig.fps);
    @try {
        [activeDevice setActiveVideoMinFrameDuration:minFrameDuration];
        [activeDevice setActiveVideoMaxFrameDuration:maxFrameDuration];
    } @catch (NSException *exception) {
        NSLog(@"BGMVideoCapture, 设备修改帧速率失败，错误信息：%@",exception.description);
    } @finally {
        
    }
    [activeDevice unlockForConfiguration];
    
    self.captureSession.sessionPreset = self.captureSessionPreset;
    
    [self.captureSession commitConfiguration];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self.captureSession startRunning];
    });
   
}

//销毁会话
- (void) destroyCaptureSession {
    if (self.captureSession) {
        [self.captureSession removeInput:self.audioInputDevice];
        [self.captureSession removeInput:self.videoInputDevice];
        [self.captureSession removeOutput:self.self.videoDataOutput];
        [self.captureSession removeOutput:self.self.audioDataOutput];
    }
    self.captureSession = nil;
}

- (void)createOutput {
    
    dispatch_queue_t captureQueue = dispatch_queue_create("aw.capture.queue", DISPATCH_QUEUE_SERIAL);
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoDataOutput setSampleBufferDelegate:self queue:captureQueue];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoDataOutput setVideoSettings:@{
                                             (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                                             }];
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioDataOutput setSampleBufferDelegate:self queue:captureQueue];
}


- (void)updatePresent:(AVCaptureSessionPreset)present {
    if ([self.captureSession canSetSessionPreset:present])  {
        self.captureSession.sessionPreset = present;
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (self.isCapturing) {
        if ([self.videoDataOutput isEqual:captureOutput]) {
            [self sendVideoSampleBuffer:sampleBuffer];
        } else if ([self.audioDataOutput isEqual:captureOutput]) {
            [self sendAudioSampleBuffer:sampleBuffer];
        }
    }
}

#pragma mark Private


- (AVCaptureDevice *)_activeCamera {
    return self.videoInputDevice.device;
}


- (void)focusDeviceAtPoint:(CGPoint)point handler :(void(^)(NSError *error))handler {

    AVCaptureDevice *device = [self _activeCamera];
    if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus] && [device isFocusPointOfInterestSupported]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.focusPointOfInterest = point;
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [device unlockForConfiguration];
        }
        if (handler != NULL){ handler(error);}
    } else {
        if (handler != NULL){
            handler([self errorWithDescription:@"设备不支持对焦" code:2001]);
        }
    }
}

- (void)exposeDeviceAtPoint:(CGPoint)point handler:(void(^)(NSError *error))handler {
    AVCaptureDevice *device = [self _activeCamera];
    if ([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure] && [device isExposurePointOfInterestSupported]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.exposurePointOfInterest = point;
            device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            [device unlockForConfiguration];
        }
        if (handler != NULL){ handler(error);}
    } else {
        if (handler != NULL){
            handler([self errorWithDescription:@"设备不支持曝光" code:2002]);
        }
    }
}

- (void)updateVideoZoomFactor:(CGFloat)factor {
    if (factor < 1) factor = 1.f;
    AVCaptureDevice *device = [self _activeCamera];
    if (factor > device.maxAvailableVideoZoomFactor) return;
    NSError *error = nil;
    [device lockForConfiguration:&error];
    if (!error) {
        device.videoZoomFactor = factor;
    }
    [device unlockForConfiguration];
}


- (NSError *)errorWithDescription:(NSString *)text code:(NSInteger)code {
    NSDictionary *descriptionDict = @{NSLocalizedDescriptionKey: text};
    NSError *error = [NSError errorWithDomain:@"com.zheshi.live.camera.error" code:code userInfo:descriptionDict];
    return error;
}

#pragma mark Delegate

- (void)singleTappedAtPoint:(CGPoint)point{
    [self focusDeviceAtPoint:point handler:^(NSError * _Nonnull error) {
        if (error) {
            NSLog(@"error ==> %@", error.localizedDescription);
        }
    }];
    [self exposeDeviceAtPoint:point handler:^(NSError * _Nonnull error) {
        if (error) {
            NSLog(@"error ==> %@", error.localizedDescription);
        }
    }];
}

//- (void)doubleTappedAtPoint:(CGPoint)point{
//
//}
//
//- (void)longPressAtPoint:(CGPoint)point{
//
//}

@end
